# 작업 기록

---

### [2026-06-09] UI 개선 및 버그 수정 다수
- **변경 사항:**
  - **Android 홈 화면 위젯**
    - 2×1 위젯 텍스트 중앙 정렬 적용
    - 양쪽 가로 패딩 12dp → 20dp 확대
    - "오늘" 문구 제거 (위젯 자체가 오늘 데이터만 표시하므로 중복)
    - `PooPooWidget`에 `HomeWidgetGlanceStateDefinition` 적용 — 기록 저장 후 위젯 데이터가 갱신되지 않던 버그 수정 (stateDefinition 미설정으로 `HomeWidgetGlanceWidgetReceiver.onUpdate`의 상태 갱신 로직이 건너뛰어졌던 문제)
    - `HomeWidgetService`에서 존재하지 않는 `_receiverLarge` 참조 제거
  - **색상 구분 — 안 감 / 다녀옴**
    - `AppTheme.moodNotVisited(#C4CCCA)` 신규 색상 추가
    - `EntryX.moodColor`: `visited=false`이면 `moodNotVisited`, `visited=true+mood=null`이면 `moodNone`으로 분리
    - `MoodIndicator._dotColor`, `MoodFacePainter._FaceColors.forMood` 동일하게 분기 처리 — 도트·얼굴 아이콘 모드 모두 적용
  - **온보딩 가이드 화면**
    - 1페이지 "화장실에 다녀왔어요" 스위치를 기록 화면과 동일한 활성화 색상으로 표시 (`IgnorePointer` + enabled 상태)
  - **더보기 화면**
    - "정보" 섹션에 공지사항 항목 추가 — Remote Config 공지가 있을 때만 노출, 탭 시 확인 버튼만 있는 일반 팝업 표시
    - 앱 버전 항목에 업데이트 인디케이터 추가 — 최신 버전 아닐 시 "업데이트" 칩 표시 및 탭 시 스토어 이동
    - `appConfigProvider` 신규 추가 — Remote Config 결과를 AppShell·MoreScreen이 공유해 중복 fetch 방지
  - **통계 화면**
    - "기분 분포" 섹션 항상 표시 — 기분 입력 기록이 없을 때 차트 대신 안내 카드 표시
    - 피크 타임 다중 칩 배경색 하드코딩(`#E6F1FB`) → `cs.primaryContainer` 교체 (다크모드 미적용 버그 수정)
  - **타임라인 화면**
    - 신규 기록 화면 진입 시 이전 폼 상태(기분·날짜·시간) 유지되던 버그 수정 — `recordFormProvider(null)` invalidate 추가
  - **QA 체크리스트** (`docs/qa_checklist.md`) 현재 코드 기준으로 업데이트
    - 위젯 2×2 항목 제거, "오늘" 문구 반영, 전면 광고 횟수 정정 (10회 최초 + 이후 7회마다)
- **영향받는 파일:**
  - 수정 - `android/.../PooPooWidget.kt` — stateDefinition, currentState() 적용, "오늘" 제거, 중앙 정렬, 패딩 조정
  - 수정 - `android/.../PooPooWidgetMediumReceiver.kt` — 주석 정리
  - 수정 - `lib/core/widget/home_widget_service.dart` — _receiverLarge 제거
  - 수정 - `lib/shared/theme/app_theme.dart` — moodNotVisited 색상 추가, moodNone 주석 수정
  - 수정 - `lib/core/extensions/entry_ext.dart` — moodColor 분기 수정
  - 수정 - `lib/shared/widgets/mood_indicator.dart` — _dotColor 분기 수정
  - 수정 - `lib/shared/widgets/mood_face_painter.dart` — forMood() 분기 수정
  - 수정 - `lib/features/onboarding/onboarding_screen.dart` — 스위치 색상 수정
  - 수정 - `lib/features/more/more_screen.dart` — 공지사항 타일·업데이트 인디케이터 추가
  - 수정 - `lib/core/remote_config/remote_config_service.dart` — appConfigProvider 추가
  - 수정 - `lib/features/shell/app_shell.dart` — appConfigProvider 사용
  - 수정 - `lib/features/stats/stats_screen.dart` — 기분 분포 빈 상태 카드 추가
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — 피크 칩 배경색 테마 적용
  - 수정 - `lib/features/timeline/timeline_screen.dart` — 신규 기록 시 폼 초기화
  - 수정 - `docs/qa_checklist.md` — 현행화
- **특이사항 및 남은 작업:**
  - 위젯 업데이트 버그 수정은 빌드 후 실제 기기 검증 필요
  - iOS 스토어 URL (`_kIosStoreUrl`)은 App Store 등록 후 실제 ID로 교체 필요

---

### [2026-06-04] 빠진 단위 테스트 3종 추가
- **변경 사항:**
    - timeline_provider.dart `_toGroups` 순수 로직을 `@visibleForTesting static buildGroupsForTest()`로 노출, 13개 순수 단위 테스트 신규 작성
    - app_database_test.dart에 `insertEntry` / `updateEntry` / `deleteEntry` / `getEntriesInRange` 경계값(exclusive end) 테스트 15개 추가
    - stats_screen_test.dart에 `_PeakTimeSummary` 데이터 부족 분기 (`maxCount==1 && peakHours.length>1`) 위젯 테스트 3개 추가
    - 총 62개 테스트 ALL PASSED
- **영향받는 파일:**
    - 수정 - lib/features/timeline/timeline_provider.dart — `_toGroups` static 전환, `buildGroupsForTest` 공개 메서드 추가
    - 신규 생성 - test/features/timeline/timeline_provider_test.dart — 필터·그룹화 순수 단위 테스트 (13개)
    - 수정 - test/core/database/app_database_test.dart — CRUD 및 범위 경계값 테스트 추가 (15개)
    - 수정 - test/features/stats/stats_screen_test.dart — _PeakTimeSummary 위젯 분기 테스트 추가 (3개)
- **특이사항 및 남은 작업:**
    - 없음

---

### [2026-06-03] 홈화면 위젯 추가 불가 버그 수정
- **변경 사항:**
    - 매니페스트에 선언되어 있으나 클래스 파일이 없던 `PooPooWidgetMediumReceiver`, `PooPooWidgetLargeReceiver` 생성
    - 이로 인해 홈화면 위젯 갤러리에서 2×1, 2×2 위젯 추가 시 발생하던 "위젯을 추가할 수 없습니다" 오류 해결
- **영향받는 파일:**
    - 신규 생성 - android/.../widget/PooPooWidgetMediumReceiver.kt — 2×1 위젯 리시버
    - 신규 생성 - android/.../widget/PooPooWidgetLargeReceiver.kt — 2×2 위젯 리시버
- **특이사항 및 남은 작업:**
    - 세 리시버 모두 동일한 `PooPooWidget`(SizeMode.Responsive) 사용, 컨테이너 크기에 따라 레이아웃 자동 전환

---

### [2026-06-03] 인앱결제 성공 팝업 변경 + 빌드 캐시 정리
- **변경 사항:**
    - 더보기 화면에서 광고 제거 인앱결제(구매 또는 복원) 성공 시 스낵바 대신 AlertDialog 팝업으로 결과 표시
    - `flutter clean` 으로 빌드 캐시 정리 (AAPT 리소스 링크 오류 해결)
- **영향받는 파일:**
    - 수정 - lib/features/more/more_screen.dart — `listenManual` 성공 분기에 `_showPurchaseSuccessDialog()` 호출 추가, `_showPurchaseSuccessDialog` 메서드 신규 추가
- **특이사항 및 남은 작업:**
    - 컴파일 오류(string/app_name, xml/poopoo_widget_info_medium 등)는 stale 빌드 캐시 문제였으며 `flutter clean && flutter pub get`으로 해결됨

---

### [2026-06-03] 캘린더 날짜 선택 동작 통일 / 통계 피크 타임 데이터 부족 케이스 처리

- **변경 사항:**
  - 캘린더 날짜 선택: 기록 없는 날 탭 시 기록 입력 화면 자동 열림 → 하단 패널 표시로 통일
  - 캘린더 날짜 선택: 기록 없는 날 하단 패널에 "저장된 기록이 없어요 / 이 날의 기록을 추가해보세요" 빈 상태 UI 표시 (기록 추가는 FAB 사용)
  - 통계 피크 타임: `maxCount == 1 && peakHours.length > 1` 조건일 때 "아직 패턴을 파악하기 어려워요." 메시지 표시 (피크 시간 숫자/칩 숨김)
- **영향받는 파일:**
  - 수정 - `lib/features/calendar/calendar_screen.dart` — `onDaySelected` 자동 화면 전환 제거, 항상 패널 표시, `_EmptyDayState` 위젯 추가
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — `_PeakTimeSummary` 데이터 부족 분기 추가

---

### [2026-06-03] 업데이트·공지 팝업 개선 및 SharedPreferences 키 누적 방지

- **변경 사항:**
  - 업데이트 팝업: Remote Config `release_notes` 값 수신 후 팝업 본문에 표시
  - 업데이트 팝업: 선택적 업데이트 '취소' → '나중에' 텍스트 변경
  - 업데이트 팝업: 선택적·강제 업데이트 모두 외부 탭·뒤로가기 차단 (`PopScope(canPop: false)` + `barrierDismissible: false`)
  - 공지 팝업: 외부 탭·뒤로가기 차단 (`PopScope(canPop: false)` 추가, 외부 탭은 기존 차단 유지)
  - 공지 노출 횟수: `notice_show_count_{id}` (공지마다 키 추가) → 고정 키 2개 (`notice_show_count`, `notice_show_count_id`)로 변경
  - 업데이트 노출 횟수: `update_show_count_{platform}_{version}` → 고정 키 2개 (`update_show_count`, `update_show_count_id`)로 변경
  - ID/버전이 바뀌면 기준 ID 불일치로 카운트를 0으로 간주(논리적 리셋) — 키 삭제 없이 누적 방지
- **영향받는 파일:**
  - 수정 - `lib/core/remote_config/app_config.dart` — `UpdateConfig`에 `releaseNotes` 필드 추가
  - 수정 - `lib/features/update/force_update_dialog.dart` — `releaseNotes` 표시, '나중에' 텍스트, 뒤로가기 차단
  - 수정 - `lib/features/notice/notice_dialog.dart` — `PopScope(canPop: false)` 추가
  - 수정 - `lib/features/shell/app_shell.dart` — `barrierDismissible: false` 고정, `releaseNotes` 전달
  - 수정 - `lib/core/notice/notice.dart` — 접두사 상수 2개 제거, 고정 키 상수 4개로 교체
  - 수정 - `docs/architecture_analysis.md` — SharedPreferences 키 관리 방법 상세화

### [2026-06-03] CSV 가져오기·내보내기 개선 / 통계 히트맵 터치 개선 / 앱 이름 한글화

- **변경 사항:**
  - CSV 가져오기: `FileType.custom` → `FileType.any`로 변경 — Google Drive 등 외부 저장소에서 MIME 타입 불일치로 파일이 표시 안 되는 버그 수정
  - CSV 가져오기: `.txt` 허용 제거, `.csv`만 허용 (내보내기가 CSV 전용이므로)
  - CSV 내보내기: `share_plus` 공유 시트 방식 → `FilePicker.saveFile()`로 변경 — 사용자가 내 파일 앱에서 저장 위치를 직접 지정
  - CSV 내보내기 파일명: 타임스탬프(ms) → 날짜 기반 `poopoolog_YYYYMMDD.csv` 형식으로 변경
  - 통계 화면 시간대별 히트맵: 피크 시간 요약 카드 + 그리드 영역 터치 시 "자세히 보기" 바텀시트 표시
  - Android 앱 이름 한글화: `android:label="poopoolog"` → `@string/app_name`("푸푸로그") 으로 변경
- **영향받는 파일:**
  - 수정 - `lib/features/more/more_screen.dart` — 가져오기 FileType·확장자 검증 수정, 내보내기 saveFile 방식으로 전환
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — 히트맵 그리드 영역 GestureDetector 추가
  - 신규 - `android/app/src/main/res/values/strings.xml` — 앱 이름 문자열 리소스
  - 수정 - `android/app/src/main/AndroidManifest.xml` — android:label을 strings.xml 참조로 변경
- **특이사항 및 남은 작업:**
  - `share_plus`, `path_provider`, `dart:io` import 제거 완료 (`flutter analyze` 0 이슈 확인)

