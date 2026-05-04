# SETUP_GUIDE.md — 알림 & 홈 위젯 설정 가이드

---

## 1. 기본 셋업

```bash
bash setup.sh   # flutter pub get + flutter gen-l10n
```

---

## 2. Android 알림 설정

`flutter pub get` 이후 추가 작업 없음.
`AndroidManifest.xml`에 권한이 이미 포함되어 있습니다.

```
POST_NOTIFICATIONS     → 알림 표시
SCHEDULE_EXACT_ALARM   → 정확한 시간 알림
RECEIVE_BOOT_COMPLETED → 재부팅 후 알림 복원
```

---

## 3. iOS 알림 설정

Xcode에서 **Runner 타겟 → Signing & Capabilities → + Capability → Push Notifications** 추가.

> 시뮬레이터에서는 알림이 동작하지 않습니다. 실기기 테스트 필요.

---

## 4. Android 홈 화면 위젯

`flutter pub get` 이후 추가 작업 없음.
위젯은 홈 화면 길게 누르기 → 위젯 메뉴에서 "기록" 앱을 찾아 추가합니다.

---

## 5. iOS 홈 화면 위젯 (WidgetKit)

### 5-1. xcodeproj gem 설치 & 타겟 자동 추가

```bash
gem install xcodeproj
cd ios
ruby ../add_widget_target.rb
cd ..
```

### 5-2. App Group 설정 (Xcode에서 수동)

1. **Xcode** 열기: `open ios/Runner.xcworkspace`
2. **Runner 타겟** 선택 → **Signing & Capabilities**
3. **+ Capability** → **App Groups** 추가
4. App Group ID: `group.com.example.toiletTracker`
5. **ToiletTrackerWidget 타겟**도 동일하게 반복

### 5-3. Bundle ID 확인

| 타겟 | Bundle ID |
|------|-----------|
| Runner | `com.example.toiletTracker` |
| ToiletTrackerWidget | `com.example.toiletTracker.widget` |

### 5-4. CocoaPods 재설치

```bash
cd ios && pod install && cd ..
```

### 5-5. 실행

```bash
flutter run -d ios
```

위젯 미리보기는 Xcode → **ToiletTrackerWidget** 스킴 선택 후 시뮬레이터 실행.

---

## 6. 앱 내 알림 설정 위치

**캘린더 화면** → 우측 상단 ⚙️ 아이콘 → **알림 설정**

- 토글로 알림 ON/OFF
- 시간 탭으로 알림 시각 변경

---

## 7. 홈 위젯에 표시되는 데이터

| 항목 | 설명 |
|------|------|
| 오늘 방문 횟수 | 오늘 `visited = true` 기록 수 |
| 마지막 기분 | 오늘 마지막 기록의 기분 이모지 |
| 마지막 시각 | 오늘 마지막 기록의 시각 |

기록을 저장하면 위젯이 자동으로 갱신됩니다.
iOS 위젯은 WidgetKit 정책상 최대 30분 간격으로 갱신됩니다.
