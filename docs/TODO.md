# TODO — 추후 수정 사항

---

## 🚀 출시 전 체크리스트

> 우선순위 순 정렬. **1단계**를 모두 완료해야 심사 제출 가능.

### 1단계 — 빌드·심사 필수

- [x] **AdMob 광고 단위 ID 교체** (배너·전면·네이티브 6개) ← `secrets.json` 완료
- [ ] **AdMob App ID 교체** (앱 자체 ID — 광고 단위 ID와 다름)
  - Android: `android/local.properties`에 `admob.app.id=ca-app-pub-XXXXX~YYYYY` 추가
  - iOS: `ios/Flutter/Secrets.xcconfig`의 `ADMOB_APP_ID` 값 교체 (현재 플레이스홀더)
- [ ] **iOS SKAdNetworkIdentifier 목록 보완** ← `광고 (AdMob)` 섹션 참고
- [ ] **인앱 결제 상품 등록**
  - [ ] Google Play Console → 앱 내 상품 → `remove_ads` (비소비성, ₩2,900) 등록
  - [ ] App Store Connect → 인앱 구입 → `remove_ads` (비소비성, ₩2,900) 등록
- [x] **개인정보처리방침 앱 내 연결** — `secrets.json`의 `PRIVACY_POLICY_URL` (Notion URL) 완료
  - [ ] Google Play Console 스토어 등록 시 동일 URL 입력 필요
  - [ ] App Store Connect 스토어 등록 시 동일 URL 입력 필요
- [x] **앱 아이콘 · 스플래시 스크린 최종 확인**
  - Android: 512×512 PNG (Play Store 등록용) + 각 해상도 아이콘
  - iOS: 1024×1024 PNG (App Store 등록용)
- [x] **Android Keystore 서명 설정**
  - `android/key.properties` 생성 및 `android/app/build.gradle.kts` 서명 설정 완료
  - 키스토어 파일 분실 시 업데이트 영구 불가 → **안전한 곳에 백업 필수**
- [ ] **릴리즈 빌드 테스트**
  - `flutter build appbundle --release` (Android AAB)
  - `flutter build ipa --release` (iOS IPA)
  - 릴리즈 모드에서 광고·결제·DB 정상 동작 기기 테스트

### 2단계 — 스토어 제출 전

- [ ] **스토어 메타데이터 작성**
  - 앱 이름: 푸푸로그 / PooPooLog
  - 짧은 설명 (80자 이내, Android 전용)
  - 긴 설명 (최대 4,000자)
  - 스크린샷: Android 폰 2장 이상 / iOS 6.7인치 3장 이상
  - 피처드 이미지: 1024×500 PNG (Android 전용)
  - 카테고리: 건강 및 피트니스
  - 연령 등급 설문 완료 (Android) / 4+ 설정 (iOS)

### 3단계 — v1.1 목표

- [x] **타임라인 시작일 동적 계산** ← `버그 수정` 섹션 참고
- [x] **빈 상태 화면 개선** ← `UI 개선` 섹션 참고
- [ ] **알림 기능 구현 여부 확정** (현재 의존성 주석 처리 상태)
  - 구현 결정 시: 일일 리마인더 알림 + 권한 요청 플로우

---

## 버그 수정

- [x] 타임라인 시작일 하드코딩: loadMore() 상한이 2026-01-01로 고정 -> 앱 첫 설치 일 또는 DB 최초 기록일 기준으로 동적 계산 필요
- [x] 기록화면 데이터: 입력 중 화면 나갔다가 다시 들어왔을 때 이전 데이터가 있음. 화면 초기화 필요
- [x] 더보기 화면: 피드백 보내기 버튼 터치 시 무반응
- [x] 더보기 화면: 개인정보처리방침 버튼 터치 시 무반응


## 캘린더

- [x] **캘린더 높이 줄이기**: 위 마진 줄이기

---

## 기록