### [2026-06-03] Android 홈 화면 위젯 다중 사이즈 지원 및 표시 내용 개편

- **변경 사항:**
  - 위젯 3종 분리 등록 (1×1 / 2×1 / 2×2) — 홈 화면 위젯 추가 시 피커에서 크기 직접 선택 가능
  - 위젯 표시 내용 전면 개편: 날짜 레이블("오늘") 추가, 기분 레이블 제거 → 색상 도트로 통일, 오늘 방문 없으면 "안 감"/"안 다녀왔어요" 표시
  - 2×2 위젯: 마지막 기록 1건 → 오늘 전체 기록(시간 + 기분 도트) 목록으로 변경 (최대 4건)
  - SharedPreferences 데이터 구조 변경: `lastMoodLabel`, `todayDots`, `dateLabel` 제거 → `today_records`("HH:mm|#COLOR,..." 형식) 추가
  - 기록 저장·삭제 시 3개 receiver 모두 갱신하도록 `HomeWidgetService.update()` 수정
- **영향받는 파일:**
  - 신규 - `android/.../widget/PooPooWidgetMediumReceiver.kt` — 2×1 위젯 receiver
  - 신규 - `android/.../widget/PooPooWidgetLargeReceiver.kt` — 2×2 위젯 receiver
  - 신규 - `android/app/src/main/res/xml/poopoo_widget_info_medium.xml` — 2×1 기본 크기 설정
  - 신규 - `android/app/src/main/res/xml/poopoo_widget_info_large.xml` — 2×2 기본 크기 설정
  - 수정 - `android/.../widget/PooPooWidget.kt` — 3개 레이아웃 전면 재설계
  - 수정 - `android/.../widget/WidgetDataStore.kt` — `todayRecords: List<Pair<String,String>>` 구조로 변경
  - 수정 - `android/app/src/main/AndroidManifest.xml` — 3개 receiver 등록 (라벨: 1x1/2x1/2x2)
  - 수정 - `lib/core/widget/home_widget_service.dart` — `todayRecords` 저장, 3개 receiver 갱신
  - 수정 - `android/.../widget/WidgetDataStoreTest.kt` — 신규 데이터 구조 기준 테스트로 전면 교체

---

### [2026-06-02] 버그 수정 및 기능 개선

- **변경 사항:**
  - 메모 삭제 후 저장 시 반영 안 되는 버그 수정: `RecordFormState.copyWith`의 `memo` 파라미터를 sentinel 패턴(`Object? memo = _s`)으로 변경, `null` 명시 전달 시 기존 값을 유지하지 않고 `null`로 저장
  - Android 홈 화면 위젯 색상 수정: `+` 버튼 색상을 앱 FAB과 동일한 `#2D6A4F`로, 기분 도트 fallback 색상을 앱 `moodNone`과 동일한 `#8CA896`으로 변경
  - 기록 입력·수정 화면 메모 전체 삭제 버튼 추가: 메모 입력 필드에 텍스트가 있을 때 `suffixIcon`으로 X 버튼 표시, 탭 시 메모 즉시 초기화
- **영향받는 파일:**
  - 수정 - `lib/features/record/record_provider.dart` — `copyWith` memo sentinel 패턴 적용
  - 수정 - `lib/features/record/record_screen.dart` — `_MemoField`에 `ValueListenableBuilder` + `suffixIcon` X 버튼 추가
  - 수정 - `android/.../widget/PooPooWidget.kt` — `COLOR_PRIMARY`, `parseColor` fallback 색상 수정
  - 신규 - `test/features/record/record_provider_test.dart` — `copyWith` sentinel 패턴 및 메모 null 저장 단위 테스트

### [2026-06-01] Remote Config JSON `show` 필드 지원 — 팝업 노출 횟수 제어

- **변경 사항:**
  - Remote Config `app_config` JSON 구조 변경 대응: `notice`, `android`, `ios` 각 객체에 `show` 필드 추가
  - `show == 0`: 항상 노출 (기존 동작과 동일)
  - `show >= 1`: 해당 횟수만큼만 노출 후 더 이상 표시하지 않음 (SharedPreferences에 노출 횟수 카운트 저장)
  - 공지사항: 사용자가 "다시 보지 않음" 선택 시 이후 완전히 노출 안 함 (기존 로직 유지)
  - 업데이트 팝업: `force_update == true`이면 `show` 값 무관하게 항상 노출
  - SharedPreferences 키 추가: `notice_show_count_{id}`, `update_show_count_{platform}_{version}`
- **영향받는 파일:**
  - 수정 - `lib/core/remote_config/app_config.dart` — `NoticeConfig`, `UpdateConfig`에 `show` 필드 추가 및 JSON 파싱
  - 수정 - `lib/core/notice/notice.dart` — `kNoticeShowCountKeyPrefix`, `kUpdateShowCountKeyPrefix` 상수 추가
  - 수정 - `lib/features/shell/app_shell.dart` — `_checkAndShowNotice()`, `_checkForceUpdate()`에 show 횟수 제어 로직 적용
  - 수정 - `test/core/remote_config/app_config_test.dart` — `show` 파싱·기본값·fallback 테스트 추가
  - 수정 - `test/features/update/update_test.dart` — `UpdateConfig.show` 기본값 테스트 추가
- **특이사항 및 남은 작업:**
  - 테스트 52개 전체 통과 확인

### [2026-05-27] 빌드 수정·버그 수정·전체 코드 리팩토링

- **변경 사항:**
  - Android 릴리즈 빌드 오류 수정: `keystoreProperties` 미정의 참조, Kotlin DSL 프로퍼티명(`isMinifyEnabled`, `isShrinkResources`), `storeFile` 경로 이중 중첩 수정
  - 테스트 데이터 생성 로직 수정: 시간 범위 06:00~23:59 → 00:00~23:59, mood를 `visited == true`인 경우에만 0~2 랜덤 설정 (기존: visited 관계없이 설정)
  - 통계 시간대별 방문 바텀시트: 최소 높이 35% → 60%로 상향, `useSafeArea: true` 적용으로 OS 내비게이션 바 겹침 해소
  - 코드 전체 리팩토링 (4단계): flutter analyze 0 이슈, 테스트 226개 전체 통과
    - **코어**: `getEntriesForDate()` 내부 구현 `getEntriesInRange()` 위임, `isOutdated()` 를 `UpdateConfig` 인스턴스 메서드로 이전, `Color.value` deprecated API → `.r/.g/.b` float 채널로 교체, 단일-행 if 중괄호 lint 수정
    - **Provider**: `TimelineFilterExt.labelEn()` 미사용 메서드 제거
    - **화면**: `record_screen.dart` 불필요한 zero-padding 제거, `calendar_screen.dart` `_kCalendarFirstMonth` 파일 상수 추출·isPastMonth 조건 단순화
    - **기타**: `AppTheme.moodColor()` 미사용 확장 메서드 제거, `app_shell.dart` `isOutdated()` 호출 인스턴스 메서드로 변경
  - 테스트 코드 동기 수정: `isOutdated()` 호출부를 새 인스턴스 메서드 방식으로 업데이트, `_base` → `base` 로컬 변수명 lint 수정
- **영향받는 파일:**
  - 수정 - `android/app/build.gradle.kts` — keystoreProperties 선언·isMinifyEnabled·isShrinkResources·storeFile 경로 수정
  - 수정 - `lib/features/more/more_screen.dart` — 테스트 데이터 시간 범위, mood null 처리
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — 바텀시트 최소 높이 60%, useSafeArea: true
  - 수정 - `lib/core/database/app_database.dart` — getEntriesForDate() 위임 구현
  - 수정 - `lib/core/remote_config/app_config.dart` — isOutdated() 인스턴스 메서드 이전
  - 수정 - `lib/core/widget/home_widget_service.dart` — Color.value → float channels
  - 수정 - `lib/core/models/mood_display_provider.dart` — curly_braces_in_flow_control_structures lint 수정
  - 수정 - `lib/features/timeline/timeline_provider.dart` — labelEn() 미사용 메서드 제거
  - 수정 - `lib/features/record/record_screen.dart` — zero-padding Padding 래퍼 제거
  - 수정 - `lib/features/calendar/calendar_screen.dart` — 상수 추출, isPastMonth 단순화
  - 수정 - `lib/features/shell/app_shell.dart` — isOutdated() 인스턴스 메서드 호출
  - 수정 - `lib/shared/theme/app_theme.dart` — moodColor() 미사용 확장 제거
  - 수정 - `test/features/update/update_test.dart` — isOutdated() 호출 업데이트
  - 수정 - `test/core/remote_config/app_config_test.dart` — isOutdated() 호출 업데이트
  - 수정 - `test/core/extensions/entry_ext_test.dart` — _base → base 변수명 수정

### [2026-05-26] 광고·IAP·버그 수정 다수
- **변경 사항:**
  - 전면 광고 빈도: 최초 10회 저장 시 첫 노출, 이후 7회마다 1회로 변경 (기존: 횟수 무관 7회마다)
  - 스플래시 화면: `flutter_native_splash` 방식 제거 → Flutter `runApp` 이중 호출 방식으로 교체 (초기화 완료까지 최소 1초 표시)
  - Remote Config 공지: 하드코딩된 `kCurrentNotice` 대신 `fetchAppConfig()` 결과의 `config.notice`를 사용하도록 수정 (fetch 1회로 통합)
  - 캘린더 FAB(+버튼): 날짜 선택 후 누르면 선택한 날짜로 기록 입력 화면이 열리도록 수정 (기존: 항상 오늘)
  - 바텀시트 drag handle 중복: `showDragHandle: false` 누락으로 핸들 2개 표시되던 문제 수정
- **영향받는 파일:**
  - 수정 - `lib/core/ads/ad_service.dart` — `_kFirstAdThreshold = 10`, 빈도 조건 변경
  - 수정 - `lib/main.dart` — 스플래시 `_SplashApp` 먼저 runApp, 초기화 완료 후 실제 앱 교체
  - 수정 - `pubspec.yaml` — `assets/splash/splash.jpg` assets 선언 추가, `flutter_native_splash` dev_dependencies로 복귀
  - 수정 - `lib/features/shell/app_shell.dart` — Remote Config 1회 fetch로 업데이트·공지 모두 처리
  - 수정 - `lib/features/calendar/calendar_screen.dart` — FAB `onPressed`에 `selectedDay` 전달
  - 수정 - `lib/features/more/more_screen.dart` — `showDragHandle: false` 추가
  - 수정 - `lib/features/calendar/widgets/month_picker_sheet.dart` — `showDragHandle: false` 추가

### [2026-05-26] 통계 — 피크 시간대 요약 UI 추가
- **변경 사항:**
  - 시간대별 방문 히트맵 상단에 가장 많이 방문한 시간 요약 카드 추가
  - 단일 피크: 큰 숫자(28sp bold) + "시", 우측 "이 시간에 N회 방문"
  - 2개 동률: 칩 2개 + "·" 구분자, 우측 "각 N회로 동률"
  - 3개 이상 동률: 칩 2개 + "+N" 뱃지, 우측 "N개 시간대 동률"
  - 데이터 없을 때(`maxCount == 0`) 카드 미표시
- **영향받는 파일:**
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — `_PeakTimeSummary`, `_SinglePeak`, `_MultiPeak` 위젯 추가

### [2026-05-26] 타임라인·기록 날짜 범위 하한 고정 및 초기화 후 캘린더 상태 리셋
- **변경 사항:**
  - 타임라인 `loadMore()` 상한을 `2026-01-01`에서 `2026-05-01`로 변경
  - 기록 입력 날짜 피커 하한선을 `2026-05-01`로 고정 (이전: 제한 없음)
  - 데이터 초기화 후 캘린더 탭 진입 시 선택 날짜·포커스 월을 오늘 기준으로 리셋
- **영향받는 파일:**
  - 수정 - `lib/features/timeline/timeline_provider.dart` — `_appStart` 2026-01-01 → 2026-05-01
  - 수정 - `lib/features/record/record_screen.dart` — `CupertinoDatePicker`에 `minimumDate: DateTime(2026, 5)` 추가
  - 수정 - `lib/features/more/more_screen.dart` — `_confirmReset()` 에서 `selectedDayProvider`·`calendarFocusedMonthProvider` 오늘 기준 리셋 추가

