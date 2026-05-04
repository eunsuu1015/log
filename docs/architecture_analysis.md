# Toilet Tracker — 아키텍처 분석 문서

---

## 목차

1. [진입점과 데이터 흐름](#1-진입점과-데이터-흐름)
2. [데이터 모델과 DB 스키마](#2-데이터-모델과-db-스키마)
3. [상태 관리 구조](#3-상태-관리-구조)
4. [화면별 분석](#4-화면별-분석)
5. [서비스·유틸리티 레이어](#5-서비스유틸리티-레이어)
6. [전체 구조 요약](#6-전체-구조-요약)

---

## 1. 진입점과 데이터 흐름

### 앱 시작 순서

```
main()
  └─ runApp(ProviderScope → ToiletTrackerApp → AppShell)
  └─ addPostFrameCallback
       └─ _initServicesInBackground()
            ├─ HomeWidgetService.init()
            └─ NotificationService.rescheduleIfNeeded()
```

- 서비스 초기화를 첫 프레임 이후에 실행해 앱 구동 속도에 영향 없음
- `ProviderScope`가 최상단 → 전체 위젯 트리에서 Provider 접근 가능
- `themeMode: ThemeMode.system` → 시스템 다크/라이트 자동 대응

### 탭 구조

`AppShell`은 `IndexedStack`으로 3개 탭을 항상 메모리에 유지한다.
탭 전환은 `_currentTabProvider` (StateProvider\<int\>) 하나로 제어.

```
AppShell (IndexedStack)
  ├─ index 0: CalendarScreen
  ├─ index 1: TimelineScreen
  └─ index 2: StatsScreen
```

---

## 2. 데이터 모델과 DB 스키마

### 모델 계층 구조

```
MoodLevel (enum)          RecordModel (domain)      Entry (DB row)
─────────────────         ────────────────────      ──────────────
good  → index 0           id: int                   Drift 자동 생성
okay  → index 1           recordedAt: DateTime      app_database.g.dart
bad   → index 2           visited: bool?
                          mood: MoodLevel?
                          memo: String?
                          createdAt: DateTime
```

- `RecordModel` — 순수 Dart 도메인 객체, Freezed 없이 수동 `copyWith` 구현
- `Entry` — Drift가 자동 생성하는 DB row 클래스
- 실제 UI에서는 `Entry`를 직접 사용하고, `RecordModel`은 변환 전용으로 존재

### Entries 테이블 스키마

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| `id` | INTEGER | PK, autoIncrement | 고유 식별자 |
| `recordedAt` | DATETIME | NOT NULL | 사용자 지정 기록 시각 |
| `visited` | BOOLEAN | **nullable** | null=미입력, false=안 감, true=다녀옴 |
| `mood` | INTEGER | **nullable** | MoodLevel.index (0·1·2) |
| `memo` | TEXT | **nullable** | 자유 메모 |
| `createdAt` | DATETIME | withDefault(now) | 앱이 저장한 실제 시각 (자동) |

**설계 포인트:**
- `visited`가 nullable → `null` / `false` / `true` 3가지 상태 표현
- `mood`는 enum index로 저장, 읽을 때 `MoodLevel.values[mood!]`로 복원
- `recordedAt`과 `createdAt` 분리 → 과거 날짜로 기록 입력 가능

### visited + mood 조합 → 표시 레이블

| visited | mood | 레이블 | 색상 |
|---|---|---|---|
| `null` | - | `—` | moodNone (회색) |
| `false` | - | `안 감` | moodNone (회색) |
| `true` | `null` | `다녀옴` | moodNone (회색) |
| `true` | `good` | `좋음` | moodGood (초록) |
| `true` | `okay` | `보통` | moodOkay (주황) |
| `true` | `bad` | `나쁨` | moodBad (빨강) |

이 로직은 `entry_ext.dart`의 `EntryX` 확장에 집중되어 있다.

---

## 3. 상태 관리 구조

### Provider 의존 관계

```
appDatabaseProvider (Provider<AppDatabase>)
        │
        ├─ monthlyEntriesProvider(DateTime)     FutureProvider.family
        │        └─ watch: calendarFocusedMonthProvider (StateProvider<DateTime>)
        │
        ├─ timelineProvider                     FutureProvider<List<DayGroup>>
        │        └─ watch: timelineFilterProvider (StateProvider<TimelineFilter>)
        │
        ├─ statsResultProvider                  FutureProvider<StatsResult>
        │        └─ watch: statsRangeProvider (StateProvider<StatsRange>)
        │
        └─ recordFormProvider(Entry?)           NotifierProvider.family
                 └─ Entry? = null → 신규 / Entry? = 기존 → 수정

selectedDayProvider          StateProvider<DateTime?>  캘린더 선택 날짜
notificationSettingsProvider AsyncNotifierProvider     알림 설정
```

### 기록 저장 후 invalidate 패턴

기록 저장·수정·삭제 후 관련 Provider 3개를 동시에 초기화해 각 화면을 갱신한다.

```dart
ref.invalidate(monthlyEntriesProvider(month))  // 캘린더 도트 갱신
ref.invalidate(timelineProvider)               // 타임라인 목록 갱신
ref.invalidate(statsResultProvider)            // 통계 재계산
```

**설계 포인트:**
- `monthlyEntriesProvider`는 family → 월마다 독립 캐시, 다른 월 데이터 보존
- `recordFormProvider(Entry?)`는 family → null=신규, Entry 있으면 수정 모드
- `appDatabaseProvider`는 `ref.onDispose(db.close)` 등록 → 앱 종료 시 DB 정상 닫힘

---

## 4. 화면별 분석

### 4-1. 캘린더 탭

**watch 중인 Provider:** `calendarFocusedMonthProvider`, `selectedDayProvider`, `monthlyEntriesProvider`

#### 사용자 액션 → 상태 변경 흐름

```
월 스와이프
  → calendarFocusedMonthProvider 갱신
  → monthlyEntriesProvider(newMonth) 로딩 시작
  → valueOrNull 로 로딩 중 빈 맵 사용 (캘린더 위젯 유지)

날짜 탭 (기록 없음)
  → selectedDayProvider 갱신
  → addPostFrameCallback → Navigator.push(RecordScreen)

날짜 탭 (기록 있음)
  → selectedDayProvider 갱신
  → _DayPanel 하단 패널 노출

헤더 월 탭
  → showMonthPickerSheet (Cupertino 드럼롤 피커)
  → calendarFocusedMonthProvider 갱신

FAB 탭
  → addPostFrameCallback → Navigator.push(RecordScreen)
```

#### 하위 위젯

| 위젯 | 역할 |
|---|---|
| `MoodDotRow` | Entry 목록 → 기분 색상 도트 최대 5개, 초과 시 `+N` |
| `_DayPanel` | 선택된 날 기록 목록 + 추가 버튼 |
| `MonthPickerSheet` | CupertinoPicker 2개 (연도·월), StatefulWidget |

---

### 4-2. 타임라인 탭

#### 데이터 변환 흐름

```
DB: List<Entry> (전체)
      ↓ timelineProvider (필터링 + 날짜 그룹)
List<DayGroup> { date, entries[] }
      ↓ _TimelineList.build() (평탄화)
List<_ListItem> [header, entry, entry, header, entry, ...]
      ↓ ListView.separated
DateHeader / EntryCard
```

`TimelineFilter`가 변경되면 `timelineProvider`가 재실행되어 필터링된 데이터를 반환한다.

#### 하위 위젯

| 위젯 | 역할 |
|---|---|
| `FilterChipRow` | 기분 필터 칩 5개, `timelineFilterProvider` 읽기·쓰기 |
| `DateHeader` | 날짜 그룹 헤더, 오늘·어제는 색상 강조 |
| `EntryCard` | 기분 도트, 레이블, 메모(2줄), 시간 표시 |

---

### 4-3. 통계 탭

#### 기간 → 날짜 범위 계산

| 기간 옵션 | from | to | totalDays |
|---|---|---|---|
| `thisMonth` | 월 1일 | 오늘 + 1일 | `today.day` |
| `last30` | 오늘 - 30일 | 오늘 | 30 |
| `last3Months` | 2개월 전 1일 | 오늘 | ~90 |
| `custom` | picker 선택 | picker 선택 | 선택 범위 |

#### StatsResult 집계 (단일 패스)

```
입력: List<Entry> (범위 내 전체)
  ↓ visited == true 필터링
  ↓ hourlyCounts[0..23] 카운팅
  ↓ moodCounts Map 집계
  ↓ visitedDays — 날짜 Set으로 중복 제거
출력: StatsResult { totalVisits, moodCounts, hourlyCounts, peakHour, totalDays, visitedDays }
```

---

### 4-4. 기록 입력·수정 화면

#### 폼 상태 머신 (RecordFormState)

```
RecordFormState
  ├─ recordedAt: DateTime   ← DatePicker / CupertinoTimePicker
  ├─ visited: bool?         ← SwitchListTile
  ├─ mood: MoodLevel?       ← MoodSelector (visited=true 일 때만 AnimatedSize로 노출)
  ├─ memo: String?          ← TextField + QuickTags
  └─ isSaving: bool         ← 저장 중 버튼 비활성화
```

**주요 동작:**
- `visited = false`로 변경 시 `mood`도 자동으로 `null` 초기화 (`setVisited` 내부 처리)
- `presetDate` 전달 시 해당 날짜·현재 시각으로 초기화 (캘린더 날짜 탭 시)
- 저장 흐름: DB upsert → `HomeWidgetService.update()` → `Navigator.pop()`

#### 신규 vs 수정 모드

```
recordFormProvider(null)    → 신규 모드, RecordFormState(recordedAt: now)
recordFormProvider(entry)   → 수정 모드, entry 데이터로 초기화
```

기록 화면 열기 직전에 `ref.invalidate(recordFormProvider(null))`로 이전 입력 초기화.

---

### 4-5. 설정 화면

```
SettingsScreen
  ├─ 알림 설정 → NotificationSettingsScreen
  │     ├─ ON/OFF 토글 (권한 요청 포함)
  │     └─ 시간 선택 (CupertinoTimePickerSheet)
  ├─ 홈 위젯 가이드 → _WidgetGuideSheet (BottomSheet)
  └─ 앱 정보 (버전 1.0.0)
```

`notificationSettingsProvider` (AsyncNotifierProvider) 가 SharedPreferences에서 설정을 로드한다.

---

## 5. 서비스·유틸리티 레이어

### NotificationService

```
init()                  플러그인 초기화 (5초 타임아웃)
requestPermission()     iOS: 플러그인 API / Android: permission_handler
scheduleDaily()         zonedSchedule + matchDateTimeComponents.time (매일 반복)
                        이미 지난 시각이면 자동으로 내일로 설정
cancel()                알림 ID 1001 취소
rescheduleIfNeeded()    SharedPreferences 확인 → 켜져 있으면 재등록
```

설정 저장소: `SharedPreferences` (enabled, hour, minute 3개 키)

### HomeWidgetService

```
init()     App Group ID 설정 (3초 타임아웃, 실패해도 _ready=false 로 무시)
update()   오늘 기록 집계 → 5가지 데이터 저장 → updateWidget() 호출
```

| 저장 키 | 내용 |
|---|---|
| `visit_count` | 오늘 방문 횟수 (int) |
| `last_mood` | 마지막 기분 이모지 (😊 / 😐 / 😣 / —) |
| `last_time` | 마지막 기록 시각 (HH:mm) |
| `date_label` | 날짜 레이블 (m/d) |
| `total_label` | "오늘 n회" 문자열 |

`_ready` 플래그로 init 실패 시 update를 건너뜀 → 홈위젯 오류가 기록 저장에 영향 없음

### AppTheme

```dart
// 기분 색상 (앱 전체 공유)
moodGood = Color(0xFF639922)  // 초록
moodOkay = Color(0xFFBA7517)  // 주황
moodBad  = Color(0xFFE24B4A)  // 빨강
moodNone = Color(0xFFB4B2A9)  // 회색 (미입력)

primaryBlue = Color(0xFF185FA5)
```

Material 3 `ColorScheme.fromSeed(primaryBlue)` 기반.
다크 테마는 `NavigationBarTheme` 미설정으로 라이트 테마보다 설정이 적음.

### Log 유틸리티

```dart
Log.w(tag, message, [error])           // WARNING — 앱 동작은 계속
Log.e(tag, message, [error, stack])    // ERROR   — 기능 실패
```

`dart:developer`의 `log()`를 래핑, level 900(w) / 1000(e) 구분.

---

## 6. 전체 구조 요약

```
┌─────────────────────────────────────────────────────────┐
│  UI Layer                                               │
│                                                         │
│  AppShell (IndexedStack)                                │
│    ├── CalendarScreen ──┐                               │
│    ├── TimelineScreen   ├─── RecordScreen (push)        │
│    ├── StatsScreen      │                               │
│    └── SettingsScreen ──┘ (push from Calendar)          │
└─────────────────────────────────────────────────────────┘
          │ watch / read
┌─────────────────────────────────────────────────────────┐
│  State Layer — Riverpod                                 │
│                                                         │
│  appDatabaseProvider                                    │
│    ├── monthlyEntriesProvider(month)                    │
│    ├── timelineProvider ← timelineFilterProvider        │
│    ├── statsResultProvider ← statsRangeProvider         │
│    └── recordFormProvider(entry?)                       │
│                                                         │
│  calendarFocusedMonthProvider                           │
│  selectedDayProvider                                    │
│  notificationSettingsProvider                           │
└─────────────────────────────────────────────────────────┘
          │ async
┌─────────────────────────────────────────────────────────┐
│  Service Layer                                          │
│                                                         │
│  NotificationService  (flutter_local_notifications)     │
│  HomeWidgetService    (home_widget)                     │
└─────────────────────────────────────────────────────────┘
          │ SQL
┌─────────────────────────────────────────────────────────┐
│  Data Layer — Drift                                     │
│                                                         │
│  AppDatabase → Entries 테이블 (SQLite)                  │
│    getEntriesForDate / getEntriesInRange / getEntriesForMonth
│    insertEntry / updateEntry / deleteEntry              │
└─────────────────────────────────────────────────────────┘
```

### 전체적인 설계 특징

| 특징 | 내용 |
|---|---|
| 단방향 데이터 흐름 | DB → Provider → UI, 역방향 없음 |
| 서비스 격리 | 알림·홈위젯 실패가 기록 저장에 영향 없음 |
| 지연 초기화 | 서비스 초기화를 첫 프레임 이후로 분리 |
| 타입 혼재 | `RecordModel`(도메인)과 `Entry`(DB row)가 공존, UI는 `Entry` 직접 사용 |
| 확장 함수 집중 | `visited + mood` 조합 로직이 `entry_ext.dart` 한 곳에 집중 |
| 캐시 전략 | `family` Provider로 월별 독립 캐시, invalidate로 수동 갱신 |


### 앱 개발 순서

1단계: 기반 (Core)
1. core/utils/log.dart                      # 로거 유틸
2. shared/theme/app_theme.dart              # 색상/테마 상수
3. core/models/record_model.dart            # 데이터 모델 (MoodLevel enum 포함)
4. core/extensions/entry_ext.dart          # 모델 확장 (색상, 레이블, 포맷)
5. core/database/app_database.dart          # DB 테이블 + CRUD 메서드
6. core/database/database_provider.dart    # DB Riverpod Provider
   2단계: 서비스
7. core/services/notification_service.dart
8. core/services/home_widget_service.dart
   3단계: 공유 위젯
9. shared/widgets/cupertino_time_picker_sheet.dart
   4단계: Feature (Provider → Screen 순)
# 기록 입력 (가장 핵심)
10. features/record/record_provider.dart
11. features/record/record_screen.dart
# 캘린더
12. features/calendar/calendar_provider.dart
13. features/calendar/widgets/mood_dot_row.dart
14. features/calendar/widgets/month_picker_sheet.dart
15. features/calendar/widgets/day_records_sheet.dart
16. features/calendar/calendar_screen.dart
# 타임라인
17. features/timeline/timeline_provider.dart
18. features/timeline/widgets/entry_card.dart
19. features/timeline/widgets/date_header.dart
20. features/timeline/widgets/filter_chip_row.dart
21. features/timeline/timeline_screen.dart
# 통계
22. features/stats/stats_provider.dart
23. features/stats/stats_screen.dart
# 설정
24. features/settings/notification_settings_screen.dart
25. features/settings/settings_screen.dart
    5단계: 앱 조립
26. features/shell/app_shell.dart           # 탭 네비게이션
27. main.dart                               # 진입점
    핵심 원칙: DB → Provider → Widget → Screen → Shell → main 순서로, 아래 계층이 완성되어야 위 계층을 만들 수 있습니다.