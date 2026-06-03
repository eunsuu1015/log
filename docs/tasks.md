# PooPooLog — Tasks

> AI 협업 작업 현황 관리 파일. 작업 시작 전 반드시 확인할 것.
> 마지막 갱신: 2026-05-28 (단위 테스트 완료 반영, flutter analyze 0 이슈 달성)

---

## 1단계: 인프라 및 기반 작업

### 프로젝트 초기 세팅
- [x] Flutter 프로젝트 생성 및 패키지 구성 (`pubspec.yaml`)
- [x] Android / iOS 기본 설정 (`AndroidManifest.xml`, `Info.plist`)
- [x] Material 3 테마 시스템 구축 (`app_theme.dart`, `style.dart`)
- [x] 라이트 / 다크 모드 지원 (SharedPreferences 저장)
- [x] 로거 유틸리티 구성 (`logger.dart`)

### 데이터베이스 (Drift / SQLite)
- [x] `Entries` 테이블 스키마 정의 (`app_database.dart`)
- [x] CRUD 메서드 구현 (`insertEntry`, `updateEntry`, `deleteEntry`, `deleteAllEntries`)
- [x] 기간 범위 쿼리 구현 (`getEntriesInRange`)
- [x] 월별 기록 Map 쿼리 구현 (`getEntriesForMonth`)
- [x] 백그라운드 DB 오픈 (`LazyDatabase + createInBackground`)
- [x] `insertEntry()` 에러 처리 강화 (`app_database.dart:92` — TODO 주석 있음)

### 도메인 모델 및 확장
- [x] `RecordModel` 불변 데이터 클래스 정의 (`record_model.dart`)
- [x] `MoodLevel` enum 정의 (good / okay / bad)
- [x] `Entry` ↔ `RecordModel` 변환 매퍼 구현 (`entry_ext.dart`)
- [x] 기분 색상·레이블·시간 포맷 확장 (`moodColor`, `timeStr` 등)

### 광고 (AdMob)
- [x] AdMob 초기화 (`main.dart`)
- [x] 광고 단위 ID 상수 파일 구성 (`ad_ids.dart`) — 현재 테스트 ID
- [x] 전면 광고 서비스 구현 — 7회 저장마다 1회 노출 (`ad_service.dart`)
- [x] 배너 광고 위젯 구현 (`banner_ad_widget.dart`)
- [x] 네이티브 광고 위젯 구현 (`native_ad_widget.dart`)
- [x] Android 네이티브 광고 팩토리 구현 (`ListTileNativeAdFactory.kt`)
- [x] iOS 네이티브 광고 팩토리 구현 (`ListTileNativeAdFactory.swift`)
- [x] 광고 제거 인앱 결제 구현 (`in_app_purchase`) — ₩2,900 일회성
  - `lib/core/iap/iap_provider.dart` 신규 — `adsRemovedProvider`, `PurchaseNotifier`
  - 배너·네이티브·전면 광고 모두 `adsRemovedProvider` 체크 후 숨김
  - 더보기 화면 최상단 `_RemoveAdsBanner` 위젯 — 구매/복원 UI
  - [ ] Google Play Console에 `remove_ads` 상품 등록 (출시 전)
  - [ ] App Store Connect에 `remove_ads` 상품 등록 (출시 전)
- [x] 광고 단위 ID 교체 (배너·전면·네이티브 Android·iOS 6개) — `secrets.json` 완료
- [ ] AdMob App ID 교체 (광고 단위 ID와 별개, 출시 필수)
  - Android: `android/local.properties` — `admob.app.id=ca-app-pub-XXXXX~YYYYY`
  - iOS: `ios/Flutter/Secrets.xcconfig` — `ADMOB_APP_ID` (현재 플레이스홀더)
- [ ] iOS `SKAdNetworkIdentifier` 목록 AdMob 공식 문서 기준으로 보완

---

## 2단계: 핵심 기능 개발

