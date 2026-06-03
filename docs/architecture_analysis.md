# PooPooLog — 아키텍처 분석

> 폴더 구조·Provider 목록은 [PROJECT.md](project.md) 참고.
> 화면별 기능 명세는 [app_features.md](app_features.md) 참고.

---

## 목차

1. [앱 시작 흐름](#1-앱-시작-흐름)
2. [탭 구조](#2-탭-구조)
3. [데이터 모델 관계](#3-데이터-모델-관계)
4. [Provider 의존 관계](#4-provider-의존-관계)
5. [화면별 데이터 흐름](#5-화면별-데이터-흐름)
6. [서비스 레이어](#6-서비스-레이어)
7. [로컬 저장소](#7-로컬-저장소)
8. [전체 구조 요약](#8-전체-구조-요약)

---

## 1. 앱 시작 흐름

```
main()
  ├─ Firebase.initializeApp()            # Firebase 초기화 (Remote Config 사전 준비)
  ├─ MobileAds.instance.initialize()     # AdMob 초기화
  ├─ AdService().preload()               # 전면 광고 미리 로드
  ├─ SharedPreferences → 테마·기분표시방식·시작요일·광고제거여부 로드
  ├─ runApp(_SplashApp)                  # 초기화 완료까지 스플래시 최소 1초 표시
  └─ runApp(
       ProviderScope(
         overrides: [
           themeModeProvider, moodDisplayProvider,
           startWeekdaySundayProvider, adsRemovedProvider
         ]
         child: PooPooLogApp → (온보딩 또는 AppShell)
       )
     )

AppShell.initState()
  ├─ Remote Config fetch (app_config JSON)
  ├─ 강제 업데이트 확인
  │    ├─ force_update=true → show 무관, 항상 닫기 불가 팝업 → 이후 로직 중단
  │    └─ force_update=false → show 횟수 체크 후 팝업 여부 결정 (노출 시 카운트 +1)
  ├─ 홈 위젯 액션 확인 (MethodChannel: open_record)
  └─ 공지사항 팝업 확인
       ├─ '다시 보지 않음' 선택 이력 확인 (notice_dismissed_id)
       └─ show 횟수 체크 후 팝업 여부 결정 (노출 시 카운트 +1)
```

- Firebase 초기화를 `main()`에서 `await`으로 처리 → AppShell에서 Remote Config 즉시 사용 가능
- 초기화 완료 전 스플래시 표시 후 `runApp` 교체 방식으로 최소 1초 스플래시 보장
- `ProviderScope.overrides`로 SharedPreferences 로드값 주입 → UI 깜빡임 방지

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

currentTabProvider           StateProvider<int>          탭 인덱스
themeModeProvider            StateProvider<ThemeMode>    테마 (초기값 ProviderScope override)
moodDisplayProvider          StateProvider<MoodDisplay>  기분 표시 방식 (dot/face)
startWeekdaySundayProvider   StateProvider<bool>         캘린더 시작 요일 (true=일요일)
adsRemovedProvider           StateProvider<bool>         광고 제거 구매 여부
purchaseNotifierProvider     NotifierProvider            인앱 결제 흐름 (buy/restore)
calendarFocusedMonthProvider StateProvider<DateTime>     캘린더에서 보고 있는 월
selectedDayProvider          StateProvider<DateTime?>    캘린더 선택 날짜
timelineFilterProvider       StateProvider<TimelineFilter> 타임라인 기분 필터
statsRangeProvider           StateProvider<StatsRange>   통계 기간 설정
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
- 초기 로드 범위: 최근 6개월. `loadMore()` 호출마다 6개월씩 확장 (최대 앱 시작일 2026-05-01)
- 필터: `all / good / okay / bad / visited / notVisited` 6종
- 네이티브 광고: 누적 엔트리 수 % 10 == 0 인 위치에 삽입 (광고 제거 구매 시 미삽입)

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
preload()              전면 광고 미리 로드 (앱 시작 시)
onRecordSaved(adsRemoved)  저장 카운트 +1. adsRemoved=true이면 광고 건너뜀.
                           count == 10 (최초) 또는 (count - 10) % 7 == 0 → 전면 광고 노출.
                           광고 닫힌 후 onComplete() 콜백 실행 → Navigator.pop()
```

- Riverpod Provider 없음, 순수 싱글톤 패턴
- 카운트는 `SharedPreferences`의 `ad_save_count` 키로 영구 저장 (앱 재시작 후에도 누적)

### RemoteConfigService

```
fetchAppConfig()    Firebase Remote Config에서 app_config JSON fetch.
                    실패 시 AppConfig.fallback 반환 (앱 정상 동작 보장).
                    네트워크 없을 때 캐시 사용, 캐시도 없으면 fallback.
```

### HomeWidgetService

```
update(db)          오늘 방문 횟수·마지막 시각·기분 레이블·색상·도트 목록 계산.
                    home_widget SharedPreferences에 저장 후 Android 위젯 갱신.
```

### AppTheme

```dart
static Color moodGood = Color(0xFF3DA06C)  // 맑은 숲 초록
static Color moodOkay = Color(0xFFCC7D30)  // 따뜻한 앰버
static Color moodBad  = Color(0xFFC64848)  // 차분한 로즈 레드
static Color moodNone = Color(0xFF8CA896)  // 그레이 그린 뉴트럴

static ThemeData light()  // Material 3, 수동 ColorScheme (Primary #2D6A4F)
static ThemeData dark()   // 수동 ColorScheme (Primary #74C19A 밝은 민트 그린)
```

---

## 7. 로컬 저장소

앱에서 사용하는 로컬 저장소는 **SharedPreferences**와 **SQLite(Drift)** 두 가지다.
"무엇을 기록했는가"는 SQLite, "앱을 어떻게 설정했는가"는 SharedPreferences로 역할이 구분된다.

### SharedPreferences — 앱 설정 및 상태 (키-값)

앱 시작 시 `main.dart`에서 한꺼번에 읽어 각 Provider 초기값으로 주입하고, 이후 사용자 액션 또는 외부 이벤트 발생 시 그 시점에 저장한다.

| 키 | 타입 | 관리 방법 |
|----|------|----------|
| `theme_mode` | int | **저장**: 더보기 → 테마 선택 시 / **읽기**: 앱 시작 시 Provider 초기화 |
| `mood_display` | String | **저장**: 더보기 → 기분 표시 방식 변경 시 / **읽기**: 앱 시작 시 Provider 초기화 |
| `start_weekday_sunday` | bool | **저장**: 더보기 → 시작 요일 변경 시 / **읽기**: 앱 시작 시 Provider 초기화 |
| `onboarding_seen` | bool | **저장**: 온보딩 완료(시작하기 탭) / **읽기**: 앱 시작 시 온보딩 표시 여부 판단 |
| `ads_removed` | bool | **저장**: 구매·복원 완료 시(purchaseStream 이벤트) / **읽기**: 광고 표시 전 체크 |
| `ad_save_count` | int | **저장**: 기록 저장마다 +1 / **읽기**: 전면 광고 빈도 판단 / **리셋**: 광고 노출 후 0으로 초기화 |
| `notice_dismissed_id` | String | **저장**: 공지 팝업 → "다시 보지 않음" 탭 / **읽기**: 앱 시작 시 공지 표시 여부 판단 / **갱신**: 공지 ID 변경 시 자동 무효화(새 ID와 불일치) |
| `notice_show_count` | int | **저장·갱신**: 공지 팝업 실제 표시 시 +1 / **리셋**: `notice_show_count_id`와 현재 ID 불일치 시 0으로 간주 (키 삭제 없이 논리적 리셋) |
| `notice_show_count_id` | String | **저장·갱신**: 공지 팝업 표시 시 현재 공지 ID로 덮어쓰기 / **용도**: `notice_show_count` 리셋 기준 비교 |
| `update_show_count` | int | **저장·갱신**: 업데이트 팝업 실제 표시 시 +1 / **리셋**: `update_show_count_id`와 현재 `{platform}_{version}` 불일치 시 0으로 간주 |
| `update_show_count_id` | String | **저장·갱신**: 업데이트 팝업 표시 시 현재 `{platform}_{version}`으로 덮어쓰기 / **용도**: `update_show_count` 리셋 기준 비교 |

> **공지·업데이트 카운트 키는 고정 키 2개(카운트 + 기준 ID)로 관리한다.**
> ID/버전이 바뀌면 기준 ID 불일치로 카운트를 0으로 간주해 논리적 리셋이 일어난다.
> 키를 직접 삭제하거나 새 키를 추가하지 않으므로 SharedPreferences 항목이 누적되지 않는다.
>
> `ads_removed`는 구매 완료 시 저장되며, 환불 감지 로직은 없다. 앱 재시작 후에도 광고 제거 상태가 유지된다.

### SQLite (Drift) — 사용자 기록 데이터

`Entries` 테이블에 사용자가 입력한 기록을 저장한다.
저장·수정·삭제 완료 후 관련 Provider를 `invalidate`해 UI를 자동 갱신한다.

| 액션 | 저장 시점 |
|------|----------|
| 기록 저장 | 기록 입력 화면 → 저장 버튼 탭 (`insertEntry`) |
| 기록 수정 | 기록 수정 화면 → 저장 버튼 탭 (`updateEntry`) |
| 기록 삭제 | 기록 화면 → 삭제 버튼 탭 (`deleteEntry`) |
| 전체 초기화 | 더보기 → 데이터 초기화 확인 (`deleteAllEntries`) |
| CSV 가져오기 | 더보기 → CSV 파일 선택 후 확인 (`upsertEntryByTime`) |

---

## 8. 전체 구조 요약

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
│  AdService           (google_mobile_ads — 전면·배너·네이티브) │
│  RemoteConfigService (firebase_remote_config — 강제 업데이트·공지) │
│  HomeWidgetService   (home_widget — Android 홈 화면 위젯)   │
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
