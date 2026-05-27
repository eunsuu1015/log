# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**PooPooLog** — 화장실 방문 여부, 기분, 메모를 기록하고 캘린더·타임라인·통계로 시각화하는 개인 건강 기록 앱 (Flutter).

## 빌드 및 실행 명령어

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# Drift 스키마 변경 시 코드 재생성
dart run build_runner build --delete-conflicting-outputs

# 린트 검사
flutter analyze

# 테스트 실행
flutter test

# 특정 테스트 파일만 실행
flutter test test/some_test.dart
```

## 아키텍처

### 상태 관리: Riverpod

모든 상태는 Riverpod Provider로 관리한다. 주요 Provider:

| Provider | 위치 | 역할 |
|----------|------|------|
| `appDatabaseProvider` | `core/database/database_provider.dart` | 싱글턴 DB 인스턴스 |
| `calendarFocusedMonthProvider` | `features/calendar/calendar_provider.dart` | 현재 보고 있는 달 |
| `monthlyEntriesProvider` | `features/calendar/calendar_provider.dart` | 달별 기록 Map |
| `timelineFilterProvider` | `features/timeline/timeline_provider.dart` | 필터 상태 |
| `timelineProvider` | `features/timeline/timeline_provider.dart` | 필터링·그룹화된 DayGroup 리스트 (`AsyncNotifier`) |
| `recordFormProvider` | `features/record/record_provider.dart` | 기록 입력·수정 폼 상태 |
| `statsRangeProvider` | `features/stats/stats_provider.dart` | 통계 조회 기간 설정 |
| `statsResultProvider` | `features/stats/stats_provider.dart` | 집계 결과 (`FutureProvider`) |
| `themeModeProvider` | `shared/theme/app_theme.dart` | 라이트·다크 테마 설정 |

### 데이터 흐름

```
RecordScreen에서 저장
    → DB insert / update
    → monthlyEntriesProvider invalidate  →  캘린더 자동 갱신
    → timelineProvider invalidate        →  타임라인 자동 갱신
```

### 데이터베이스: Drift (SQLite ORM)

- DB 정의: `lib/core/database/app_database.dart`
- 코드 생성 결과 (수정 금지): `lib/core/database/app_database.g.dart`
- DB 파일명: `poopoolog.sqlite` (앱 문서 디렉토리)
- `Entry` (Drift Row) ↔ `RecordModel` (도메인 값 객체) 변환은 `EntryMapper` / `RecordModelMapper` 확장에서 처리

**Entries 테이블 주요 컬럼:**
- `recordedAt`: 사용자가 지정한 시간
- `visited`: 방문 여부 (null 가능)
- `mood`: 0=좋음, 1=보통, 2=나쁨 (null 가능)
- `memo`: 메모 (null 가능)

### 공통 확장 (`lib/core/extensions/entry_ext.dart`)

기분 색상·레이블·시간 포맷 변환 로직이 통합되어 있다. 새 위젯에서 기분 관련 표시가 필요하면 이 확장을 사용한다.

```dart
MoodLevel.good.color   // AppTheme.moodGood
entry.moodColor        // visited·mood 조합 → 표시 색상
entry.timeStr          // recordedAt → "HH:mm"
```

### 광고 (AdMob)

- 광고 단위 ID: `lib/core/ads/ad_ids.dart` — 현재 **테스트 ID** 사용 중, 출시 전 실제 ID로 교체 필요
- AndroidManifest.xml의 `APPLICATION_ID`와 ios/Runner/Info.plist의 `GADApplicationIdentifier`도 함께 교체
- 전면 광고: 5회 저장마다 1회 (`AdService._kInterstitialFrequency`)
- 네이티브 광고: 타임라인 7번째 엔트리마다 삽입

### 테마 색상

| 상수 | 색상 | 용도 |
|------|------|------|
| `AppTheme.moodGood` | `#3DA06C` (맑은 숲 초록) | 좋음 |
| `AppTheme.moodOkay` | `#CC7D30` (따뜻한 앰버) | 보통 |
| `AppTheme.moodBad` | `#C64848` (차분한 로즈 레드) | 나쁨 |
| `AppTheme.moodNone` | `#8CA896` (그레이 그린 뉴트럴) | 안 감 / 미입력 |

Material 3 기반, 라이트·다크 테마 모두 지원. 테마 모드는 `shared_preferences`에 저장.

## 주요 규칙 및 패턴