### 앱 쉘 / 네비게이션
- [x] 4탭 `NavigationBar` 구현 (캘린더·타임라인·통계·더보기)
- [x] `IndexedStack` 기반 탭 상태 유지
- [x] `app_shell.dart` 리팩토링 (코드 정리)
- [x] 앱 시작 시 처리 순서 확정: 강제 업데이트 → 홈 위젯 액션 → 공지사항 팝업

### 기록 입력 (RecordScreen)
- [x] 신규 기록 저장 / 기존 기록 수정 공용 화면
- [x] `CupertinoDatePicker`로 날짜·시간 선택
- [x] 방문 여부 토글 (`visited`)
- [x] 기분 선택 (좋음 / 보통 / 나쁨)
- [x] 메모 입력
- [x] 미래 시간 선택 차단 처리
- [x] 저장 후 `monthlyEntriesProvider` / `timelineProvider` 자동 갱신
- [x] 기록 삭제 기능
- [x] 미래 시간 선택 시 사용자 안내 UX 개선 (토스트 또는 안내 문구)

### 캘린더 (CalendarScreen)
- [x] `table_calendar` 기반 월간 캘린더 표시
- [x] 날짜별 기분 도트 표시 (`mood_dot_row.dart`)
- [x] 날짜 선택 시 하단 시트로 당일 기록 목록 표시
- [x] 월 이동 (이전·다음 달 버튼)
- [x] 월 선택 바텀시트 (`month_picker_sheet.dart`)
- [x] 플로팅 버튼이 리스트에 가리지 않도록 하단 여백 추가
- [x] `calendar_provider.dart` 리팩토링
- [x] `mood_dot_row.dart` 리팩토링
- [x] `month_picker_sheet.dart` 리팩토링

### 타임라인 (TimelineScreen)
- [x] 날짜별 그룹 리스트 표시 (`DayGroup`)
- [x] 날짜 헤더 상대 표시 ("오늘", "어제" + 실제 날짜 병기)
- [x] 기분 / 방문 여부 필터 칩 (`filter_chip_row.dart`)
- [x] 초기 6개월 로드 + `loadMore()`로 6개월씩 확장
- [x] 타임라인 중간 네이티브 광고 삽입 (7번째 엔트리마다)
- [x] 엔트리 카드 터치 시 수정 화면 이동
- [x] 빈 상태 화면 스타일 개선 (`timeline_screen.dart:239,244` — TODO 주석)
- [x] `entry_card.dart` 타임라인 디자인 확정 (기분 앞)
- [ ] 타임라인 시작일 하드코딩 제거 — `2026-01-01` → 앱 최초 기록일 기준 동적 계산

### 통계 (StatsScreen)
- [x] 기간 선택 칩 (이번 달 / 최근 30일 / 최근 90일 / 직접 지정)
- [x] 직접 지정 — `DateRangePicker` 연동
- [x] 요약 카드 (방문한 날 수 + 총 방문 횟수)
- [x] 기분 분포 도넛 차트 (`fl_chart`)
- [x] 시간대별 히트맵 그리드 (24칸) — 최대 횟수 대비 비율 기반 색상
- [x] 하단 배너 광고 삽입
- [x] 빈 상태 텍스트 스타일 추가 (`stats_screen.dart:40` — TODO 주석)
- [ ] 연속 방문 스트릭 표시 ("n일 연속 기록 중") — 필요 여부 검토 후 구현

### 더보기 (MoreScreen)
- [x] 테마 모드 설정 UI (라이트 / 다크 / 기기설정)
- [x] 앱 버전 표시 (`package_info_plus`)
- [x] 피드백 링크 (Google Forms)
- [x] 오픈소스 라이선스 화면
- [x] 데이터 전체 초기화 (확인 다이얼로그 → 삭제 → 캘린더 탭 이동)
- [x] 히든 기능: 버전 5회 탭 시 테스트 데이터 생성
- [x] 기분 표시 방식 설정 — 색상 도트 vs 얼굴 아이콘 전환
  - `MoodDisplay` enum (`dot` / `face`), `moodDisplayProvider`, `loadMoodDisplay()` / `saveMoodDisplay()`
  - `MoodFacePainter` (CustomPainter) + `MoodIndicator` (통합 위젯)
  - 적용 범위: 캘린더 도트, 타임라인·캘린더 카드, 통계 범례, 기록 입력 선택기
  - 설정 UI: `SegmentedButton` 인라인 (바텀시트 → 인라인 전환)