- [ ] 기록 화면 문구 이동: 오늘 이후 날짜는 선택할 수 없어요를 '지금' 버튼 오른쪽 영역으로 이동(오른쪽 마진 기준으로 정렬)
- [ ] 날짜 시간 입력칸 위에 마진 줄이기

---

## 타임라인

---

## 통계

- [ ] **연속 방문 스트릭**: "n일 연속 기록 중" 표시. 기록 습관 형성에 효과적. 필요 여부 생각 필요
- [x] 기분 분포 영역 줄이기
- [x] 시간대별 방문 텍스트가 너무 큼
- [x] **피크 시간대 요약 UI**: 히트맵 상단에 가장 많이 방문한 시간 카드 표시

---

## 더보기

- [x] **데이터 초기화 기능**: 확인 다이얼로그 후 전체 삭제 → 캘린더 탭으로 이동
- [x] **기분 표시 방식 설정**: 색상 도트 / 얼굴 아이콘 전환 구현 완료
  - `MoodDisplay` enum (`dot` / `face`), `moodDisplayProvider`, `MoodFacePainter`, `MoodIndicator` 구현
  - 적용 범위: 캘린더 도트, 타임라인·캘린더 카드, 통계 범례, 기록 입력 선택기
- [x] **데이터 내보내기**: CSV 내보내기 -> 가져오기 (Upsert 방식, 확인 다이얼로그 포함)
- [x] 오픈소스 라이선스 추가 필요
- [ ] 자동 등록 설정: +버튼 누르면 기본 값으로 자동 저장됨

---

## 광고 (AdMob)

- [x] **광고 단위 ID 교체**: 배너·전면·네이티브 6개 → `secrets.json` 완료
- [ ] **AdMob App ID 교체**: 광고 단위 ID와 별개의 앱 식별자 (출시 필수)
  - Android: `android/local.properties`에 `admob.app.id=ca-app-pub-XXXXX~YYYYY` 추가
  - iOS: `ios/Flutter/Secrets.xcconfig`의 `ADMOB_APP_ID` 값 교체
- [x] **전면 광고 빈도 조정**: 최초 10회 저장 시 첫 노출, 이후 7회마다 1회 (`ad_service.dart`)
- [x] **네이티브 광고 삽입 간격 조정**: 10번째 엔트리마다 1개 (`timeline_screen.dart`, `entryCount % 10 == 0`)
- [ ] **iOS SKAdNetworkIdentifier 목록 보완**: AdMob 공식 문서 기준 전체 목록으로 교체

---

## UI 개선

- [ ] **타임라인 리스트 디자인**: 시간 앞 vs 기분 앞. 선택 후 entry_card.dart 통일 적용
- [x] **빈 상태 화면 개선**: 캘린더 타임라인 통계 각각 다른 빈 상태 일러스트/메시지로 교체. 첫 방문 사용자 온보딩 역할
- [x] **기록 입력 CupertinoDatePicker 미래 시간 차단 UX**: "오늘 이후 날짜는 선택할 수 없어요" 안내 문구 추가 완료

---

## 리팩토링

- [x] `calendar_screen.dart`
- [x] `record_screen.dart` + `record_provider.dart`
- [x] `stats_screen.dart` + `stats_provider.dart`
- [x] `timeline_screen.dart` + `timeline_provider.dart` + 위젯 (`filter_chip_row`, `date_header`)
- [x] `app_shell.dart`
- [x] `more_screen.dart`
- [x] `calendar_provider.dart`
- [x] `entry_ext.dart` + `record_model.dart`
- [x] `shared/widgets/entry_card.dart`
- [x] 캘린더 위젯 (`mood_dot_row.dart`, `month_picker_sheet.dart`)
- [x] 통계 위젯 (`summary_card.dart`, `stat_heat_map_grid.dart`)
- [x] 테마 (`app_theme.dart`, `style.dart`)
- [x] 코어 (`main.dart`, `logger.dart`, `database_provider.dart`, `app_database.dart`)