- **언어**: UI 텍스트와 날짜 포맷은 모두 `ko_KR` 기준
- **타임라인 페이징**: 초기 로드 최근 6개월, `loadMore()`로 6개월씩 확장. 앱 시작일은 `2026-01-01`로 고정
- **DB 쿼리**: `getEntriesInRange(from, to)` — from 이상 to 미만 범위 (exclusive end)
- **기록 삽입 시 ID**: `RecordModel.id == 0`이면 신규 삽입, 아니면 수정


## 작업 시작 프로토콜 (Session Start)
- 사용자가 새로운 작업을 지시하면, 코드를 짜기 전에 먼저 `@tasks.md` 파일을 읽고 현재 진행 상황과 충돌이 없는지 확인할 것.
- 작업 시작 전, 준비 완료 상태와 함께 현재 진행할 태스크를 사용자에게 명확히 확인받고 시작할 것.

## 작업 완료 프로토콜 (Session End)
- 모든 함수와 메서드를 신규 구현하거나 기존 코드를 수정할 때는 **반드시 함수/메서드 선언부 바로 위에 기능 설명을 자바스크립트/Dart 표준 문서화 주석 형식으로 작성**해야 합니다. 이는 AI와 개발자 간의 명확한 의도 공유를 위함입니다.
  - 이 함수/메서드가 왜 존재하고 무슨 기능을 하는지 한 줄 요약
- 하나의 기능 구현이나 버그 수정이 성공적으로 완료되면, 사용자가 요청하지 않아도 자동으로 다음 문서 업데이트를 수행하거나 제안해야 함.

1. `@tasks.md` 파일에서 방금 완료한 항목을 `[x]`로 변경.
2. `@CHANGELOG.md` 파일 맨 위에 오늘 날짜와 함께 변경 사항을 누적 기록.
3. 작업 성격에 따라 아래 해당하는 문서만 선택적으로 업데이트:

   | 작업 유형 | 업데이트 대상 |
      |-----------|--------------|
   | DB 스키마 변경 (테이블·컬럼 추가·수정) | `PROJECT.md`, `architecture_analysis.md` |
   | Provider 추가·삭제·구조 변경 | `architecture_analysis.md` |
   | 새 화면·기능 추가 또는 기존 기능 제거·변경 | `app_features.md` |
   | 폴더 구조 변경 (파일 추가·이동·삭제) | `PROJECT.md` |
   | 기술 스택·의존성 변경 (pubspec 등) | `README.md` |
   | 버그 수정, UI 개선, 텍스트 변경 등 | 해당 없음 (CHANGELOG만 기록) |

4. 하나의 기능 구현이나 버그 수정이 완료되면 다음 단계를 순서대로 수행할 것:
    1) 관련 비즈니스 로직에 대한 **단위 테스트(Unit Test) 코드**를 자동으로 작성하거나 기존 테스트 코드를 업데이트할 것.
    2) 안드로이드 스튜디오 터미널 환경을 이용할 수 있다면, 실제 테스트 명령어(예: `flutter test` 등)를 실행하여 `ALL TESTS PASSED`를 직접 확인할 것.
    3) 만약 환경 제한으로 직접 실행이 불가능하다면, 사용자에게 "테스트 코드를 작성했으니 검증을 위해 한 번 실행해 주세요"라고 요청할 것.
    4) 테스트가 통과되면 `@tasks.md`와 `@CHANGELOG.md`를 양식에 맞춰 업데이트할 것.
  
### CHANGELOG 기록 양식:
```markdown
### [YYYY-MM-DD] 작업 요약
- **변경 사항:** (코드가 아닌 내용 위주로 작성)
  - (예: AdMob ID 및 피드백 URL 등 소스코드 내 민감 정보를 외부 환경 변수로 분리)
  - (예: 보안을 위해 secrets.json 및 xcconfig 파일을 생성하고 gitignore에 등록)
- **영향받는 파일:**
  - 변경된 파일과 변경 내용 간단하게 작성
  - 신규 생성 - lib/core/ads/ad_ids.dart — 플랫폼별 광고 단위 ID
  - 수정 - pubspec.yaml — google_mobile_ads: ^5.1.0 추가
- **특이사항 및 남은 작업:**
  - (예: secrets.json 없이 실행 시 테스트 ID로 자동 폴백됨 / 추후 배포 파이프라인 환경 변수 세팅 필요)