- [x] 캘린더 시작 요일 설정 (월요일 / 일요일)
- [x] 데이터 내보내기 / 가져오기 (CSV)

### 공용 위젯
- [x] `entry_card.dart` — 기분 색상, 레이블, 메모, 시간 표시
- [x] `new_user_empty_state.dart` — 기록 0건 신규 유저 빈 상태 위젯 (타임라인·통계 공용)
- [ ] `entry_card.dart` 리팩토링 및 디자인 확정
- [x] 빈 상태 화면 일러스트·메시지 교체 — `new_user_empty_state.dart` 공용 위젯 구현 (타임라인·통계 공용)
  - 첫 방문 사용자 온보딩 역할 겸용

### 온보딩 및 공지사항
- [x] 온보딩 슬라이드에 실제 UI 미리보기 위젯 추가 (기록·캘린더·통계)
- [x] 앱 시작 시 공지사항 팝업 표시 기능 구현 (확인 / 다시 보지 않음)
  - `lib/core/notice/notice.dart` — 공지 모델·현재 공지 상수 관리
  - `lib/features/notice/notice_dialog.dart` — 팝업 다이얼로그
  - `lib/features/shell/app_shell.dart` — `_checkAndShowNotice()` 연동
- [x] 공지사항 팝업 배경 터치로 닫히지 않도록 처리 (`barrierDismissible: false`)
- [x] `kForceShowNotice` 플래그 — `true`이면 '다시 보지 않음' 무시하고 항상 표시 (테스트용, 현재 `false`)
- [x] 공지사항 Firebase Remote Config 연동 — `_checkAndShowNotice(config)`에서 `AppConfig.notice` 사용 중
- [x] Remote Config JSON `show` 필드 지원 — 공지·업데이트 팝업 노출 횟수 제어
  - `show == 0`: 항상 노출, `show >= 1`: 해당 횟수만큼만 노출 (SharedPreferences 카운트)
  - 공지: "다시 보지 않음" 선택 시 이후 노출 안 함 (기존 로직 유지)
  - 업데이트: `force_update == true`이면 `show` 무관하게 항상 노출

### Firebase Remote Config
- [x] Remote Config `app_config` JSON 구조 확정 (notice + update 통합)
- [x] Firebase Remote Config fetch 서비스 구현 (`remote_config_service.dart`)
  - fetch 실패 시 `AppConfig.fallback` 폴백 처리
  - 네트워크 없을 때: 캐시 있으면 캐시 사용, 없으면 fallback 반환
- [x] Remote Config fetch 전후 로그 추가 (`remote_config_service.dart`)
  - 요청 시작 / fetchAndActivate 결과(`activated` 여부) / 수신 JSON / 파싱 요약 / 실패 시 경고 로그
- [x] 강제 업데이트 기능 구현 (`force_update_dialog.dart`)
  - `force_update: true` + 현재 버전 < `latest_version`이면 닫기 불가 팝업 표시
  - `barrierDismissible: false` + `PopScope(canPop: false)` 이중 차단
  - 확인 버튼 → 플랫폼별 스토어 이동 (`url_launcher`)
  - 강제 업데이트 발생 시 이후 로직(공지, 위젯 액션) 중단
- [x] Android Gradle에 Google Services 플러그인 추가
  - `settings.gradle.kts` — `com.google.gms.google-services` 버전 선언
  - `android/app/build.gradle.kts` — 플러그인 적용
- [ ] Firebase 콘솔 앱 등록 및 설정 파일 추가 (출시 전)
  - `google-services.json` (Android) → `android/app/` 경로에 배치
  - `GoogleService-Info.plist` (iOS) → `ios/Runner/` 경로에 배치
- [ ] `force_update_dialog.dart`의 iOS App Store ID 교체 (출시 전)
  - `_kIosStoreUrl` 상수에 실제 App Store Connect ID 입력
