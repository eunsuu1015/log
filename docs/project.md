# PooPooLog — 프로젝트 문서

## 폴더 구조

```
lib/
├── main.dart                             # 앱 진입점, Firebase·AdMob 초기화, 스플래시→실제 앱 교체
├── core/
│   ├── ads/
│   │   ├── ad_ids.dart                   # 플랫폼별 광고 단위 ID (출시 전 실제 ID로 교체)
│   │   ├── ad_service.dart               # 전면 광고 싱글톤 (로드·노출·빈도 관리)
│   │   ├── banner_ad_widget.dart         # 배너 광고 위젯
│   │   └── native_ad_widget.dart         # 네이티브 광고 위젯
│   ├── database/
│   │   ├── app_database.dart             # Drift DB 정의, CRUD 메서드, 변환 확장
│   │   ├── app_database.g.dart           # 코드 생성 결과 (수정 금지)
│   │   └── database_provider.dart        # AppDatabase Riverpod Provider
│   ├── extensions/
│   │   └── entry_ext.dart                # MoodLevelX · EntryX 확장 (색상·레이블·시간)
│   ├── iap/
│   │   └── iap_provider.dart             # adsRemovedProvider, PurchaseNotifier (인앱 결제), IAPStatus (idle/loading/error/canceled)
│   ├── models/
│   │   ├── record_model.dart             # MoodLevel enum, RecordModel 값 객체
│   │   └── mood_display_provider.dart    # MoodDisplay enum, moodDisplayProvider, loadMoodDisplay()
│   ├── notice/
│   │   └── notice.dart                   # Notice 모델, SharedPreferences 키 상수 (kNoticeDismissedKey, kNoticeShowCountKeyPrefix, kUpdateShowCountKeyPrefix)
│   ├── remote_config/
│   │   ├── app_config.dart               # AppConfig·NoticeConfig·UpdateConfig 모델, isOutdated()
│   │   └── remote_config_service.dart    # Firebase Remote Config fetch 서비스
│   ├── settings/
│   │   └── display_settings.dart         # startWeekdaySundayProvider
│   └── widget/
│       └── home_widget_service.dart      # HomeWidgetService — 홈 화면 위젯 데이터 갱신
├── features/
│   ├── shell/
│   │   └── app_shell.dart                # 하단 탭 네비게이션 (4탭), currentTabProvider
│   ├── calendar/
│   │   ├── calendar_screen.dart
│   │   ├── calendar_provider.dart
│   │   └── widgets/
│   │       ├── mood_dot_row.dart          # 날짜 셀 기분 도트 행
│   │       └── month_picker_sheet.dart   # 연·월 빠른 선택 피커
│   ├── notice/
│   │   └── notice_dialog.dart            # 공지사항 팝업 다이얼로그
│   ├── onboarding/
│   │   └── onboarding_screen.dart        # 최초 실행 온보딩 3장 슬라이드
│   ├── record/
│   │   ├── record_screen.dart
│   │   └── record_provider.dart
│   ├── stats/
│   │   ├── stats_screen.dart
│   │   ├── stats_provider.dart
│   │   └── widgets/
│   │       ├── summary_card.dart          # 요약 카드 위젯
│   │       └── stat_heat_map_grid.dart    # 시간대별 히트맵 + 자세히 보기 바 차트
│   ├── timeline/
│   │   ├── timeline_screen.dart
│   │   ├── timeline_provider.dart
│   │   └── widgets/
│   │       ├── date_header.dart           # 날짜 그룹 헤더
│   │       └── filter_chip_row.dart       # 기분 필터 칩 행
│   ├── update/
│   │   └── force_update_dialog.dart      # 강제 업데이트 팝업 (닫기 불가)
│   └── more/
│       └── more_screen.dart
├── shared/
│   ├── theme/
│   │   ├── app_theme.dart                # 기분 색상 상수, 라이트·다크 테마 (수동 ColorScheme)
│   │   └── style.dart                    # 공통 반지름·버튼·카드 스타일 상수
│   └── widgets/
│       ├── entry_card.dart               # 공용 기록 카드 위젯
│       ├── mood_indicator.dart           # MoodIndicator — dot/face 전환 통합 위젯
│       ├── mood_face_painter.dart        # CustomPainter — 웃음/일자/찡그림 얼굴
│       └── new_user_empty_state.dart     # 신규 유저 빈 상태 공용 위젯
└── utils/
    └── logger.dart                       # 디버그 로거
```

