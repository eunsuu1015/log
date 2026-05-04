# Toilet Tracker — 프로젝트 설명

## 개요

**화장실 방문 기록 앱** (Flutter).
언제 화장실을 다녀왔는지, 그때 컨디션이 어땠는지를 기록하고 캘린더 / 타임라인 / 통계로 확인하는 헬스 트래킹 앱.

---

## 기술 스택

| 영역 | 패키지 |
|------|--------|
| 상태 관리 | `flutter_riverpod` |
| 데이터베이스 | `drift` (SQLite ORM) |
| 캘린더 UI | `table_calendar` |
| 차트 | `fl_chart` |
| 알림 | `flutter_local_notifications` |
| 홈 위젯 | `home_widget` |
| 설정 저장 | `shared_preferences` |

---

## 폴더 구조

```
lib/
├── main.dart
├── core/
│   ├── database/
│   │   ├── app_database.dart        # Drift DB 정의, CRUD 쿼리, 변환 확장
│   │   ├── app_database.g.dart      # Drift 코드 생성 결과 (자동)
│   │   └── database_provider.dart   # AppDatabase Riverpod Provider
│   ├── extensions/
│   │   └── entry_ext.dart           # MoodLevelX · EntryX 확장 (색상·레이블·시간 포맷)
│   ├── models/
│   │   └── record_model.dart        # MoodLevel enum, RecordModel 값 객체
│   └── services/
│       ├── home_widget_service.dart # 홈 화면 위젯 업데이트
│       └── notification_service.dart# 로컬 알림 스케줄링
├── features/
│   ├── calendar/
│   │   ├── calendar_screen.dart     # 캘린더 탭 화면
│   │   ├── calendar_provider.dart   # 포커스 달·월별 기록·선택 날짜 Provider
│   │   └── widgets/
│   │       ├── mood_dot_row.dart    # 날짜 셀 기분 도트 행
│   │       ├── day_records_sheet.dart  # 선택된 날 기록 시트
│   │       └── month_picker_sheet.dart # 연/월 빠른 선택 피커
│   ├── timeline/
│   │   ├── timeline_screen.dart     # 타임라인 탭 화면
│   │   ├── timeline_provider.dart   # 필터·그룹화·정렬 Provider
│   │   └── widgets/
│   │       ├── entry_card.dart      # 단일 기록 행 위젯
│   │       ├── date_header.dart     # 날짜 그룹 헤더
│   │       └── filter_chip_row.dart # 기분 필터 칩 행
│   ├── record/
│   │   ├── record_screen.dart       # 기록 입력·수정 화면
│   │   └── record_provider.dart     # 폼 상태 관리 Notifier
│   ├── stats/
│   │   ├── stats_screen.dart        # 통계 화면 (요약·기분 차트·시간대 차트)
│   │   └── stats_provider.dart      # 기간 설정·집계 계산 Provider
│   ├── settings/
│   │   ├── settings_screen.dart     # 설정 화면
│   │   └── notification_settings_screen.dart # 알림 설정
│   └── shell/
│       └── app_shell.dart           # 하단 탭 네비게이션 쉘
└── shared/
    └── theme/
        └── app_theme.dart           # 기분 색상 상수 + 라이트·다크 테마
```

---

## 화면 구성 (3탭)

### 1. 캘린더 탭
- `TableCalendar` 기반 월간 달력
- 각 날짜에 기분 도트 (최대 5개, 초과 시 `+N`) 표시
- 날짜 탭 → 해당 날 기록 하단 패널에 표시
- 헤더 탭 → `CupertinoPicker`로 연/월 빠른 이동
- 다른 달로 이동했을 때만 "오늘로 돌아가기" 버튼 노출

### 2. 타임라인 탭
- 전체 기록을 최신순 + 날짜별 그룹으로 표시
- 필터: 전체 / 좋음 / 보통 / 나쁨 / 안 감
- Pull-to-refresh 지원

### 3. 통계 탭
- `fl_chart` 기반 기분 분포 막대 차트
- 시간대별 방문 횟수 수평 막대 차트
- 기간 선택: 이번 달 / 최근 30일 / 최근 3개월 / 직접 지정

---

## 데이터 모델

### `Entries` 테이블 (SQLite)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | INTEGER PK | 자동 증가 |
| `recordedAt` | DATETIME | 사용자가 지정한 시간 |
| `visited` | BOOLEAN? | 방문 여부 (null = 미입력) |
| `mood` | INTEGER? | 0=좋음, 1=보통, 2=나쁨 |
| `memo` | TEXT? | 메모 |
| `createdAt` | DATETIME | 생성 시각 (자동) |

### `MoodLevel` enum

```dart
enum MoodLevel { good, okay, bad }  // index: 0, 1, 2
```

색상·레이블은 `MoodLevelX` 확장(`entry_ext.dart`)에서 관리한다.

---

## 상태 관리 (Riverpod)

```
calendarFocusedMonthProvider   현재 보고 있는 달
selectedDayProvider            캘린더에서 선택된 날
monthlyEntriesProvider         해당 달의 기록 Map<DateTime, List<Entry>>

timelineFilterProvider         타임라인 필터 (전체/기분별)
timelineProvider               필터링·그룹화된 DayGroup 리스트

recordFormProvider             기록 입력·수정 폼 상태

statsRangeProvider             통계 조회 기간 설정
statsResultProvider            집계 결과 (방문 수·기분 분포·시간대)
```

### 데이터 흐름

```
RecordScreen에서 저장
    → DB insert / update
    → monthlyEntriesProvider invalidate  →  캘린더 자동 갱신
    → timelineProvider invalidate        →  타임라인 자동 갱신
```

---

## 확장 구조 (`entry_ext.dart`)

여러 위젯에서 중복되던 변환 로직을 단일 파일에 통합했다.

```dart
// MoodLevel 확장
MoodLevel.good.color   // AppTheme.moodGood
MoodLevel.good.label   // '좋음'

// Entry 확장
entry.moodColor        // visited·mood 조합 → 표시 색상
entry.moodLabel        // visited·mood 조합 → 표시 텍스트
entry.timeStr          // recordedAt → "HH:mm"
```

---

## 테마 색상 (`app_theme.dart`)

| 상수 | 색상 | 용도 |
|------|------|------|
| `moodGood` | `#639922` (녹색) | 좋음 |
| `moodOkay` | `#BA7517` (주황) | 보통 |
| `moodBad` | `#E24B4A` (빨강) | 나쁨 |
| `moodNone` | `#B4B2A9` (회색) | 안 감 / 미입력 |
| `primaryBlue` | `#185FA5` | 주 색상 |

Material 3 기반, 라이트·다크 테마 모두 지원.

---

## 부가 기능

- **홈 위젯** (`home_widget_service.dart`): 홈 화면에 오늘 기록 요약 표시
- **로컬 알림** (`notification_service.dart`): 기록 리마인더, 설정 화면 별도 제공
- **한국어 지역화**: 캘린더, 날짜 포맷 전부 `ko_KR`


fontSize	사용 횟수	주요 사용처
7	1	mood_dot_row.dart — 무드 점 레이블
10	1	settings_screen.dart
11	5+	app_theme.dart, 캘린더, 타임라인, 통계
12	6+	타임라인 카드, 캘린더, 기록, 설정, 알림설정
13	9+	캘린더, 타임라인, 통계, 설정, 기록 (가장 넓게 쓰임)
14	3	타임라인 카드, 캘린더 시트, 기록
15	3	타임라인, 기록
16	4+	캘린더, 월 피커, 알림설정, 기록
26	1	stats_screen.dart — 통계 주요 수치