- [x] 공지사항 Remote Config 연동 — `AppConfig.notice`로 팝업 표시 완료 (온보딩 섹션 참고)
- [x] Remote Config JSON 구조 변경 대응 — `show` 필드 추가 및 노출 횟수 로직 구현

### Android 홈 화면 위젯
- [x] `HomeWidgetService` 구현 (`lib/core/widget/home_widget_service.dart`)
  - 오늘 방문 횟수·마지막 시간·기분 레이블·기분 색상·도트 목록·날짜 라벨 계산
  - `HomeWidget.saveWidgetData()` + `HomeWidget.updateWidget()` 로 Android 위젯 갱신
- [x] 기록 저장·삭제 후 홈 위젯 자동 갱신 연동 (fire-and-forget)
- [x] 홈 위젯에서 앱 진입 시 'record' 액션 처리 (`_handleWidgetAction()` — `app_shell.dart`)
  - `MethodChannel`로 초기 액션 수신 → 기록 화면 push → 타임라인·캘린더 자동 갱신
- [ ] iOS 홈 화면 위젯 지원 (현재 Android 전용)

### 알림 (Push Notification)
- [ ] 알림 기능 구현 여부 확정 (현재 의존성 주석 처리 상태)
  - `flutter_local_notifications`, `timezone`, `permission_handler` 주석 처리됨
- [ ] 구현 결정 시: 일일 리마인더 알림 구현
- [ ] 구현 결정 시: 알림 권한 요청 플로우

### 리팩토링
- [x] `calendar_screen.dart`
- [x] `record_screen.dart` + `record_provider.dart`
- [x] `stats_screen.dart` + `stats_provider.dart`
- [x] `timeline_screen.dart` + `timeline_provider.dart` + 관련 위젯
- [x] `more_screen.dart`
- [x] `app_shell.dart` — 변경 불필요 (이미 정리됨)
- [x] `calendar_provider.dart` — 변경 불필요 (이미 정리됨)
- [x] `entry_ext.dart` + `record_model.dart`
- [x] `shared/widgets/entry_card.dart`
- [x] 캘린더 위젯 (`mood_dot_row.dart`, `month_picker_sheet.dart`)
- [x] 통계 위젯 (`summary_card.dart`, `stat_heat_map_grid.dart`)
- [x] 테마 (`app_theme.dart`, `style.dart`)
- [x] 코어 (`main.dart`, `logger.dart`, `database_provider.dart`, `app_database.dart`)

---

## 3단계: 테스트 및 안정화

### 단위 테스트
- [x] `RecordModel` 변환 로직 테스트 (`record_model.dart`) — copyWith sentinel 패턴·==·hashCode 12개
- [x] `EntryMapper` / `RecordModelMapper` 확장 테스트 (`entry_ext.dart`) — EntryX·MoodLevelX 18개
- [x] `StatsResult` 집계 로직 테스트 (`stats_provider.dart`) — fromEntries() 집계 21개
- [ ] 타임라인 필터·그룹화 로직 테스트 (`timeline_provider.dart`)

### 통합 테스트
- [ ] DB CRUD 통합 테스트 (실제 SQLite, 모킹 금지)
- [ ] 기록 저장 후 캘린더·타임라인 자동 갱신 플로우 테스트

### 예외 처리 및 안정화
- [ ] `insertEntry()` 에러 처리 구체화 (현재 TODO 주석만 있음)
- [ ] 광고 로드 실패 시 폴백 처리 확인
- [ ] 타임라인 `loadMore()` 경계값 처리 검토 (앱 시작일 초과 방지)
- [ ] 대용량 데이터(1000건+) 성능 테스트

### 출시 전 최종 체크
- [ ] AdMob 실제 ID 교체 (1단계 항목과 동일)
- [ ] iOS App Store / Android Play Store 메타데이터 작성
- [ ] 개인정보처리방침 URL 연결
- [ ] 앱 아이콘 및 스플래시 스크린 최종 확인
- [x] `flutter analyze` 경고 0개 달성
- [ ] 릴리즈 빌드 테스트 (Android AAB, iOS IPA)