---

## 화면 구성 (4탭)

### 1. 캘린더
- `TableCalendar` 기반 월간 달력, 기분 도트 표시
- 날짜 탭 → 하단 패널에 기록 목록 / 기록 없으면 입력 화면 이동
- 헤더 탭 → 연·월 피커 (Cupertino 드럼롤)

### 2. 타임라인
- 전체 기록 최신순 + 날짜 그룹, 기분 필터 칩 6개 (전체/좋음/보통/나쁨/다녀옴/안 감)
- 초기 6개월 로드, `loadMore()`로 6개월씩 확장 (앱 시작일 2026-05-01 고정)
- 네이티브 광고: 누적 엔트리 수가 10의 배수인 위치마다 삽입

### 3. 통계
- 기분 분포 도넛 차트, 시간대별 방문 수 히트맵 그리드 (6×4) + 자세히 보기 바 차트
- 기간 선택: 이번 달 / 최근 30일 / 최근 90일 / 직접 지정
- 하단 고정 배너 광고

### 4. 더보기
- 다크모드·기분 표시 방식·주 시작 요일 설정
- 피드백 보내기, 개인정보처리방침, 오픈소스 라이선스, 앱 가이드
- CSV 내보내기·가져오기, 데이터 초기화
- 광고 없애기 인앱 결제 (₩2,900 일회성)

---

## 데이터 모델

### `Entries` 테이블 (SQLite, Drift ORM)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | INTEGER PK | 자동 증가 |
| `recordedAt` | DATETIME | 사용자가 지정한 시간 |
| `visited` | BOOLEAN? | null=미입력, false=안 감, true=다녀옴 |
| `mood` | INTEGER? | 0=좋음, 1=보통, 2=나쁨 |
| `memo` | TEXT? | 메모 (빈 문자열은 null로 저장) |
| `createdAt` | DATETIME | 앱 저장 시각 (자동) |

### `MoodLevel` enum

```dart
enum MoodLevel { good, okay, bad }  // index: 0, 1, 2
```

`visited + mood` 조합 → 표시 색상·레이블 변환 로직은 `entry_ext.dart`의 `EntryX` 확장에 집중.

### DB 메서드 (`AppDatabase`)

| 메서드 | 설명 |
|--------|------|
| `getEntriesForDate(date)` | 특정 날짜 기록 오름차순 |
| `getEntriesInRange(from, to)` | from 이상 to 미만 범위 |
| `getEntriesForMonth(year, month)` | 월별 기록 `Map<DateTime, List<Entry>>` |
| `insertEntry(companion)` | 신규 삽입, 생성된 id 반환 |
| `updateEntry(companion)` | id 기준 전체 교체 |
| `upsertEntryByTime(companion)` | 동일 `recordedAt` 존재 시 UPDATE, 없으면 INSERT |
| `deleteEntry(id)` | 단건 삭제 |
| `deleteAllEntries()` | 전체 삭제 |
| `getOldestEntryDate()` | 가장 오래된 기록의 `recordedAt` (없으면 null) |

---

## 상태 관리 (Riverpod)

