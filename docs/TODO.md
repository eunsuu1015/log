# TODO — 추후 수정 사항

---

## 🚀 출시 전 체크리스트

> 우선순위 순 정렬. **1단계**를 모두 완료해야 심사 제출 가능.

### 1단계 — 빌드·심사 필수

- [x] **AdMob 광고 단위 ID 교체** (배너·전면·네이티브 6개) ← `secrets.json` 완료
- [x] **AdMob App ID 교체** (앱 자체 ID — 광고 단위 ID와 다름)
  - Android: `android/local.properties`에 `admob.app.id=ca-app-pub-XXXXX~YYYYY` 추가
  - iOS: `ios/Flutter/Secrets.xcconfig`의 `ADMOB_APP_ID` 값 교체 (현재 플레이스홀더)
- [ ] **iOS SKAdNetworkIdentifier 목록 보완** ← `광고 (AdMob)` 섹션 참고
- [ ] **인앱 결제 상품 등록**
  - [x] Google Play Console → 앱 내 상품 → `remove_ads` (비소비성, ₩2,900) 등록
  - [ ] App Store Connect → 인앱 구입 → `remove_ads` (비소비성, ₩2,900) 등록
- [x] **개인정보처리방침 앱 내 연결** — `secrets.json`의 `PRIVACY_POLICY_URL` (Notion URL) 완료
  - [ ] Google Play Console 스토어 등록 시 동일 URL 입력 필요
  - [x] App Store Connect 스토어 등록 시 동일 URL 입력 필요
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

- [x] **스토어 메타데이터 작성**
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

## 캘린더


---

## 기록


---

## 타임라인

---

## 통계


---

## 더보기

- [ ] 자동 등록 설정: +버튼 누르면 기본 값으로 자동 저장됨
- [ ] 폰트 변경
- [ ] 테마 색상 변경

---

## 광고 (AdMob)

- [x] **AdMob App ID 교체**: 광고 단위 ID와 별개의 앱 식별자 (출시 필수)
  - Android: `android/local.properties`에 `admob.app.id=ca-app-pub-XXXXX~YYYYY` 추가
  - iOS: `ios/Flutter/Secrets.xcconfig`의 `ADMOB_APP_ID` 값 교체
- [x] **전면 광고 빈도 조정**: 최초 10회 저장 시 첫 노출, 이후 7회마다 1회 (`ad_service.dart`). 이후에 5회로 변경 예정?
- [ ] **iOS SKAdNetworkIdentifier 목록 보완**: AdMob 공식 문서 기준 전체 목록으로 교체

---

## UI 개선



---

## 리팩토링