### [2026-05-26] 핵심 비즈니스 로직 단위 테스트 추가 (226개 전체 통과)
- **변경 사항:**
  - `StatsResult.fromEntries()` 집계 로직 테스트 추가: 빈 기록, visited 필터, 기분 집계, 시간대 집계, 피크 시간, 방문일 중복 제거 (21개)
  - `AppConfig.fromJsonString()` JSON 파싱 테스트 추가: 정상 파싱, 누락 필드 기본값, `NoticeConfig.isEmpty`, `AppConfig.fallback`, `isOutdated()` (17개)
  - `RecordModel.copyWith()` sentinel 패턴 테스트 추가: no-op, non-nullable 변경, nullable 명시적 null 설정, `==` 연산자, hashCode (12개)
  - `EntryX.moodColor/moodLabel/timeStr`, `MoodLevelX.color/label` 확장 테스트 추가 (18개)
  - `entry_ext_test.dart` 컴파일 오류 수정: `const DateTime` → `final DateTime`
- **영향받는 파일:**
  - 신규 - `test/features/stats/stats_result_test.dart` — StatsResult.fromEntries() 21개 테스트
  - 신규 - `test/core/remote_config/app_config_test.dart` — AppConfig JSON 파싱 17개 테스트
  - 신규 - `test/core/models/record_model_test.dart` — RecordModel copyWith/== 12개 테스트
  - 신규 - `test/core/extensions/entry_ext_test.dart` — EntryX/MoodLevelX 확장 18개 테스트
- **특이사항 및 남은 작업:**
  - flutter test 전체 226개 ALL PASSED 확인 완료

### [2026-05-25] 테스트 커버리지 보강 및 기존 테스트 수정
- **변경 사항:**
  - 온보딩: `건너뛰기`·`시작하기` 탭 후 `kOnboardingSeenKey = true` 저장 검증 테스트 추가
  - 기록: X 버튼 탭 → 저장 없이 화면 닫힘 테스트 추가
  - 캘린더: 미래 날짜 선택 → DayPanel 미표시 테스트 추가
  - 더보기: 다크모드·기분 표시·요일 바텀시트 열림 / 앱 가이드 → 온보딩 화면 진입 테스트 추가
  - 기존 온보딩 페이지 전환 테스트: 두 번째 슬라이드 제목 `'색상으로 기분 흐름 파악'` → `'기분 흐름을 한눈에'` 수정
  - 기존 캘린더 테스트: firstDay 변경(2026-05-01) 으로 무효화된 과거 달 참조를 다음 달 기준으로 수정
  - 온보딩 슬라이드 전환 테스트: 실기기 크기(390×844) 가상 윈도우 적용으로 PieChart 오버플로우 해결
- **영향받는 파일:**
  - 수정 - `test/features/onboarding/onboarding_screen_test.dart` — 슬라이드 제목 픽스, 화면 크기 설정, prefs 저장 테스트 추가
  - 수정 - `test/features/record/record_screen_test.dart` — X 버튼(닫기) 테스트 추가
  - 수정 - `test/features/calendar/calendar_screen_test.dart` — firstDay 대응 날짜 수정, 미래 날짜 테스트 추가
  - 수정 - `test/features/more/more_screen_test.dart` — 바텀시트·앱 가이드 테스트 추가
- **특이사항 및 남은 작업:**
  - `건너뛰기`·`시작하기` prefs 저장 테스트는 AppShell Firebase 초기화 예외를 `tester.takeException()`으로 무시 처리
  - 타임라인 RefreshIndicator provider 무효화 테스트는 안정성 문제로 미포함

### [2026-05-25] 온보딩 UI 개선, 캘린더 날짜 범위 변경, 스플래시 교체, 버그 수정
- **변경 사항:**
  - 온보딩 1번 슬라이드 기분 동그라미 크기 14px → 6px (실제 `MoodIndicator._dotDiameter = 6.0`과 동일)
  - 온보딩 3번 슬라이드(통계) 기분 분포 도넛 차트 + 범례 추가 (샘플: 좋음 55% / 보통 32% / 나쁨 14%)
  - 온보딩 2번 슬라이드(캘린더) 시작 요일 월요일 → 일요일 변경
  - 캘린더 최소 날짜 2025-12-01 → 2026-05-01 변경
  - 캘린더 최대 날짜 이번 달 마지막 날 → 다음 달 마지막 날(오늘 달 +1)로 변경
  - 스플래시 화면 아이콘 중앙 배치 → 전체 배경 이미지(`assets/splash/splash.jpg`)로 교체
  - 통계 화면 첫 기록 저장 후 캘린더·타임라인 미갱신 버그 수정
  - 앱 버전 `1.0.0+1` → `0.1.0+1`
- **영향받는 파일:**
  - 수정 - lib/features/onboarding/onboarding_screen.dart — 기분 동그라미 크기, 기분 분포 차트 추가, 캘린더 요일 변경
  - 수정 - lib/features/calendar/calendar_screen.dart — 최소/최대 날짜 변경
  - 수정 - lib/features/stats/stats_screen.dart — `monthlyEntriesProvider`, `timelineProvider` invalidate 추가, `timelineProvider` import 추가
  - 수정 - pubspec.yaml — `flutter_native_splash` 설정 변경(background_image), 버전 변경
  - 신규 생성 - assets/splash/splash.jpg — 스플래시 전체 배경 이미지
- **특이사항 및 남은 작업:**
  - 스플래시는 `dart run flutter_native_splash:create`로 Android/iOS 네이티브 파일에 반영 완료

### [2026-05-23] Firebase Remote Config 기반 강제 업데이트 기능 추가
- **변경 사항:**
  - Firebase Remote Config `app_config` JSON 파라미터 구조 확정 (`notice` + `update` 통합)
  - 앱 시작 시 Remote Config fetch → 현재 버전과 `latest_version` 비교 → `force_update: true`이면 닫기 불가 팝업 표시
  - 강제 업데이트 팝업: `barrierDismissible: false` + `PopScope(canPop: false)`로 완전 차단, 확인 버튼 → 플랫폼별 스토어 이동
  - Remote Config fetch 실패 시 `AppConfig.fallback`으로 폴백 처리 (앱 정상 동작 보장)
  - 강제 업데이트 발생 시 위젯 액션·공지 팝업 등 이후 로직 중단
  - `firebase_core: ^3.13.1`, `firebase_remote_config: ^5.4.4` 의존성 추가
- **영향받는 파일:**
  - 신규 생성 - lib/core/remote_config/app_config.dart — AppConfig·NoticeConfig·UpdateConfig 모델, `isOutdated()` 버전 비교
  - 신규 생성 - lib/core/remote_config/remote_config_service.dart — Remote Config fetch 서비스
  - 신규 생성 - lib/features/update/force_update_dialog.dart — 강제 업데이트 팝업 (닫기 불가)
  - 수정 - lib/features/shell/app_shell.dart — `_checkForceUpdate()` 추가 및 initState 연동
  - 수정 - lib/main.dart — `Firebase.initializeApp()` 추가
  - 수정 - pubspec.yaml — firebase_core, firebase_remote_config 추가
- **특이사항 및 남은 작업:**
  - Firebase 콘솔에서 앱 등록 후 `google-services.json`(Android), `GoogleService-Info.plist`(iOS) 추가 필요
  - `force_update_dialog.dart`의 `_kIosStoreUrl` 상수에 App Store Connect 실제 ID 교체 필요
  - 버전 비교: `1.0.0` 형식 3자리 (major.minor.patch), 현재 < 최신이면 업데이트 필요로 판단

### [2026-05-23] 시간대별 방문 자세히 보기 UI 개선
- **변경 사항:**
  - 커스텀 드래그 핸들 제거 (시스템 핸들도 미사용 — 핸들 없음)
  - 시트 크기 고정 (min = max = initial, 데이터 기반 동적 계산)
  - 바 높이 22 → 16px, 간격 7 → 4px, 그룹 레이블 패딩 축소, 텍스트 11px 통일
  - 시간 표시 간소화: '오전 8시' → '8시' (24시간제 숫자만)
  - 레이블 폭 52 → 32px로 축소해 바 영역 확대
- **영향받는 파일:**
  - 수정 - lib/features/stats/widgets/stat_heat_map_grid.dart

### [2026-05-23] 온보딩 화면 UI 개선 및 공지사항 팝업 추가
- **변경 사항:**
  - 온보딩 3장 슬라이드에 각 기능별 실제 UI 모형(미리보기 위젯) 추가 — 기록 입력 카드, 미니 캘린더 그리드+도트, 통계 요약+히트맵
  - 앱 시작 시 공지사항 팝업 표시 기능 추가 — '확인' 닫기 / '다시 보지 않음' 선택 시 해당 공지 ID를 SharedPreferences에 저장해 재표시 차단
  - 공지 데이터는 `lib/core/notice/notice.dart`에 상수로 관리, 추후 Firebase Remote Config 연동 예정
- **영향받는 파일:**
  - 수정 - lib/features/onboarding/onboarding_screen.dart — 슬라이드별 미리보기 위젯(`_RecordPreview`, `_CalendarPreview`, `_StatsPreview`) 추가
  - 신규 생성 - lib/core/notice/notice.dart — 공지 모델(`Notice`) 및 현재 공지 상수(`kCurrentNotice`)
  - 신규 생성 - lib/features/notice/notice_dialog.dart — 공지 팝업 다이얼로그
  - 수정 - lib/features/shell/app_shell.dart — `_checkAndShowNotice()` 메서드 추가 및 initState 연동
- **특이사항 및 남은 작업:**
  - 공지 내용(title/message) 및 id는 `lib/core/notice/notice.dart`의 `kCurrentNotice` 상수를 직접 수정해 변경
  - id가 빈 문자열이면 공지 없음으로 처리됨

### [2026-05-23] 앱 최초 실행 온보딩 가이드 추가
- **변경 사항:**
  - 앱 최초 실행 시 3장 슬라이드 온보딩 화면 표시 (기록하기·캘린더&타임라인·통계)
  - "건너뛰기" 버튼으로 즉시 건너뛸 수 있고, "시작하기" 완료 시 SharedPreferences에 완료 기록
  - 더보기 > 지원 섹션에 "앱 가이드" 항목 추가 — 언제든 다시 볼 수 있음 (X 버튼으로 닫기)
- **영향받는 파일:**
  - 신규 - lib/features/onboarding/onboarding_screen.dart — 온보딩 화면 및 슬라이드 콘텐츠
  - 수정 - lib/main.dart — SharedPreferences에서 온보딩 완료 여부 로드, 조건부 홈 화면 분기
  - 수정 - lib/features/more/more_screen.dart — "앱 가이드" 항목 추가 (지원 섹션)
  - 신규 - test/features/onboarding/onboarding_screen_test.dart — 온보딩 위젯 테스트 9개
- **특이사항 및 남은 작업:**
  - All tests passed (115개)
  - 더보기에서 열 때는 prefs 저장 없이 X 버튼으로 닫기만 함

### [2026-05-23] 시간대별 방문 히트맵 색상 파랑 → 초록 계열로 변경
- **변경 사항:**
  - 히트맵 4단계 색상을 앱 테마(초록 계열)에 맞게 변경
    - Heat1(≤25%): `#E6F1FB` → `#D4EDDF` (연한 민트 그린)
    - Heat2(≤50%): `#85B7EB` → `#7DC4A0` (라이트 그린)
    - Heat3(≤75%): `#378ADD` → `#3DA06C` (AppTheme.moodGood)
    - Heat4(≤100%): `#185FA5` → `#1B5E3A` (다크 포레스트 그린)
  - "최다" 뱃지 배경·텍스트 색상도 동일 상수 참조로 자동 반영
- **영향받는 파일:**
  - 수정 - lib/features/stats/widgets/stat_heat_map_grid.dart — 히트맵 색상 상수 변경
  - 수정 - test/features/stats/stats_screen_test.dart — heatColor 단위 테스트 색상값 업데이트
- **특이사항 및 남은 작업:**
  - All tests passed (106개)