| Provider | 종류 | 역할 |
|----------|------|------|
| `appDatabaseProvider` | Provider | AppDatabase 싱글톤 |
| `currentTabProvider` | StateProvider | 현재 선택된 탭 인덱스 |
| `themeModeProvider` | StateProvider | 라이트·다크 테마 설정 |
| `moodDisplayProvider` | StateProvider | 기분 표시 방식 (dot / face) |
| `startWeekdaySundayProvider` | StateProvider | 캘린더 시작 요일 설정 |
| `adsRemovedProvider` | StateProvider | 광고 제거 구매 여부 |
| `purchaseNotifierProvider` | NotifierProvider | 인앱 결제 흐름 (buy / restore) |
| `earliestEntryDateProvider` | FutureProvider | 가장 오래된 기록 날짜 (없으면 null) |
| `calendarFocusedMonthProvider` | StateProvider | 캘린더에서 보고 있는 월 |
| `selectedDayProvider` | StateProvider | 캘린더에서 선택된 날짜 |
| `monthlyEntriesProvider` | FutureProvider.family | 월별 기록 Map (캘린더 도트용) |
| `timelineFilterProvider` | StateProvider | 타임라인 기분 필터 |
| `timelineProvider` | AsyncNotifier | 필터링·그룹화된 기록 목록 |
| `recordFormProvider` | NotifierProvider.family | 기록 입력·수정 폼 상태 |
| `statsRangeProvider` | StateProvider | 통계 기간 설정 |
| `statsResultProvider` | FutureProvider | 통계 집계 결과 |

### 기록 저장 후 갱신 흐름

```
RecordScreen 저장
  → DB insert / update
  → monthlyEntriesProvider invalidate  →  캘린더 갱신
  → timelineProvider invalidate        →  타임라인 갱신
  → statsResultProvider invalidate     →  통계 갱신
  → HomeWidgetService.update()         →  홈 화면 위젯 갱신
```

---

## Android 홈 화면 위젯

| 크기 | 표시 정보 |
|------|-----------|
| 1×1 (57×57dp~) | 오늘 방문 횟수 + + 버튼 |
| 2×1 (120×57dp~) | 오늘 방문 횟수 + 마지막 시각 + + 버튼 |
| 2×2 (120×120dp~) | 오늘 방문 횟수 + 마지막 시각 + 마지막 기분 + 오늘 기분 도트 + + 버튼 |

**구현 파일 (Android):**
- `widget/PooPooWidget.kt` — Glance `SizeMode.Responsive`로 3종 레이아웃 분기
- `widget/PooPooWidgetReceiver.kt` — 1×1 위젯 `HomeWidgetGlanceWidgetReceiver` 확장, 자정 리셋 AlarmManager
- `widget/PooPooWidgetMediumReceiver.kt` — 2×1 위젯 Receiver
- `widget/WidgetDataStore.kt` — `"HomeWidgetPreferences"` SharedPreferences 읽기
- `widget/BootReceiver.kt` — `BOOT_COMPLETED` 수신 시 위젯 갱신 + 알람 재등록
- `res/xml/poopoo_widget_info.xml` — 위젯 메타데이터 (updatePeriodMillis=1800000)

**데이터 흐름:**
```
기록 저장 → HomeWidgetService → home_widget SharedPreferences 저장
         → HomeWidget.updateWidget() → PooPooWidgetReceiver.onUpdate()
         → PooPooWidget.provideGlance() → currentState().preferences 읽기 → UI 갱신
```

---

## 테마 색상

| 상수 | 색상 | 용도 |
|------|------|------|
| `AppTheme.moodGood` | `#3DA06C` (맑은 숲 초록) | 좋음 |
| `AppTheme.moodOkay` | `#CC7D30` (따뜻한 앰버) | 보통 |
| `AppTheme.moodBad` | `#C64848` (차분한 로즈 레드) | 나쁨 |
| `AppTheme.moodNone` | `#8CA896` (그레이 그린 뉴트럴) | 다녀옴 + 기분 미입력 |
| `AppTheme.moodNotVisited` | `#C4CCCA` (옅은 쿨 그레이) | 안 감 (`visited=false`) |

Material 3 기반 수동 `ColorScheme` 구성 (라이트 Primary `#2D6A4F` / 다크 `#74C19A`). 테마 모드는 `shared_preferences`에 저장.

---

## 한국어 지역화

UI 텍스트와 날짜 포맷은 모두 `ko_KR`. `flutter_localizations` + `GlobalCupertinoLocalizations` 적용.
