# Toilet Tracker — 앱 기능 문서

> 화장실 방문 여부·기분·메모를 기록하고 캘린더·타임라인·통계로 시각화하는 개인 건강 기록 앱

---

## 목차

1. [앱 구조](#1-앱-구조)
2. [캘린더 탭](#2-캘린더-탭)
3. [기록 탭 (타임라인)](#3-기록-탭-타임라인)
4. [통계 탭](#4-통계-탭)
5. [기록 입력·수정 화면](#5-기록-입력수정-화면)
6. [설정 화면](#6-설정-화면)
7. [데이터 모델](#7-데이터-모델)
8. [상태 관리 Provider 목록](#8-상태-관리-provider-목록)
9. [기술 스택](#9-기술-스택)

---

## 1. 앱 구조

```
lib/
├── main.dart                        # 앱 진입점, 서비스 초기화
├── core/
│   ├── database/                    # Drift ORM + SQLite
│   ├── extensions/                  # MoodLevel·Entry 확장 함수
│   ├── models/                      # RecordModel, MoodLevel enum
│   ├── services/                    # 알림(NotificationService), 홈위젯(HomeWidgetService)
│   └── utils/                       # Log 유틸리티
├── features/
│   ├── shell/                       # 하단 NavigationBar + IndexedStack
│   ├── calendar/                    # 캘린더 탭
│   ├── record/                      # 기록 입력·수정 화면
│   ├── timeline/                    # 기록 탭 (타임라인)
│   ├── stats/                       # 통계 탭
│   └── settings/                    # 설정·알림설정 화면
└── shared/
    ├── theme/                       # Material 3 라이트·다크 테마
    └── widgets/                     # 공용 위젯 (CupertinoTimePickerSheet)
```

하단 네비게이션은 `IndexedStack`으로 3개 탭(캘린더·기록·통계)을 메모리에 유지한다.

---

## 2. 캘린더 탭

**파일** `lib/features/calendar/calendar_screen.dart`

### 주요 기능

| 기능 | 설명 |
|---|---|
| 월간 달력 | `table_calendar` 라이브러리, 좌우 스와이프로 월 이동 |
| 기분 도트 | 기록이 있는 날짜 아래 기분 색상 도트 표시 (최대 5개, 초과 시 `+N`) |
| 날짜 선택 | 기록 있음 → 하단 패널에 목록 표시 / 기록 없음 → 기록 입력 화면으로 이동 |
| 월 피커 | 헤더 탭 시 Cupertino 드럼롤 스타일 연·월 선택기 (2026 ~ 현재년) |
| 오늘 이동 | 현재 월이 아닐 때 AppBar에 "오늘로 돌아가기" 버튼 노출 |
| 기록 추가 | 우하단 FAB(+) 탭 → 기록 입력 화면 |
| 설정 진입 | 우상단 설정 아이콘 → 설정 화면 |

### 날짜 하단 패널 (`_DayPanel`)

선택된 날짜에 기록이 있을 때 표시된다.

- `"m월 d일"` 헤더 + **"추가"** 버튼
- 해당 날의 기록 목록 (`EntryCard` 리스트)
- 기록 탭 → 수정 화면으로 이동

---

## 3. 기록 탭 (타임라인)

**파일** `lib/features/timeline/timeline_screen.dart`

### 주요 기능

| 기능 | 설명 |
|---|---|
| 전체 기록 목록 | 최신순 정렬, 날짜별 그룹 |
| 날짜 헤더 | 오늘·어제는 컬러 강조 + 왼쪽 바 / 그 외는 "m월 d일 (요일)" |
| 기분 필터 | 상단 칩 5개: 전체 / 좋음 / 보통 / 나쁨 / 안 감 |
| 기록 카드 | 기분 도트, 기분 레이블, 메모(2줄 요약), 시간 표시 |
| Pull-to-refresh | 아래로 당겨 새로고침 |
| 기록 수정 | 카드 탭 → 수정 화면으로 이동 |
| 기록 추가 | 우하단 FAB(+) |
| 빈 상태 | 기록 없음 / 필터 결과 없음 각각 다른 안내 메시지 |

---

## 4. 통계 탭

**파일** `lib/features/stats/stats_screen.dart`

### 기간 선택

| 옵션 | 설명 |
|---|---|
| 이번 달 | 1일 ~ 오늘 (미래 날짜 제외) |
| 최근 30일 | 오늘 기준 30일 전 ~ 오늘 |
| 최근 3개월 | 이번 달 포함 3개월 |
| 직접 지정 | DateRangePicker로 시작·종료일 선택 |

### 요약 카드

- **총 방문 횟수** — `"n번"` + `"n일 동안 방문"`
- **방문한 날 수** — `"n일"` + `"n일 중 하루 이상 방문한 날"`
- **주요 방문 시간** — `"HH시"` (피크 시간대)

### 차트

| 차트 | 설명 |
|---|---|
| 기분 분포 막대 차트 | 좋음·보통·나쁨 각 횟수, 막대 위에 횟수 레이블 |
| 시간대별 방문 수평 막대 | 0~23시, 기록이 있는 시간대만 표시, 비율 기반 길이 |

기간 내 데이터가 없으면 `"이 기간에 기록이 없어요"` 메시지 표시.

---

## 5. 기록 입력·수정 화면

**파일** `lib/features/record/record_screen.dart`

### 입력 필드

| 필드 | 위젯 | 설명 |
|---|---|---|
| 날짜 | `DatePicker` (Material) | 기록할 날짜 선택 |
| 시간 | `CupertinoDatePicker` | iOS 드럼롤 휠, 24시간 포맷 |
| 방문 여부 | `SwitchListTile` | 화장실에 다녀왔는지 토글 |
| 기분 | 버튼 3개 | 좋음·보통·나쁨, 방문=ON일 때만 `AnimatedSize`로 노출 |
| 메모 | `TextField` (4줄) | 자유 텍스트 입력 |
| 빠른 태그 | `ActionChip` 5개 | 쾌변·설사·배아픔·잔변감·급했음 → 탭하면 메모에 자동 추가 |

### 동작

- **신규**: `presetDate` 전달 시 해당 날짜·현재 시각으로 초기화
- **수정**: 기존 `Entry` 데이터로 폼 초기화
- **저장**: DB upsert → 홈 위젯 데이터 갱신
- **삭제** (수정 모드만): 확인 다이얼로그 후 DB 삭제

---

## 6. 설정 화면

**파일** `lib/features/settings/settings_screen.dart`

### 알림 설정 (`NotificationSettingsScreen`)

| 기능 | 설명 |
|---|---|
| 알림 ON/OFF | `SwitchListTile` 토글, 켜면 시스템 권한 요청 |
| 알림 시간 | CupertinoDatePicker (iOS 스타일), 기본값 09:00 |
| 설정 저장 | `SharedPreferences` 로컬 저장 |
| 자동 재등록 | 앱 재시작 시 설정이 켜져 있으면 알림 스케줄 재등록 |

알림 내용: 제목 `"기록할 시간이에요"` / 본문 `"오늘 화장실 기록을 남겨보세요"`

### 홈 위젯 가이드

- iOS: 홈 화면 길게 누르기 → `+` → 앱 검색 → 위젯 추가
- Android: 홈 화면 길게 누르기 → 위젯 메뉴 → 위젯 찾아 추가

홈 위젯에 표시되는 정보:
- 오늘 방문 횟수
- 마지막 기록의 기분 이모지 (😊 / 😐 / 😣)
- 마지막 기록 시간 (`HH:mm`)
- 날짜 레이블 (`m/d`)

### 앱 정보

- 버전 `1.0.0`

---

## 7. 데이터 모델

### Entries 테이블 (SQLite, Drift ORM)

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `id` | INTEGER (PK) | 자동 증가 |
| `recordedAt` | DATETIME | 사용자가 설정한 기록 날짜·시간 |
| `visited` | BOOLEAN (nullable) | 방문 여부 (`null` = 미입력) |
| `mood` | INTEGER (nullable) | 0=좋음, 1=보통, 2=나쁨 |
| `memo` | TEXT (nullable) | 자유 메모 |
| `createdAt` | DATETIME | 앱에서 실제 저장된 시각 (자동) |

### MoodLevel enum

| 값 | 레이블 | 색상 |
|---|---|---|
| `good` | 좋음 | `#639922` (초록) |
| `okay` | 보통 | `#BA7517` (주황) |
| `bad` | 나쁨 | `#E24B4A` (빨강) |
| (없음) | 안 감 / 다녀옴 | `#B4B2A9` (회색) |

---

## 8. 상태 관리 Provider 목록

| Provider | 종류 | 역할 |
|---|---|---|
| `appDatabaseProvider` | Provider | AppDatabase 싱글톤 |
| `calendarFocusedMonthProvider` | StateProvider | 캘린더에서 보고 있는 월 |
| `selectedDayProvider` | StateProvider | 캘린더에서 선택된 날짜 |
| `monthlyEntriesProvider` | FutureProvider.family | 월별 기록 Map (캘린더 도트용) |
| `timelineFilterProvider` | StateProvider | 타임라인 기분 필터 |
| `timelineProvider` | FutureProvider | 전체 기록 그룹 목록 |
| `statsRangeProvider` | StateProvider | 통계 기간 설정 |
| `statsResultProvider` | FutureProvider | 통계 계산 결과 |
| `recordFormProvider` | NotifierProvider.family | 기록 폼 입력 상태 |
| `notificationSettingsProvider` | AsyncNotifierProvider | 알림 설정 로드·저장 |

---

## 9. 기술 스택

| 역할 | 라이브러리 | 버전 |
|---|---|---|
| UI | Flutter + Material 3 | `>=3.19.0` |
| 상태 관리 | flutter_riverpod | `^2.5.1` |
| 데이터베이스 | drift + sqlite3_flutter_libs | `^2.18.0` |
| 캘린더 | table_calendar | `^3.1.2` |
| 차트 | fl_chart | `^0.68.0` |
| 알림 | flutter_local_notifications + timezone | `^17.2.2` |
| 홈 위젯 | home_widget | `^0.9.0` |
| 로컬 저장소 | shared_preferences | `^2.2.3` |
| 권한 | permission_handler | `^11.3.1` |