### [2026-05-23] 전체 파일 리팩토링 및 파일 상단 주석 추가
- **변경 사항:**
  - 모든 Dart 파일 상단에 파일 역할·주요 기능 설명 주석 추가 (22개 파일)
  - `calendar_screen.dart` — `isBeforeEarliest` 분기의 `!` 및 `as` 불필요 캐스트 제거 (Dart 흐름 분석 활용)
  - `record_screen.dart` — `MoodLevel.values`를 `const`로 변경
  - `timeline_provider.dart` — `loadMore` 로그 메시지 명확화
  - `pubspec.yaml` — `url_launcher_platform_interface: any` dev_dependencies 추가 (테스트 직접 의존성)
  - `test/widget_test.dart` — 앱 구조와 맞지 않는 카운터 스모크 테스트 → AppTheme 생성 확인 테스트로 교체
  - `test/core/widget/home_widget_service_test.dart` — 색상 상수 업데이트 (moodGood #3DA06C, moodOkay #CC7D30, moodBad #C64848, moodNone #8CA896)
  - `test/features/more/more_screen_test.dart` — startWeekdaySundayProvider 기본값(true=일요일) 반영
  - `test/features/record/record_screen_test.dart` — 지역 함수 언더스코어 접두사 제거 (`_insertAndFetch` → `insertAndFetch`)
  - `CLAUDE.md` — 테마 색상 표 업데이트 (실제 AppTheme 값으로 수정)
- **영향받는 파일:**
  - 수정 - lib/ 전 Dart 파일 (파일 상단 주석)
  - 수정 - lib/features/calendar/calendar_screen.dart — 불필요 캐스트 제거
  - 수정 - lib/features/record/record_screen.dart — const 추가
  - 수정 - pubspec.yaml — dev_dependencies 추가
  - 수정 - test/ 4개 파일 — 색상·기본값 업데이트 및 스모크 테스트 개선
- **특이사항 및 남은 작업:**
  - All tests passed (106개)
  - flutter analyze No issues found

### [2026-05-23] UI 코드 리팩토링
- **변경 사항:**
  - `stat_heat_map_grid.dart` — 구식 주석 수정 ("8×3" → "6×4", 그룹명 "오전/오후/저녁/밤" → "새벽/아침/오후/저녁"). 반복 범례 박스 Container를 `_legendBox()` 정적 헬퍼로 추출 (12줄 → 2줄)
  - `stats_screen.dart` — 단일 사용 `_ChartTitle` 위젯 인라인 처리 후 클래스 제거
  - `more_screen.dart` — `_DragHandle` 색상 `Colors.grey[300]` → `cs.outlineVariant` (ColorScheme 일관성 확보)
  - `calendar_screen.dart` — `_BeforeEarliestState` 내 `Theme.of(context).textTheme` → `context.tt` 확장으로 통일
- **영향받는 파일:**
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart`
  - 수정 - `lib/features/stats/stats_screen.dart`
  - 수정 - `lib/features/more/more_screen.dart`
  - 수정 - `lib/features/calendar/calendar_screen.dart`

### [2026-05-23] UI 버그 수정
- **변경 사항:**
  - 통계 화면 "시간대별 방문" 타이틀 중복 제거 — `stats_screen.dart`에 남아있던 `_ChartTitle` 삭제 (`StatHeatMapGrid` 내부 헤더와 중복)
  - 타임라인 날짜 헤더 오늘 건수 배지 텍스트 색상 수정 — `cs.onPrimaryContainer` → `cs.onPrimary` (primary 배경 위에서 안 보이던 문제 해결)
- **영향받는 파일:**
  - 수정 - `lib/features/stats/stats_screen.dart`
  - 수정 - `lib/features/timeline/widgets/date_header.dart`

### [2026-05-23] CSV 가져오기 Upsert 방식으로 개선
- **변경 사항:**
  - 가져오기 전 확인 다이얼로그 표시 ("동일 시간 기록 덮어씀, 기존 기록 삭제 없음" 안내)
  - `db.insertEntry()` → `db.upsertEntryByTime()` 교체
    - 동일 `recordedAt` 기록 존재 → 해당 행 업데이트 (중복 삽입 없음)
    - 없으면 새 행 삽입
  - 헤더 컬럼명 기반 파싱으로 전환 (위치 인덱스 → `colIndex[name]`)
    - 앱 버전업으로 CSV에 컬럼이 추가·누락돼도 null/기본값으로 처리
    - `int.parse` → `int.tryParse` (mood 파싱 실패 시 null 반환)
  - UTF-8 디코딩 실패 시 명시적 오류 메시지 표시 (기존: 예외 전파)
  - 빈 줄 사전 제거 후 파싱
- **영향받는 파일:**
  - 수정 - `lib/core/database/app_database.dart` — `upsertEntryByTime()` 추가
  - 수정 - `lib/features/more/more_screen.dart` — `_importCsv()` 전면 개선
  - 수정 - `test/core/database/app_database_test.dart` — upsert 단위 테스트 4개 추가

### [2026-05-23] 통계 화면 UI 크기 조정
- **변경 사항:**
  - **히트맵 그리드 배열 변경**: 8×3 → 6×4 (4줄 표시)
  - **히트맵 헤더 재구성**: "시간대별 방문" 타이틀 + 범례 + "자세히 보기 ↑" 버튼을 한 행으로 통합
    - `stats_screen.dart`에서 별도 `_ChartTitle` 제거, `StatHeatMapGrid` 내부에서 헤더 렌더링
  - **히트맵 셀 크기 축소**: `childAspectRatio` 1.1 → 1.6, 셀 간격 5 → 4px
  - **기분 분포 도넛 차트 크기 축소**: 높이 150 → 100, 섹션 반지름 48 → 36, 중앙 공간 반지름 20 → 14
- **영향받는 파일:**
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart`
  - 수정 - `lib/features/stats/stats_screen.dart`

### [2026-05-23] 통계 시간대별 방문 히트맵 UI 개선
- **변경 사항:**
  - `stat_heat_map_grid.dart` 완전 재작성
    - 기존: 6열 격자, 녹색 계열, 스낵바 상세
    - 신규: 8×3 블루 계열 격자 + `DraggableScrollableSheet` 바 차트 상세
  - 히트맵 색상 4단계 블루 계열 (`_kHeat1`~`_kHeat4`) — 비율 기반
  - 격자(24칸)와 바 차트에서 `StatHeatMapGrid.heatColor()` 공유 정적 메서드로 일관성 유지
  - 최다 방문 시간대 셀에 primary 테두리 강조 표시
  - 하단 "시간대 자세히 보기 ↑" TextButton + 좌측 범례(적음→많음) 추가
  - `_HourDetailSheet`: 오전/오후/저녁/밤 그룹별 수평 바 차트, 기록 있는 시간대만 표시, "최다" 뱃지
  - 수평 바: `LayoutBuilder` + `Stack` 두 Container(배경 + 색상) 구조
- **영향받는 파일:**
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — 전체 재작성
- **특이사항 및 남은 작업:**
  - Dart 3 Record 타입 구조분해 (`for (final (label, hours) in _kGroups)`) 사용

### [2026-05-22] 최초 사용자 빈 상태(Empty State) UI 구현
- **변경 사항:**
  - **타임라인** — `NewUserEmptyState` 대신 `_TimelineNewUserEmptyState` 커스텀 위젯 추가
    - 🌱 이모지 + "아직 기록이 없어요" 타이틀 + 서브텍스트
    - "+ 첫 기록 남기기" FilledButton → 기록 입력 화면 바로 push
  - **통계** — `NewUserEmptyState` 대신 `_StatsGhostEmptyState` Ghost UI 구현
    - 더미 데이터(`_ghostStats`)를 주입한 `_StatsBody`를 `Opacity(0.22)` + `IgnorePointer`로 흐릿하게 표시
    - 중앙에 "🔒 기록하면 통계가 열려요" 배지 + "+ 첫 기록 남기기" 버튼 오버레이
    - CTA 버튼 → `RecordScreen` push 후 `statsResultProvider` / `earliestEntryDateProvider` invalidate
- **영향받는 파일:**
  - 수정 - `lib/features/timeline/timeline_screen.dart` — 빈 상태 분기 교체, `_TimelineNewUserEmptyState` 추가
  - 수정 - `lib/features/stats/stats_screen.dart` — 빈 상태 분기 교체, `_StatsGhostEmptyState` + `_ghostStats` 추가
- **특이사항 및 남은 작업:**
  - `NewUserEmptyState` 공유 위젯은 삭제하지 않음 (다른 경로에서 재사용 가능성 유지)

### [2026-05-22] fontSize 하드코딩 → TextTheme named style 교체
- **변경 사항:**
  - 앱 전체 12개 파일에서 `TextStyle(fontSize: N, ...)` 하드코딩을 `context.tt.bodySmall` 등 TextTheme named style + `copyWith()`으로 교체
  - 교체 매핑: fontSize 11→labelSmall, 12→bodySmall/labelMedium, 13→titleSmall, 14→bodyMedium/labelLarge, 15→titleMedium, 16→bodyLarge (히트맵 내부 fontSize 10·20은 유지)
  - `entry_card.dart`에 `app_theme.dart` import 추가 (`context.tt` 확장 사용을 위해)
  - `more_screen.dart`에 `app_theme.dart` import 추가
- **영향받는 파일:**
  - 수정 - `lib/shared/widgets/entry_card.dart`
  - 수정 - `lib/shared/widgets/new_user_empty_state.dart`
  - 수정 - `lib/features/timeline/widgets/date_header.dart`
  - 수정 - `lib/features/timeline/widgets/filter_chip_row.dart`
  - 수정 - `lib/features/timeline/timeline_screen.dart`
  - 수정 - `lib/features/stats/widgets/summary_card.dart`
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart`
  - 수정 - `lib/features/stats/stats_screen.dart`
  - 수정 - `lib/features/calendar/calendar_screen.dart`
  - 수정 - `lib/features/calendar/widgets/month_picker_sheet.dart`
  - 수정 - `lib/features/more/more_screen.dart`
  - 수정 - `lib/features/record/record_screen.dart`
- **특이사항 및 남은 작업:**
  - 버튼 자식 Text(`저장`, `삭제`, `지금`)의 스타일은 button foregroundColor 상속을 보존하기 위해 교체 제외
  - TextField.style (입력 텍스트) 및 hintStyle Colors.grey는 특수 케이스로 유지

### [2026-05-22] OS 기본 폰트 적용 (google_fonts 제거)
- **변경 사항:**
  - `app_theme.dart`에서 `google_fonts` import 및 `GoogleFonts.notoSansKr` 관련 코드 전체 제거
  - `textTheme`을 `GoogleFonts.notoSansKrTextTheme()` → `TextTheme()` 으로 교체
  - 모든 `TextStyle`에서 `fontFamily` 파라미터 제거 → iOS: SF Pro / Android: 기기 기본 폰트 사용
- **영향받는 파일:**
  - 수정 - `lib/shared/theme/app_theme.dart` — google_fonts 의존 코드 제거
- **특이사항 및 남은 작업:**
  - `pubspec.yaml`의 `google_fonts` 의존성은 복원을 고려해 유지

---

### [2026-05-22] NavigationBar 아이콘·레이블 색상 개선
- **변경 사항:**
  - 선택된 탭: 아이콘·레이블 → `cs.primary` (라이트 딥 포레스트 그린 / 다크 민트 그린)
  - 미선택 탭: `cs.onSurfaceVariant` 60% 투명도로 은은하게 처리
  - `iconTheme`, `labelTextStyle` 모두 `WidgetStateProperty.resolveWith`로 상태별 분기
- **영향받는 파일:**
  - 수정 - `lib/shared/theme/app_theme.dart` — `navigationBarTheme` 수정

---

### [2026-05-22] 기록 입력 화면 UI 세부 조정
- **변경 사항:**
  - 메모 퀵태그 칩 간격: `spacing` · `runSpacing` 모두 `2`로 통일
  - 메모 퀵태그 칩 세로 패딩 `vertical: 0` + `materialTapTargetSize: shrinkWrap` 적용 — 48dp 강제 높이 제거
  - 카테고리 레이블(`상태`, `증상` 등) 상단 여백 `13 → 6`으로 축소
  - 화장실 토글(`_VisitedToggle`) `minVerticalPadding: 0` 명시 — 전역 테마 14dp 여백 재정의
- **영향받는 파일:**
  - 수정 - `lib/features/record/record_screen.dart` — `_MemoQuickTags`, `_VisitedToggle` 수정

---

### [2026-05-22] AppColors 색상 상수 용도 주석 추가 및 미사용 상수 제거
- **변경 사항:**
  - 미사용 상수 6개 제거: `lightHintText`, `darkHintText`, `moodGoodDark`, `moodOkayDark`, `moodBadDark`, `moodNoneDark`
  - 잔여 상수 전체에 용도 주석 추가 (사용 컴포넌트 및 대응 `ColorScheme` 역할 명시)
- **영향받는 파일:**
  - 수정 - `lib/shared/theme/app_theme.dart` — `AppColors` 클래스 정리

---

### [2026-05-22] 라이트 모드 화면 배경 #FFFFFF 통일
- **변경 사항:**
  - `AppColors.lightBackground`를 `#F6FAF7` → `#FFFFFF`로 변경하여 모든 화면 배경 순수 흰색 통일
- **영향받는 파일:**
  - 수정 - `lib/shared/theme/app_theme.dart` — `lightBackground` 상수값 변경 (scaffoldBg·appBarBg에 연쇄 적용)
- **특이사항 및 남은 작업:**
  - 다크 모드 배경은 기존 유지

---

### [2026-05-22] 전체 컬러 시스템 완전 재설계 (AI 선택)
- **변경 사항:**
  - 기존 누적된 색상 스펙 전부 폐기 후 처음부터 재설계
  - Primary: `#2D6A4F` 딥 포레스트 그린 (흰 텍스트 5.7:1 대비) — 자연·건강 앱에 최적
  - Secondary: `#A85C30` 따뜻한 테라코타 (녹색 보색 계열)
  - Light 배경: `#F6FAF7` 미세한 초록빛 흰색, Surface: `#FFFFFF` 순백
  - Dark 배경: `#0F1410` 짙은 숲 계열, Surface: `#171D18`
  - 다크 Primary: `#74C19A` 밝은 민트 그린 (어두운 배경 고대비)
  - 기분 컬러 재정의: Good `#3DA06C` / Okay `#CC7D30` / Bad `#C64848` / None `#8CA896`
  - `ColorScheme` (light + dark) 완전 재구성 — primaryContainer, surfaceContainer 계층 모두 갱신
- **영향받는 파일:**
  - 수정 - lib/shared/theme/app_theme.dart — AppColors·ColorScheme·AppTheme 모두 재작성

### [2026-05-22] 디자인 시스템 (Color System) 구축
- **변경 사항:**
  - `AppColors` 클래스 신규 — 라이트/다크 팔레트 원시 상수 분리
  - 기분 컬러 갱신: Good `#7FBF7A` / Okay `#F0C36A` / Bad `#E78B8B` / None `#B8B2A8` (다크 변형 추가)
  - `ColorScheme` 완전 수동 구성 — `fromSeed` 제거, surfaceContainer 계층 모두 명시
  - 컴포넌트 테마 추가: AppBar / NavigationBar / FAB / Card / Dialog / BottomSheet / Chip / FilledButton / OutlinedButton / TextButton / Input / ListTile / Divider
  - `google_fonts` 패키지 추가, Noto Sans KR TextTheme 적용
  - `style.dart` 재작성: `AppRadius` / `AppButtonStyle` / `AppCard` / `AppDivider`
  - `ThemeContext` 확장에 `tt`, `isDark`, `moodColor()` 추가
  - `AppTheme.primaryGreen` 제거 → 각 위젯에서 `cs.primary` 사용으로 교체
- **영향받는 파일:**
  - 재작성 - `lib/shared/theme/app_theme.dart`
  - 재작성 - `lib/shared/theme/style.dart`
  - 수정 - `pubspec.yaml` — google_fonts: ^6.2.1 추가
  - 수정 - `lib/features/calendar/calendar_screen.dart` — primaryGreen → cs.primary
  - 수정 - `lib/features/more/more_screen.dart` — primaryGreen → cs.primary
  - 수정 - `lib/features/timeline/widgets/date_header.dart` — primaryGreen → cs.primary
  - 수정 - `lib/features/stats/widgets/stat_heat_map_grid.dart` — primaryGreen → cs.primary
- **특이사항:**
  - 기분 컬러(moodGood/Okay/Bad/None)는 정적 상수 유지 (chart/dot 렌더링에서 context 없이 사용됨)
  - 다크모드 기분 변형(`moodGoodDark` 등)은 context.moodColor()로 접근 가능

---

### [2026-05-22] 메모 빠른 태그 카테고리 확장
- **변경 사항:**
  - 빠른 태그를 카테고리(상태/증상/식사/기타)별로 분류해 표시
  - 태그 6개 → 13개로 확장 (쾌변·설사·묽음·딱딱함 / 배아픔·잔변감·급했음·냄새 심함·냄새 없음 / 식후·공복 / 스트레스·운동 후)
- **영향받는 파일:**
  - 수정 - `lib/features/record/record_screen.dart` — `_MemoQuickTags` 위젯 구조 변경

---

### [2026-05-22] 데이터 초기화 방식 변경
- **변경 사항:**
  - 데이터 초기화 시 `DELETE FROM entries` → `DROP TABLE` + 재생성 방식으로 변경
  - auto-increment ID 카운터도 함께 초기화됨
- **영향받는 파일:**
  - 수정 - `lib/core/database/app_database.dart` — `deleteAllEntries()` 구현 변경, 반환 타입 `int` → `void`

---

### [2026-05-21] 기록 화면 기분 버튼 UI 개선
- **변경 사항:**
  - face 모드일 때 기분 아이콘 크기 28px → 22px로 축소
  - face/dot 모드 관계없이 기분 버튼 높이를 dot 기준(28px)으로 통일
  - `_MoodSelector`를 `ConsumerWidget`으로 전환해 `moodDisplayProvider` 직접 감시
- **영향받는 파일:**
  - 수정 — `lib/features/record/record_screen.dart`

### [2026-05-21] primaryContainer 색상 통일 및 UI 개선
- **변경 사항:**
  - Material 3 테마 `primaryContainer`를 사용하는 모든 곳을 `AppTheme.primaryGreen(#80A77E)`으로 통일
  - FAB(캘린더·타임라인) 배경색을 테마 레벨에서 `#80A77E`로 고정 (`FloatingActionButtonThemeData`)
  - 주 시작 요일 기본값 월요일 → 일요일 변경
  - 기록 입력 화면 기분 버튼 미선택 배경 불투명도 0.4 → 0.5, 패딩 vertical 10 → 8
  - 기록 입력 화면 화장실 스위치 크기 0.75배 축소 (`Transform.scale`)
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart` — FAB 테마 추가
  - 수정 — `lib/core/settings/display_settings.dart` — 주 시작 요일 기본값 → true(일요일)
  - 수정 — `lib/main.dart` — SharedPreferences 폴백값 → true
  - 수정 — `lib/features/record/record_screen.dart` — 기분 버튼 alpha·패딩, 스위치 스케일
  - 수정 — `lib/features/timeline/widgets/date_header.dart` — 오늘 헤더 배경 → primaryGreen
  - 수정 — `lib/features/calendar/calendar_screen.dart` — 오늘 날짜 원 배경 → primaryGreen
  - 수정 — `lib/features/stats/widgets/stat_heat_map_grid.dart` — 피크 시간대 카드 배경 → primaryGreen
  - 수정 — `lib/features/more/more_screen.dart` — 광고 제거 배너 배경 → primaryGreen

### [2026-05-21] 피드백·개인정보처리방침 버튼 무반응 버그 수정 및 테스트 추가
- **변경 사항:**
  - `_kFeedbackUrl`이 `String.fromEnvironment('https://www.google.com')`로 잘못 작성되어 항상 빈 문자열 반환 → URL 비활성화 버그 수정
  - `feedbackUrlProvider` / `privacyPolicyUrlProvider` Riverpod Provider로 추출 (테스트 가능하도록)
  - `_launchContactForm`, `_launchPrivacyPolicy` 메서드를 Provider에서 URL 읽도록 수정
  - URL 관련 테스트 4개 추가: 미설정 시 no-op / 설정 시 정상 launch
- **영향받는 파일:**
  - 수정 — `lib/features/more/more_screen.dart` — Provider 추가, 버그 수정
  - 수정 — `test/features/more/more_screen_test.dart` — `_FakeUrlLauncherPlatform` 및 테스트 4개 추가
- **특이사항 및 남은 작업:**
  - 실제 URL은 빌드 시 `--dart-define=FEEDBACK_URL=<url>` / `--dart-define=PRIVACY_POLICY_URL=<url>` 로 주입. 미설정 시 버튼 무반응(의도된 동작)

### [2026-05-21] 라이트 모드 AppBar 배경 흰색 고정
- **변경 사항:**
  - 라이트 테마 `AppBarTheme`에 `backgroundColor: Colors.white` 추가 (모든 화면 앱바 배경 흰색)
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart`

---

### [2026-05-21] 전체 색상 #80a77e 기준으로 통일
- **변경 사항:**
  - `primaryGreen` → `#80A77E` (세이지 그린 계열로 교체)
  - `moodGood` → `#4E8A4C` (#80a77e 동계열 채도 높인 진한 초록)
  - 네비게이션 바 indicatorColor → `#CEE5CD`
  - 히트맵 셀 색상 4단계 모두 #80a77e 팔레트로 교체
    - 1단계 `#DFF0DE` / 2단계 `#ADCCAC` / 3단계 `#80A77E` / 4단계 `#4D7A4B`
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart`
  - 수정 — `lib/features/stats/widgets/stat_heat_map_grid.dart`

---

### [2026-05-21] 앱 primary seed 색상 변경
- **변경 사항:**
  - `AppTheme.primaryGreen` `#7CB342` → `#89A857` (moodGood #639922와 어울리는 풀잎 톤으로 변경)
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart`

---

### [2026-05-21] 앱 테마 연하게 조정 + 시간대별 방문 그래프 녹색 계열 변경
- **변경 사항:**
  - `AppTheme.primaryGreen` seed 색상을 `#639922` → `#7CB342`로 변경 (한 톤 밝게, 전체 색상 연해짐)
  - 시간대별 방문 히트맵 셀 색상을 파란 계열 → 녹색 계열로 교체
    - 1단계: `#E6F1FB` → `#E8F5D0` / 2단계: `#85B7EB` → `#B3D87A`
    - 3단계: `#378ADD` → `#7CB342` / 4단계: `#185FA5` → `#4E8020`
  - 히트맵 텍스트 색상도 파란 계열 → 녹색 계열로 교체
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart`
  - 수정 — `lib/features/stats/widgets/stat_heat_map_grid.dart`

---

### [2026-05-21] 라이트 모드 배경색 화이트 고정
- **변경 사항:**
  - 라이트 테마에 `scaffoldBackgroundColor: Colors.white` 추가 (Material 3 seed 색상에 의한 기본 배경색 대신 순수 흰색 적용)
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart`

---

### [2026-05-21] 앱 테마 색상 블루 → 그린으로 변경
- **변경 사항:**
  - `AppTheme.primaryBlue` → `AppTheme.primaryGreen` (`#185FA5` → `#639922`) 으로 교체
  - 라이트/다크 테마 seed 색상 모두 녹색 계열로 변경
  - 네비게이션 바 indicatorColor를 파란 계열(`#E6F1FB`) → 녹색 계열(`#D9EDBD`)로 변경
- **영향받는 파일:**
  - 수정 — `lib/shared/theme/app_theme.dart`

---

### [2026-05-21] 배포 가이드 문서 신규 생성
- **변경 사항:**
  - `docs/RELEASE.md` 신규 생성 — 배포 빌드 명령, secrets 준비, 버전 관리, 스토어 제출 전 체크리스트 포함
  - `docs/QA_CHECKLIST.md` — 배포 섹션 제거 후 `RELEASE.md` 링크로 대체
- **영향받는 파일:**
  - 신규 생성 — `docs/RELEASE.md`
  - 수정 — `docs/QA_CHECKLIST.md`

---

### [2026-05-21] 배포 빌드 주의사항 문서화 및 AdMob ID 보안 강화
- **변경 사항:**
  - `build.gradle.kts` 폴백 AdMob App ID를 실제 ID → Google 테스트 ID로 교체 (git 노출 방지)
  - `QA_CHECKLIST.md` 상단에 "배포 빌드 전 필수 확인 사항" 섹션 추가
    - `--dart-define-from-file=secrets.json` 미포함 빌드 시 테스트 ID로 배포되는 위험 명시
    - `local.properties`의 `admob.app.id` 설정 필요 여부 명시
    - `secrets.json` git 미포함 확인 방법 안내
  - `QA_CHECKLIST.md` 내 네이티브 광고 주기 "7번째" → "10번째"로 수정
- **영향받는 파일:**
  - 수정 — `android/app/build.gradle.kts` — AdMob App ID 폴백을 테스트 ID로 교체
  - 수정 — `docs/QA_CHECKLIST.md` — 배포 전 필수 확인 섹션 추가, 광고 주기 수정

---

### [2026-05-21] 앱 아이콘 및 스플래시 화면 적용
- **변경 사항:**
  - `flutter_launcher_icons`로 Android·iOS 앱 아이콘 생성 (adaptive icon 포함)
  - `flutter_native_splash`로 Android·iOS 스플래시 화면 생성 (배경색 `#FAF3E8`, 크림색)
- **영향받는 파일:**
  - 신규 생성 — `assets/icon/app_icon.png` — 앱 아이콘 원본
  - 수정 — `pubspec.yaml` — `flutter_launcher_icons`, `flutter_native_splash` 패키지 및 설정 추가
  - 자동 생성 — `android/app/src/main/res/mipmap-*/` — Android 아이콘 전 해상도
  - 자동 생성 — `android/app/src/main/res/drawable*/launch_background.xml` — 스플래시 레이아웃
  - 자동 생성 — `android/app/src/main/res/values*/styles.xml` — 스플래시 스타일
  - 자동 생성 — `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — iOS 아이콘 전 해상도
  - 자동 생성 — `ios/Runner/Assets.xcassets/LaunchImage.imageset/` — iOS 스플래시 이미지

---

### [2026-05-21] VS Code 실행 설정 추가
- **변경 사항:**
  - `.vscode/launch.json` 생성 — `--dart-define-from-file=secrets.json` 플래그 자동 포함
  - 이로 인해 피드백 보내기·개인정보처리방침 URL이 빌드 시 정상 주입됨
- **영향받는 파일:**
  - 신규 생성 — `.vscode/launch.json` — debug·release 두 가지 실행 구성
- **특이사항 및 남은 작업:**
  - 터미널 직접 실행 시에는 `flutter run --dart-define-from-file=secrets.json` 필요

---

### [2026-05-21] 광고 노출 빈도 조정
- **변경 사항:**
  - 전면 광고 빈도 주석 "N회" → "7회"로 명확화 (실제 값은 기존부터 7)
  - 타임라인 네이티브 광고 삽입 주기 7번째 → 10번째 기록마다로 변경
- **영향받는 파일:**
  - 수정 — `lib/core/ads/ad_service.dart` — `_kInterstitialFrequency` 주석 수정
  - 수정 — `lib/features/timeline/timeline_screen.dart` — `entryCount % 7` → `% 10`

---

### [2026-05-21] 주요 메서드 주석 추가
- **변경 사항:**
  - 비자명한 WHY가 없던 중요 메서드에 주석 추가
  - `ad_service.dart` — `_kInterstitialFrequency` 상수 주석 "5회" → "N회" 수정 (실제 값 7과 불일치)
- **영향받는 파일:**
  - 수정 — `lib/core/iap/iap_provider.dart` — `buy()`, `restore()`, `clearError()`, `_onPurchases()` 주석 추가
  - 수정 — `lib/core/widget/home_widget_service.dart` — `update()`, `_hex()` 주석 추가
  - 수정 — `lib/features/timeline/timeline_provider.dart` — `_toGroups()` 주석 추가
  - 수정 — `lib/features/stats/stats_provider.dart` — `statsResultProvider` 주석 추가
  - 수정 — `lib/core/ads/ad_service.dart` — 상수 주석 오탈자 수정
  - 수정 — `lib/shared/widgets/entry_card.dart` — `_truncateMemo()` 주석 추가
  - 수정 — `lib/shared/widgets/mood_face_painter.dart` — 클래스·`_drawFurrowedBrows()` 주석 추가
  - 수정 — `lib/features/more/more_screen.dart` — `_onVersionTap()` 이스터에그 주석 추가

---

### [2026-05-21] Android 위젯 단위 테스트 작성 및 컴파일 오류 수정
- **변경 사항:**
  - `WidgetDataStoreTest.kt` 작성 — MockK로 SharedPreferences 모킹, 21개 테스트 100% 통과
  - Flutter `test/core/widget/home_widget_service_test.dart` 작성 — 18개 테스트 통과
  - `org.jetbrains.kotlin.plugin.compose` 플러그인 추가 — Kotlin 2.1.0 K2 컴파일러에서 Glance @Composable 인라인 함수 오류 수정
  - `PooPooWidget.kt` — `currentState()` 제거, `provideGlance`에서 SharedPreferences 직접 읽기로 변경 (K2 inline 오류 우회)
  - `PooPooWidgetReceiver.kt` — `scheduleMidnightReset`의 nullable PendingIntent 처리 수정 (`?: return`)
- **영향받는 파일:**
  - 신규 생성 — `android/.../test/.../WidgetDataStoreTest.kt` — WidgetDataStore 단위 테스트
  - 신규 생성 — `test/core/widget/home_widget_service_test.dart` — HomeWidgetService 단위 테스트
  - 수정 — `android/settings.gradle.kts` — compose 컴파일러 플러그인 선언
  - 수정 — `android/app/build.gradle.kts` — compose 플러그인 및 `buildFeatures { compose = true }` 추가
  - 수정 — `android/.../widget/PooPooWidget.kt` — currentState 제거, SharedPreferences 직접 읽기
  - 수정 — `android/.../widget/PooPooWidgetReceiver.kt` — nullable PendingIntent 안전 처리
- **특이사항 및 남은 작업:**
  - Kotlin 2.1.0 K2 컴파일러에서 Glance `currentState<T>()` inline 함수를 사용하면 컴파일 실패함 → SharedPreferences 직접 읽기로 우회
  - iOS 홈 화면 위젯 미구현 (별도 작업 필요)

---

### [2026-05-21] Android 홈 화면 위젯 구현
- **변경 사항:**
  - `home_widget: ^0.9.1` 패키지 추가
  - `HomeWidgetService` 추가 — 기록 저장·삭제 시 위젯 데이터(visit_count, last_time, last_mood_label, last_mood_color, today_dots, date_label) 저장 및 위젯 갱신
  - Jetpack Glance 기반 위젯 3종 (1×1 / 2×1 / 2×2) 구현 — `SizeMode.Responsive`로 크기 자동 분기
  - 위젯 + 버튼 탭 시 기록 화면 바로 열기 (`open_record` Intent extra + MethodChannel)
  - `AlarmManager.setRepeating`으로 매일 자정 위젯 갱신
  - `BOOT_COMPLETED` 수신 시 위젯 복원 및 알람 재등록
- **영향받는 파일:**
  - 수정 — `pubspec.yaml` — `home_widget: ^0.9.1` 추가
  - 신규 생성 — `lib/core/widget/home_widget_service.dart` — 위젯 데이터 저장·갱신 서비스
  - 수정 — `lib/features/record/record_provider.dart` — save/delete 후 HomeWidgetService 호출
  - 수정 — `lib/features/shell/app_shell.dart` — ConsumerStatefulWidget 전환, MethodChannel 위젯 탭 처리
  - 수정 — `android/app/build.gradle.kts` — Glance 의존성 추가
  - 신규 생성 — `android/.../widget/PooPooWidget.kt` — Glance 위젯 3종 레이아웃
  - 신규 생성 — `android/.../widget/PooPooWidgetReceiver.kt` — HomeWidgetGlanceWidgetReceiver
  - 신규 생성 — `android/.../widget/WidgetDataStore.kt` — SharedPreferences 읽기 헬퍼
  - 신규 생성 — `android/.../widget/BootReceiver.kt` — 부팅 후 위젯 복원
  - 신규 생성 — `android/.../res/xml/poopoo_widget_info.xml` — 위젯 프로바이더 메타데이터
  - 수정 — `android/.../AndroidManifest.xml` — RECEIVE_BOOT_COMPLETED 권한 및 리시버 등록
  - 수정 — `android/.../MainActivity.kt` — MethodChannel 추가, open_record 인텐트 처리
- **특이사항 및 남은 작업:**
  - 다크/라이트 테마는 `GlanceMaterialTheme` 자동 적용
  - `updatePeriodMillis="1800000"` (30분) fallback 설정됨
  - iOS 홈 화면 위젯 미구현 (별도 작업 필요)

---

### [2026-05-20] 통계 화면 위젯 테스트 작성
- **변경 사항:**
  - `test/features/stats/stats_screen_test.dart` 신규 작성 — 13개 테스트 전부 통과
- **영향받는 파일:**
  - 신규 생성 — `test/features/stats/stats_screen_test.dart`
- **특이사항 및 비고:**
  - AppBar 타이틀, 기간 칩 4개(이번 달·최근 30일·최근 90일·직접 지정), 날짜 범위 레이블 렌더링 검증
  - Case A(빈 DB → NewUserEmptyState), Case B(기록 있음·2020 커스텀 범위 → _StatsEmptyState) 분기 검증
  - 기간 칩 탭 후 statsRangeProvider.period 변경 검증
  - 기록 삽입 후 SummaryCard 2개·방문 횟수·기분 분포·시간대별 방문 렌더링 검증
  - "기록하러 가기" 탭 → currentTabProvider = 0 (캘린더 탭) 이동 검증
  - 모든 테스트에서 `adsRemovedProvider.overrideWith((ref) => true)` 로 배너 광고 로딩 차단

---

### [2026-05-20] 기록 화면 위젯 테스트 작성
- **변경 사항:**
  - `test/features/record/record_screen_test.dart` 신규 작성 — 13개 테스트 전부 통과
- **영향받는 파일:**
  - 신규 생성 — `test/features/record/record_screen_test.dart`
- **특이사항 및 비고:**
  - AppBar·섹션 레이블·저장 버튼, 폼 초기값(visited=true/mood=null), 빠른 태그 6개 렌더링, 기분 선택·해제·전환, 방문 여부↔기분 연동, 빠른 태그 메모 추가·이어붙임, 저장 후 DB 삽입 및 화면 닫힘, 수정 모드 초기화, 삭제 다이얼로그 취소/확인 검증
  - 빠른 태그가 ListView 하단에 위치해 lazy rendering으로 기본 미노출 → `tester.drag(..., Offset(0, -500))` 으로 스크롤 후 테스트
  - `adsRemovedProvider.overrideWith((ref) => true)` 로 저장·삭제 후 Navigator.pop 즉시 보장
  - `_buildScreenWithNav` 헬퍼: ElevatedButton → pushRoute 패턴으로 pop 검증 가능

---

### [2026-05-20] 타임라인 화면 위젯 테스트 작성
- **변경 사항:**
  - `test/features/timeline/timeline_screen_test.dart` 신규 작성 — 11개 테스트 전부 통과
- **영향받는 파일:**
  - 신규 생성 — `test/features/timeline/timeline_screen_test.dart`
- **특이사항 및 비고:**
  - AppBar·FAB, 필터 칩 6개, Case A/B 빈 상태 분기, DateHeader 형식·건수 배지, 필터 탭 후 리스트 갱신 검증
  - 필터 칩과 EntryCard moodLabel 텍스트 중복 문제 → `.first` 로 칩 지정

---

### [2026-05-20] 캘린더 화면 위젯 테스트 작성
- **변경 사항:**
  - `test/features/calendar/calendar_screen_test.dart` 신규 작성 — 10개 테스트 전부 통과
- **영향받는 파일:**
  - 신규 생성 — `test/features/calendar/calendar_screen_test.dart`
- **특이사항 및 비고:**
  - AppBar·FAB 렌더링, 오늘 버튼 노출 조건, 월 헤더 텍스트, DayPanel 표시/미표시, EntryCard 다건 렌더링, _BeforeEarliestState, 오늘 버튼 탭 동작 등 9개 시나리오 검증

---

### [2026-05-20] 더보기 > 정보 섹션에 개인정보처리방침 추가
- **변경 사항:**
  - 더보기 화면 정보 섹션 최상단에 "개인정보처리방침" 항목 추가
  - `String.fromEnvironment('PRIVACY_POLICY_URL')` 방식으로 URL 분리 (기존 FEEDBACK_URL 패턴 동일)
  - URL 미설정(빈 값) 시 탭해도 동작 없음
- **영향받는 파일:**
  - 수정 — `lib/features/more/more_screen.dart` — 타일 추가, `_launchPrivacyPolicy()` 메서드 추가
  - 수정 — `secrets.json` — `PRIVACY_POLICY_URL` 키 추가 (값은 노션 링크로 채워야 함)

---

### [2026-05-20] 빈 화면(Empty State) Case A/B 분기 처리
- **변경 사항:**
  - 신규 유저(DB 기록 0개) = Case A: 기록 추가 유도 UI 표시
  - 필터·기간 결과 없음 = Case B: 기존 안내 문구 유지
  - 통계 화면 Case A에 "기록하러 가기" 버튼 추가 → 캘린더 탭으로 이동
  - `earliestEntryDateProvider` (이미 존재)를 신규 유저 판단 기준으로 재활용
- **영향받는 파일:**
  - 신규 생성 — `lib/shared/widgets/new_user_empty_state.dart`
  - 수정 — `lib/features/stats/stats_screen.dart` — Case A/B 분기, `NewUserEmptyState` 적용
  - 수정 — `lib/features/timeline/timeline_screen.dart` — Case A/B 분기, `_refresh()`에 `earliestEntryDateProvider` invalidate 추가

---

### [2026-05-20] 더보기 화면 위젯 테스트 작성
- **변경 사항:**
  - `AppDatabase.forTesting(super.e)` 생성자 추가 (Drift in-memory DB 테스트용)
  - `test/features/more/more_screen_test.dart` 신규 작성 — 16개 테스트 전부 통과
- **영향받는 파일:**
  - `lib/core/database/app_database.dart`
  - `test/features/more/more_screen_test.dart`
- **특이사항 및 비고:**
  - `_FakePurchaseNotifier`로 IAP 플랫폼 채널 구독을 차단하고 `simulateState()`로 상태 전환 테스트
  - 스크롤이 필요한 하단 항목(데이터 초기화, 앱 버전)은 `scrollUntilVisible` + `ensureVisible` 조합으로 뷰포트 내 탭 보장

---

### [2026-05-19] 민감 정보 분리 — AdMob ID·URL GitHub 노출 방지
- **변경 사항:**
  - AdMob Unit ID 6개 및 피드백 URL을 `String.fromEnvironment` 방식으로 소스코드에서 분리
  - Android AdMob App ID를 `local.properties` + Gradle manifest placeholder 방식으로 분리
  - iOS AdMob App ID를 `Secrets.xcconfig` + xcconfig 변수 주입 방식으로 분리
  - 민감 파일(`secrets.json`, `Secrets.xcconfig`) gitignore 등록, 커밋용 템플릿(`secrets.example.json`) 추가
- **영향받는 파일:**
  - `secrets.json`, `secrets.example.json`, `.gitignore`
  - `lib/core/ads/ad_ids.dart`, `lib/features/more/more_screen.dart`
  - `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `android/local.properties`
  - `ios/Flutter/Secrets.xcconfig`, `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`, `ios/Runner/Info.plist`
- **특이사항 및 비고:**
  - `secrets.json` 없이 실행 시 테스트 ID로 자동 폴백되므로 개발 환경에서 별도 설정 불필요
  - 릴리즈 빌드 시 `flutter build appbundle --release --dart-define-from-file=secrets.json` 사용

### [2026-05-19] 코드 교차 검증 — 버그 4건 수정 및 flutter analyze 경고 0건 달성
- **변경 사항:**
  - `lib/features/calendar/calendar_screen.dart:89` — `earliestDate!` 불필요 non-null assertion 분석기 경고 suppress (`isBeforeEarliest` 조건이 non-null 보장)
  - `lib/features/calendar/widgets/month_picker_sheet.dart:36-37` — `_maxYear`, `_currentMonth`를 `static final`(클래스 최초 로드 고정) → `late final` + `initState()` 초기화로 변경. 연말~연초 앱 백그라운드 유지 시 연도 고정 버그 수정
  - `lib/features/stats/stats_screen.dart:162` — 커스텀 기간 피커 `firstDate: DateTime(2026)` → `DateTime(2024)` 변경. 테스트 데이터(2025-10~) 조회 불가 버그 수정
  - `lib/features/timeline/timeline_provider.dart:104` — 주석 "이번 달 포함 최근 3개월" → "이번 달 포함 최근 6개월" 수정 (코드는 `_chunkMonths=6` 기준으로 옳았으나 주석 오류)
- **영향받는 파일:** `calendar_screen.dart`, `month_picker_sheet.dart`, `stats_screen.dart`, `timeline_provider.dart`
- **특이사항 및 비고:** `flutter analyze` 경고 0건 달성. 히트맵/날짜제한/바텀시트 범위 로직은 모두 정상 검증됨

### [2026-05-19] 인앱 결제 버그 수정 — buy() 예외 처리 + restore() 타이머 폴백
- **변경 사항:**
  - `lib/core/iap/iap_provider.dart` — `buy()` 전체 try-catch 추가 (예외 시 `IAPStatus.error` 처리). `restore()` try-catch 추가 + 5초 타이머 폴백(복원할 구매 없을 때 `loading` 무기한 지속 버그 수정). `_restoreTimer` 필드 추가, `onDispose`에서 정리
  - `lib/features/more/more_screen.dart` — `listenManual` 콜백에 `prev==loading && next==idle && !adsRemoved` 조건 추가 → "이전 구매 내역을 찾을 수 없어요." SnackBar 표시
- **영향받는 파일:** `lib/core/iap/iap_provider.dart`, `lib/features/more/more_screen.dart`
- **특이사항 및 비고:** 스토어 미등록 상태에서는 `buy()` 시 `productDetails.isEmpty` → error 처리됨. 스토어 등록(Google Play, App Store) 은 출시 전 별도 작업 필요

### [2026-05-19] UI 개선 다수 — 리팩토링·도트·날짜 헤더·통계·캘린더 경계
- **변경 사항:**
  - `lib/features/more/more_screen.dart` — `_ThemePickerSheet`, `_MoodDisplaySheet`, `_TwoOptionSheet` → 단일 `_ListPickerSheet`로 통합 리팩토링 (956줄 → 760줄). `_showBottomSheet`, `_showConfirmDialog`, `_showLoadingDialog`, `_invalidateAll()` 헬퍼 추출. 바텀시트 타이틀 중앙정렬. `"캘린더 시작 요일"` → `"주 시작 요일"` 문구 변경. `ref.invalidate(earliestEntryDateProvider)` 추가
  - `lib/shared/widgets/mood_indicator.dart` — `_DotPainter` 제거. `CustomPaint` → `Center + SizedBox.square + DecoratedBox(BoxShape.circle)` 전환. 도트 크기 6px 고정 (`_dotDiameter`). 기존 `SizedBox` 내 `CustomPaint.size`가 타이트 제약에 의해 무시되던 버그 수정
  - `lib/features/calendar/widgets/mood_dot_row.dart` — `MoodIndicator` 의존성 제거. `moodDisplayProvider` 구독 없이 항상 색상 도트 표시. `entry.moodColor + DecoratedBox` 직접 렌더링
  - `lib/features/timeline/widgets/date_header.dart` — `"어제"` 특수 처리 제거. `"오늘"` 레이블 제거. 모든 날짜 `"m월 d일 (요일)"` 형식 통일. 오늘은 Primary 컬러 + 좌측 수직 바 유지
  - `lib/features/stats/stats_provider.dart` — `peakHour: int?` → `peakHours: List<int>`. 공동 최대 시간대 전부 포함
  - `lib/features/stats/widgets/stat_heat_map_grid.dart` — `peakHours.map(_hourLabel).join(', ')`로 공동 피크 모두 표시. `_colorStep()` 메서드 신규: maxCount ≤ 3은 count = step, ≥ 4는 비율 기반 4단계
  - `lib/core/database/app_database.dart` — `getOldestEntryDate()` 메서드 추가
  - `lib/features/calendar/calendar_provider.dart` — `earliestEntryDateProvider (FutureProvider<DateTime?>)` 추가
  - `lib/features/calendar/widgets/month_picker_sheet.dart` — `minDate` 파라미터 추가. 연도·월 최솟값 동적 계산 (`_minYear`, `_minMonth`, `_minMonthForYear`)
  - `lib/features/calendar/calendar_screen.dart` — `earliestEntryDateProvider` 구독. `isBeforeEarliest` 판단 로직. `_BeforeEarliestState` 위젯 추가 ("푸푸로그를 시작하기 전이에요!"). `TableCalendar.firstDay` → `DateTime(2020)` 하드코딩 (동적 변경 시 달력 깨짐 버그 방지). 기록 저장 후 `ref.invalidate(earliestEntryDateProvider)` 추가
- **영향받는 파일:** `more_screen.dart`, `mood_indicator.dart`, `mood_dot_row.dart`, `date_header.dart`, `stats_provider.dart`, `stat_heat_map_grid.dart`, `app_database.dart`, `calendar_provider.dart`, `month_picker_sheet.dart`, `calendar_screen.dart`
- **특이사항 및 비고:** `TableCalendar.firstDay`는 초기화 후 변경 불가 (동적 변경 시 달력 공백). `DateTime(2020)`으로 하드코딩하고 경계 처리는 `isBeforeEarliest` empty state로 분리함

### [2026-05-18] 기분 표시 방식 설정 — 얼굴 아이콘 모드 구현
- **변경 사항:**
  - `lib/core/models/mood_display_provider.dart` 신규 — `MoodDisplay` enum (dot/face), `moodDisplayProvider`, `loadMoodDisplay()`, `saveMoodDisplay()`
  - `lib/shared/widgets/mood_face_painter.dart` 신규 — CustomPainter 얼굴 아이콘 (좋음·보통·나쁨·없음/미방문)
  - `lib/shared/widgets/mood_indicator.dart` 신규 — `moodDisplayProvider` 구독, dot↔face 자동 전환 위젯
  - `lib/core/settings/display_settings.dart` — 이모지 Provider 제거 (`moodDisplayEmojiProvider` 삭제)
  - `lib/features/calendar/widgets/mood_dot_row.dart` — `MoodIndicator.fromEntry(size: 8)` 적용, `ConsumerWidget` → `StatelessWidget`
  - `lib/shared/widgets/entry_card.dart` — `MoodIndicator.fromEntry(size: 20)` 적용, `ConsumerWidget` → `StatelessWidget`
  - `lib/features/stats/stats_screen.dart` — 도넛 차트 범례 `MoodIndicator(size: 14)` 적용, `_MoodDonutChart` `ConsumerWidget` → `StatelessWidget`
  - `lib/features/record/record_screen.dart` — `_MoodSelector` 내 색상 도트 Container → `MoodIndicator(size: 28)`
  - `lib/features/more/more_screen.dart` — 기분 표시 설정을 `SegmentedButton<MoodDisplay>` 인라인 타일로 교체
  - `lib/main.dart` — `loadMoodDisplay()` 초기값 로드 → `moodDisplayProvider` override 주입
- **영향받는 파일:** `mood_display_provider.dart`, `mood_face_painter.dart`, `mood_indicator.dart`, `display_settings.dart`, `mood_dot_row.dart`, `entry_card.dart`, `stats_screen.dart`, `record_screen.dart`, `more_screen.dart`, `main.dart`
- **특이사항 및 비고:** 이모지 모드 제거, 얼굴 아이콘(CustomPainter) 모드로 대체. `MoodIndicator`가 표시 방식을 자체적으로 처리하므로 상위 위젯들은 Provider를 직접 구독하지 않아도 됨.

### [2026-05-18] 광고 제거 인앱 결제 구현
- **변경 사항:**
  - `lib/core/iap/iap_provider.dart` 신규 — `adsRemovedProvider`, `purchaseNotifierProvider`, `PurchaseNotifier` (구매 스트림 처리, `buy()`, `restore()`)
  - `lib/core/ads/banner_ad_widget.dart` — `ConsumerWidget`으로 전환, `adsRemovedProvider` true 시 숨김
  - `lib/core/ads/native_ad_widget.dart` — 동일
  - `lib/core/ads/ad_service.dart` — `onRecordSaved(adsRemoved:)` 파라미터 추가, true 시 전면 광고 건너뜀
  - `lib/features/record/record_screen.dart` — `adsRemovedProvider` 값 전달
  - `lib/features/more/more_screen.dart` — `_RemoveAdsBanner` 위젯 추가 (구매 전: ₩2,900 버튼 + 복원 링크 / 구매 후: 완료 메시지), 오류 시 스낵바
  - `lib/main.dart` — `kAdsRemovedKey` SharedPreferences 로드 → `adsRemovedProvider` override 주입
  - `pubspec.yaml` — `in_app_purchase: ^3.2.0` 추가
- **영향받는 파일:** `iap_provider.dart`, `banner_ad_widget.dart`, `native_ad_widget.dart`, `ad_service.dart`, `record_screen.dart`, `more_screen.dart`, `main.dart`, `pubspec.yaml`
- **특이사항 및 비고:** 스토어 상품 ID `remove_ads` — 출시 전 Google Play Console / App Store Connect에 등록 필요. `PurchaseDetails.pendingCompletePurchase` (bool) 필드로 완료 처리.

### [2026-05-18] 더보기 기능 3종 구현 (기분 표시 방식 / 시작 요일 / CSV 내보내기·가져오기)
- **변경 사항:**
  - `lib/core/settings/display_settings.dart` 신규 생성 — `moodDisplayEmojiProvider`, `startWeekdaySundayProvider` 및 SharedPreferences 키 상수
  - `lib/core/extensions/entry_ext.dart` — `MoodLevel.emoji` getter 및 `EntryX.moodEmoji` 확장 추가
  - `lib/shared/widgets/entry_card.dart` — `ConsumerWidget`으로 전환, 이모지/색상 모드 분기 표시
  - `lib/features/calendar/widgets/mood_dot_row.dart` — `ConsumerWidget`으로 전환, `_ColorDot`/`_EmojiDot` 분기
  - `lib/features/stats/stats_screen.dart` — `_MoodDonutChart` `ConsumerWidget`으로 전환, 이모지 모드 범례 지원
  - `lib/features/calendar/calendar_screen.dart` — `startWeekdaySundayProvider` 구독, `TableCalendar.startingDayOfWeek` 동적 설정
  - `lib/features/more/more_screen.dart` — 기분 표시·시작 요일 설정 UI, CSV 내보내기(`share_plus`) / 가져오기(`file_picker`) 구현
  - `lib/main.dart` — `moodDisplayEmojiProvider`, `startWeekdaySundayProvider` 초기값 SharedPreferences에서 로드해 `ProviderScope` override 주입
  - `pubspec.yaml` — `share_plus: ^10.0.3`, `file_picker: ^8.0.0` 추가
- **영향받는 파일:** `display_settings.dart`, `entry_ext.dart`, `entry_card.dart`, `mood_dot_row.dart`, `stats_screen.dart`, `calendar_screen.dart`, `more_screen.dart`, `main.dart`, `pubspec.yaml`
- **특이사항 및 비고:** share_plus 10.x API는 `Share.shareXFiles()` 사용 (`SharePlus.instance.share` 아님). `flutter analyze` 경고 0개 확인.

### [2026-05-18] 캘린더 Provider·위젯 리팩토링
- **변경 사항:**
  - `calendar_provider.dart`: 미사용 `ref` 파라미터 → `_` 처리 (2곳)
  - `mood_dot_row.dart`: `visible` 중간 변수 제거, `.take().map()` 인라인으로 단순화
  - `month_picker_sheet.dart`: 자명한 인라인 주석 4개 제거 (`// 핸들`, `// 버튼`, `// 선택 가능 범위`, `// 연도 피커`), WHY 주석은 유지
- **영향받는 파일:**
  - `lib/features/calendar/calendar_provider.dart`
  - `lib/features/calendar/widgets/mood_dot_row.dart`
  - `lib/features/calendar/widgets/month_picker_sheet.dart`
- **특이사항 및 비고:** `flutter analyze` 경고 0개 유지

---

### [2026-05-18] 전체 리팩토링 — 코드 품질 정리
- **변경 사항:**
  - `main.dart`: 미사용 import 2개 제거, locale 리스트 `const` 적용
  - `app_theme.dart`: 미사용 `import 'dart:ui'` 제거, 주석 정리, `dark()` 테마에 `navigationBarTheme` 추가
  - `style.dart`: `TextStyle` 생성자 `const` 추가
  - `entry_card.dart`: 미사용 `import 'dart:math'` 제거, TODO 주석 제거, `withOpacity` → `withValues`, `BoxConstraints` const화
  - `summary_card.dart`: `withOpacity` → `withValues`, `Theme.of(context).colorScheme` → `context.cs`, padding `fromLTRB` → `all(14)`, `SizedBox` const화
  - `stat_heat_map_grid.dart`: 문자열 보간 불필요 중괄호 3곳 제거
  - `month_picker_sheet.dart`: `colorScheme` → `cs` 변수명 통일, `app_theme.dart` import 추가
  - `timeline_provider.dart`: 중복 `import 'package:logger/logger.dart'` 제거
  - `filter_chip_row.dart`: `final filters` → `const filters`
  - `stats_screen.dart`: `final periods` → `const periods`
  - `calendar_screen.dart`: `Icon`/`SizedBox` const화, `_DayPanel` 생성자 const화
  - `record_screen.dart`: 서브위젯 생성자 const화, `TextStyle` const화
  - `record_provider.dart`: 미사용 catch stack 변수 `s` 제거
  - `more_screen.dart`: 미사용 `_requestReview()` 메서드 제거, 미사용 import 제거, `withOpacity` → `withValues`
- **영향받는 파일:** 위 14개 파일 전체
- **특이사항 및 비고:** `flutter analyze` 경고 0개 달성

---

### [2026-05-18] 에러 처리 강화 및 빈 상태·UX 개선
- **변경 사항:**
  - `insertEntry()` / `updateEntry()` / `deleteEntry()` 에러 로그에 `error`, `stackTrace` 파라미터 추가, `print()` 제거
  - 기록 입력 화면 날짜 피커 하단에 "오늘 이후 날짜는 선택할 수 없어요" 안내 문구 추가
  - 타임라인 빈 상태 텍스트에 `TextStyle` 적용 (제목 16px bold, 부제 13px onSurfaceVariant)
  - 통계 빈 상태를 `_StatsEmptyState` 위젯으로 분리, 아이콘·스타일 추가
- **영향받는 파일:**
  - `lib/core/database/app_database.dart`
  - `lib/features/record/record_screen.dart`
  - `lib/features/timeline/timeline_screen.dart`
  - `lib/features/stats/stats_screen.dart`
- **특이사항 및 비고:** `flutter analyze` 새 경고 없음

---

### [2026-05-18] 더보기 화면 히든 테스트 데이터 생성 기능 추가
- **수정된 파일:** `lib/features/more/more_screen.dart`
- **주요 변경 사항:**
  - `MoreScreen` → `ConsumerStatefulWidget` 전환 (탭 카운터 상태 관리)
  - 앱 버전 타일 5회 탭 시 테스트 데이터 추가 기능 활성화
  - 2025년 10월 1일 ~ 오늘까지 매일 0~4개 랜덤 기록 생성
  - `visited`: true/false 랜덤 (UI 스펙 상 null 제외)
  - `mood`: null 포함 4종 랜덤 (null/good/okay/bad)
  - `memo`: null 포함 7종 랜덤 (null 또는 빠른태그 문구)
  - 생성 중 로딩 다이얼로그 표시, 완료 후 SnackBar 알림 및 Provider 무효화
- **특이사항 및 비고:** 히든 기능 (버전 5회 탭), 배포 시 제거 여부 결정 필요

---

### [2026-05-18] 더보기 화면 데이터 초기화 기능 추가
- **수정/추가된 파일:**
  - `lib/core/database/app_database.dart`
  - `lib/features/shell/app_shell.dart`
  - `lib/features/more/more_screen.dart`
- **주요 변경 사항:**
  - `AppDatabase.deleteAllEntries()` 메서드 추가 (entries 테이블 전체 삭제)
  - `_currentTabProvider` → `currentTabProvider` 공개 변환 (외부 접근 허용)
  - 더보기 화면에 "데이터" 섹션 추가 — "데이터 초기화" 항목
  - 탭 시 확인 다이얼로그 표시 후 전체 삭제 → timeline·calendar·stats Provider 무효화 → 캘린더 탭(index 0)으로 이동
- **특이사항 및 비고:** 삭제 버튼은 error 색상(빨강)으로 표시하여 위험성 강조

---

### [2026-05-18] 캘린더 리스트 하단 여백 추가
- **수정된 파일:** `lib/features/calendar/calendar_screen.dart`
- **주요 변경 사항:** `_DayPanel` 내 `ListView`의 하단 패딩을 `0 → 80`으로 변경하여 플로팅 버튼에 가려지는 항목이 없도록 수정
- **특이사항 및 비고:** FAB 높이(56px) + 기본 여백(16px) 기준으로 80px 적용

---

## [2026-05-18] AdMob 광고 연동

### 변경사항

- **전면 광고 (Interstitial)**: 기록 저장 완료 후 5회마다 1회 노출. 광고 닫힌 후 화면 복귀.
- **배너 광고 (Banner)**: 통계 화면 하단에 고정 노출.
- **네이티브 광고 (Native)**: 타임라인 리스트에서 7번째 엔트리마다 카드 형태로 삽입.
- 현재 모든 광고는 Google 테스트 ID 사용 중. 출시 전 실제 ID로 교체 필요.

### 영향 받는 파일

**신규 생성**
- `lib/core/ads/ad_ids.dart` — 플랫폼별 광고 단위 ID
- `lib/core/ads/ad_service.dart` — 전면 광고 싱글톤 (로드·노출·빈도 관리)
- `lib/core/ads/banner_ad_widget.dart` — 배너 위젯
- `lib/core/ads/native_ad_widget.dart` — 네이티브 광고 위젯 (factoryId: `listTileNativeAd`)
- `android/app/src/main/res/layout/list_tile_native_ad.xml` — Android 네이티브 광고 레이아웃
- `android/app/src/main/kotlin/.../ListTileNativeAdFactory.kt` — Android 네이티브 팩토리
- `ios/Runner/ListTileNativeAdFactory.swift` — iOS 네이티브 팩토리

**수정**
- `pubspec.yaml` — `google_mobile_ads: ^5.1.0` 추가
- `android/app/src/main/AndroidManifest.xml` — INTERNET 권한, AdMob 앱 ID meta-data
- `ios/Runner/Info.plist` — GADApplicationIdentifier, SKAdNetworkItems
- `android/.../MainActivity.kt` — 네이티브 팩토리 등록/해제
- `ios/Runner/AppDelegate.swift` — 네이티브 팩토리 등록
- `lib/main.dart` — `MobileAds.instance.initialize()`, `AdService().preload()`
- `lib/features/record/record_screen.dart` — 저장 버튼에 `AdService().onRecordSaved()` 연동
- `lib/features/stats/stats_screen.dart` — 본문 하단에 `BannerAdWidget` 추가
- `lib/features/timeline/timeline_screen.dart` — `_ListItem.nativeAd()` 타입 추가, 7번째마다 삽입

### 주의점 / 남은 작업

- **출시 전 필수**: `ad_ids.dart`, `AndroidManifest.xml`, `Info.plist`의 테스트 ID를 실제 AdMob ID로 교체
- **전면 광고 빈도**: `ad_service.dart`의 `_kInterstitialFrequency` (현재 `5`) 조정 가능
- **네이티브 광고 간격**: `timeline_screen.dart`의 `entryCount % 7` 값 조정 가능
- **iOS SKAdNetworkIdentifier**: 현재 AdMob 기본값 1개만 등록됨. 출시 전 AdMob 공식 문서의 전체 목록으로 교체 필요
- **삭제 미처리**: 기록 삭제 시 저장 횟수(`ad_save_count`)는 차감되지 않음 — 의도된 동작

---

## [2026-05-18] more_screen.dart 리팩토링

### 변경사항

- `_showThemePicker`의 인라인 바텀시트 빌더를 `_ThemePickerSheet` (`ConsumerWidget`)으로 분리
- `_themeModeLabel` 메서드를 top-level 함수로 이동 (양쪽 위젯에서 공유)

### 영향 받는 파일

- `lib/features/more/more_screen.dart`

### 주의점 / 남은 작업

- 없음
