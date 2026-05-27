# PooPooLog — 아키텍처 분석

> 폴더 구조·Provider 목록은 [PROJECT.md](../PROJECT.md) 참고.
> 화면별 기능 명세는 [app_features.md](app_features.md) 참고.

---

## 목차

1. [앱 시작 흐름](#1-앱-시작-흐름)
2. [탭 구조](#2-탭-구조)
3. [데이터 모델 관계](#3-데이터-모델-관계)
4. [Provider 의존 관계](#4-provider-의존-관계)
5. [화면별 데이터 흐름](#5-화면별-데이터-흐름)
6. [서비스 레이어](#6-서비스-레이어)
7. [전체 구조 요약](#7-전체-구조-요약)

---

## 1. 앱 시작 흐름

```
main()
  ├─ MobileAds.instance.initialize()     # AdMob 초기화
  ├─ AdService().preload()               # 전면 광고 미리 로드
  ├─ SharedPreferences → 저장된 테마 로드
  └─ runApp(
       ProviderScope(
         overrides: [themeModeProvider ← 저장된 테마]
         child: PooPooLogApp → AppShell
       )
     )
```

- AdMob 초기화를 `main()`에서 `await`으로 처리 → 광고 준비 후 앱 시작
- 테마 모드는 `ProviderScope.overrides`로 초기값 주입

---

## 2. 탭 구조

`AppShell`은 `IndexedStack`으로 4개 탭을 항상 메모리에 유지한다.
탭 전환은 `currentTabProvider` (StateProvider\<int\>) 하나로 제어.

```
AppShell (IndexedStack)
  ├─ index 0: CalendarScreen
  ├─ index 1: TimelineScreen
  ├─ index 2: StatsScreen
  └─ index 3: MoreScreen
```

`currentTabProvider`는 공개(public) Provider로, `MoreScreen`에서 데이터 초기화 후 캘린더 탭(0)으로 이동할 때 직접 설정한다.

---

## 3. 데이터 모델 관계

```
MoodLevel (enum)         RecordModel (domain)      Entry (DB row)
────────────────         ────────────────────      ──────────────
good  → index 0          id: int                   Drift 자동 생성
okay  → index 1          recordedAt: DateTime      app_database.g.dart
bad   → index 2          visited: bool?
                         mood: MoodLevel?
                         memo: String?
                         createdAt: DateTime
```

- `RecordModel` — 순수 Dart 도메인 객체. UI는 `Entry`를 직접 사용하고 `RecordModel`은 변환 전용.
- 변환 메서드: `Entry.toModel()` / `RecordModel.toCompanion()` (`app_database.dart` 하단 확장)

### visited + mood 조합 → 표시 레이블

| visited | mood | 레이블 | 색상 |
|---------|------|--------|------|
| `null` | - | `—` | moodNone (회색) |
| `false` | - | `안 감` | moodNone (회색) |
| `true` | `null` | `다녀옴` | moodNone (회색) |
| `true` | `good` | `좋음` | moodGood (녹색) |
| `true` | `okay` | `보통` | moodOkay (주황) |
| `true` | `bad` | `나쁨` | moodBad (빨강) |

이 로직은 `entry_ext.dart`의 `EntryX` 확장에 집중되어 있다.

---

## 4. Provider 의존 관계

```
appDatabaseProvider (Provider<AppDatabase>)
        │
        ├─ monthlyEntriesProvider(DateTime)     FutureProvider.family
        │        └─ watch: calendarFocusedMonthProvider
        │
        ├─ earliestEntryDateProvider            FutureProvider<DateTime?>
        │        └─ 가장 오래된 기록 날짜 (기록 없으면 null)
        │        └─ 사용처: 월 피커 minDate, _BeforeEarliestState 판단
        │
        ├─ timelineProvider                     AsyncNotifier
        │        └─ watch: timelineFilterProvider
        │
        ├─ statsResultProvider                  FutureProvider
        │        └─ watch: statsRangeProvider
        │
        └─ recordFormProvider(Entry?)           NotifierProvider.family
                 └─ null → 신규 / Entry → 수정

currentTabProvider       StateProvider<int>       탭 인덱스
themeModeProvider        StateProvider<ThemeMode> 테마 (초기값 ProviderScope override)
selectedDayProvider      StateProvider<DateTime?> 캘린더 선택 날짜
```

### 기록 저장·수정·삭제 후 invalidate 패턴

```dart
ref.invalidate(monthlyEntriesProvider)  // 캘린더 도트 갱신 (family 전체)
ref.invalidate(timelineProvider)        // 타임라인 목록 갱신
ref.invalidate(statsResultProvider)     // 통계 재계산
```

**설계 포인트:**
- `monthlyEntriesProvider`는 family → 월마다 독립 캐시, 다른 월 데이터 보존
- `recordFormProvider(Entry?)`는 family → null=신규, Entry=수정 모드
- `appDatabaseProvider`는 `ref.onDispose(db.close)` 등록 → 앱 종료 시 DB 정상 닫힘

---

## 5. 화면별 데이터 흐름

### 5-1. 캘린더 탭

```
월 스와이프
  → calendarFocusedMonthProvider 갱신
  → monthlyEntriesProvider(newMonth) 로딩
  → valueOrNull로 로딩 중 이전 데이터 유지 (캘린더 깜빡임 방지)

날짜 탭 (기록 없음)
  → selectedDayProvider 갱신
  → Navigator.push(RecordScreen, presetDate: day)

날짜 탭 (기록 있음)
  → selectedDayProvider 갱신
  → _DayPanel 하단 패널 노출

헤더 탭
  → showMonthPickerSheet (Cupertino 드럼롤)
  → calendarFocusedMonthProvider 갱신
```

### 5-2. 타임라인 탭

```
DB: List<Entry> (전체)
      ↓ timelineProvider (필터링 + 날짜 그룹 + 페이징)
List<DayGroup> { date, entries[] }
      ↓ 평탄화
List<_ListItem> [header, entry, entry, nativeAd, header, entry, ...]
      ↓ ListView.separated
DateHeader / EntryCard / NativeAdWidget
```

- `TimelineFilter` 변경 → `timelineProvider` 재실행
- 초기 로드 범위: 최근 6개월. `loadMore()` 호출마다 6개월씩 확장 (최대 앱 시작일 2026-01-01)
- 네이티브 광고: 누적 엔트리 수 % 7 == 0 인 위치에 삽입

### 5-3. 통계 탭

```
statsRangeProvider (기간 설정)
  ↓ statsResultProvider (FutureProvider)
       ↓ getEntriesInRange(from, to)
       ↓ 단일 패스 집계
StatsResult {
  totalVisits,     visited == true 전체 수
  moodCounts,      Map<MoodLevel?, int>
  hourlyCounts,    List<int> [0..23]
  peakHours,       List<int> — 최대 횟수를 공동으로 가진 시간대 전체
  totalDays,       기간 전체 일수
  visitedDays      방문한 날 수 (Set으로 중복 제거)
}
```

### 5-4. 기록 입력·수정 화면

```
RecordFormState
  ├─ recordedAt: DateTime   ← CupertinoDatePicker
  ├─ visited: bool?         ← SwitchListTile
  ├─ mood: MoodLevel?       ← MoodSelector
  ├─ memo: String?          ← TextField + QuickTags
  └─ isSaving: bool

신규 모드: recordFormProvider(null) → visited 초기값 true
수정 모드: recordFormProvider(entry) → entry 데이터로 초기화

저장 흐름:
  notifier.save(db)
    → DB upsert
    → ref.invalidate(timelineProvider, statsResultProvider)
    → AdService().onRecordSaved()  ← 5회마다 전면 광고
    → Navigator.pop()
```

**주요 로직:**
- `setVisited(false)` → `mood` 자동 null 초기화
- `setMood(m)` → `visited` 자동 true 설정
- `setMemo("")` → null로 저장

### 5-5. 더보기 탭

```
데이터 초기화:
  _confirmReset()
    → AlertDialog (확인)
    → db.deleteAllEntries()
    → ref.invalidate(timelineProvider, monthlyEntriesProvider, statsResultProvider)
    → currentTabProvider = 0  (캘린더 탭으로 이동)

CSV 가져오기:
  _importCsv()
    → FilePicker로 .csv/.txt 선택
    → UTF-8 디코딩 (실패 시 오류 스낵바)
    → 확인 다이얼로그
    → 헤더 컬럼명 기반 파싱 (위치 인덱스 X → 버전 호환)
    → db.upsertEntryByTime() — 동일 recordedAt 존재 시 UPDATE, 없으면 INSERT
    → 완료 후 Provider 무효화

테스트 데이터 생성 (히든, 버전 5회 탭):
  _generateTestData()
    → 2025-10-01 ~ 오늘까지 순회
    → 매일 Random().nextInt(5)개 insertEntry()
    → 완료 후 Provider 무효화
```

---

## 6. 서비스 레이어

### AdService (싱글톤)

```
preload()           전면 광고 미리 로드 (앱 시작 시)
onRecordSaved()     저장 카운트 +1, _kInterstitialFrequency(5)회마다 전면 광고 노출
                    광고 닫힌 후 onComplete() 콜백 실행 → Navigator.pop()
```

- Riverpod Provider 없음, 순수 싱글톤 패턴
- 카운트는 `SharedPreferences`의 `ad_save_count` 키로 저장

### AppTheme

```dart
static Color moodGood = Color(0xFF639922)  // 녹색
static Color moodOkay = Color(0xFFBA7517)  // 주황
static Color moodBad  = Color(0xFFE24B4A)  // 빨강
static Color moodNone = Color(0xFFB4B2A9)  // 회색

static ThemeData light()  // Material 3, ColorScheme.fromSeed
static ThemeData dark()
```

---

## 7. 전체 구조 요약

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer                                                   │
│                                                             │
│  AppShell (IndexedStack, 4탭)                               │
│    ├── CalendarScreen ──┐                                   │
│    ├── TimelineScreen   ├── RecordScreen (push)             │
│    ├── StatsScreen      │                                   │
│    └── MoreScreen ──────┘                                   │
└─────────────────────────────────────────────────────────────┘
          │ watch / read
┌─────────────────────────────────────────────────────────────┐
│  State Layer — Riverpod                                     │
│                                                             │
│  appDatabaseProvider                                        │
│    ├── monthlyEntriesProvider(month)                        │
│    ├── timelineProvider  ← timelineFilterProvider           │
│    ├── statsResultProvider  ← statsRangeProvider            │
│    └── recordFormProvider(entry?)                           │
│                                                             │
│  currentTabProvider · themeModeProvider                     │
│  calendarFocusedMonthProvider · selectedDayProvider         │
└─────────────────────────────────────────────────────────────┘
          │ singleton
┌─────────────────────────────────────────────────────────────┐
│  Service Layer                                              │
│                                                             │
│  AdService  (google_mobile_ads — 전면·배너·네이티브)         │
└─────────────────────────────────────────────────────────────┘
          │ SQL
┌─────────────────────────────────────────────────────────────┐
│  Data Layer — Drift (SQLite)                                │
│                                                             │
│  AppDatabase → Entries 테이블                               │
│    getEntriesForDate / getEntriesInRange / getEntriesForMonth│
│    insertEntry / updateEntry / upsertEntryByTime             │
│    deleteEntry / deleteAllEntries                            │
└─────────────────────────────────────────────────────────────┘
```

### 설계 특징

| 특징 | 내용 |
|------|------|
| 단방향 데이터 흐름 | DB → Provider → UI, 역방향 없음 |
| 수동 캐시 무효화 | 저장·삭제 후 `ref.invalidate()`로 관련 Provider 갱신 |
| family Provider 캐시 | `monthlyEntriesProvider`는 월별 독립 캐시 |
| 타입 혼재 | UI는 `Entry` 직접 사용, `RecordModel`은 변환 전용 |
| 확장 함수 집중 | `visited + mood` 조합 로직이 `entry_ext.dart` 한 곳에 집중 |
| 광고 격리 | `AdService` 실패가 기록 저장에 영향 없음 (onComplete 콜백 패턴) |
