# 배포 가이드

---

## 1. 배포 전 필수 확인

### secrets.json 준비
`secrets.json`은 `.gitignore`에 포함되어 git에 올라가지 않는다.  
배포 머신에 파일이 존재하는지 확인한다.


실제 값은 별도로 관리. 형식 참고는 `secrets.example.json` 사용.

### android/local.properties 확인
`local.properties`도 gitignore 대상이므로 배포 머신에 직접 설정해야 한다.

```properties
admob.app.id=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

미설정 시 `build.gradle.kts`의 테스트 App ID로 폴백되어 광고가 표시되지 않는다.

---

## 2. 빌드 명령

> `flutter build appbundle --release --dart-define-from-file=secrets.json` 없이 빌드하면 AdMob ID·피드백 URL·개인정보처리방침 URL이 모두 테스트값 또는 빈 문자열로 배포된다.

### Android (Play Store)
```bash
flutter build appbundle --dart-define-from-file=secrets.json
```
결과물: `build/app/outputs/bundle/release/app-release.aab`

### iOS (App Store)
```bash
flutter build ipa --dart-define-from-file=secrets.json
```
결과물: `build/ios/ipa/*.ipa`

---

## 3. 버전 관리

`pubspec.yaml`의 `version` 필드를 올린 뒤 빌드한다.

```yaml
version: 1.0.0+1
#        ^^^^^  ^
#        버전명  빌드 번호 (스토어에서 단조 증가 필요)
```

---

## 4. 스토어 제출 전 체크

- [ ] `pubspec.yaml` 버전·빌드 번호 증가 확인
- [x] `secrets.json` 실제 AdMob ID 입력 확인
- [x] `local.properties`에 `admob.app.id` 설정 확인
- [ ] `--dart-define-from-file=secrets.json` 포함 빌드 확인 (아래 둘 중 하나로 빌드해야함)
          - flutter build apk --dart-define-from-file=secrets.json
          - flutter build appbundle --dart-define-from-file=secrets.json
- [ ] 타임라인 admob 광고 확인 팝업 삭제
- [ ] 더보기 화면 > 앱 버전 > 테스트코드 삭제 
- [ ] `QA_CHECKLIST.md` 🔴 크리티컬 항목 전체 통과 확인

## 5. 배포 전 flag 값 확인 (lib/core/debug/debug_flags.dart)
- [ ] kDebugShowAdIds: true 처리
- [ ] kForceShowNotice: true 처리
- [ ] kAppVersionAddData: true 처리
- [ ] kDebugRemoteConfig: null 처리
