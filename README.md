# PooPooLog

화장실 방문 여부·기분·메모를 기록하고 캘린더·타임라인·통계로 시각화하는 개인 건강 기록 앱 (Flutter).

---

## 주요 기능

- **캘린더**: 월간 달력에서 날짜별 기분 도트 확인, 날짜 탭으로 기록 조회·추가
- **타임라인**: 전체 기록 최신순 + 날짜 그룹 표시, 기분 필터, 페이징 (6개월씩)
- **통계**: 기분 분포 차트·시간대별 방문 수 차트, 기간 선택 (이번 달 / 30일 / 3개월 / 직접 지정)
- **더보기**: 다크모드 설정, 피드백, 데이터 초기화

---

## 기술 스택

| 역할 | 라이브러리 |
|------|-----------|
| 상태 관리 | `flutter_riverpod ^2.5.1` |
| 데이터베이스 | `drift ^2.18.0` (SQLite ORM) |
| 캘린더 UI | `table_calendar ^3.1.2` |
| 차트 | `fl_chart ^0.68.0` |
| 광고 | `google_mobile_ads ^5.1.0` |
| 설정 저장 | `shared_preferences ^2.3.0` |
| 원격 설정 | `firebase_core ^3.13.1`, `firebase_remote_config ^5.4.4` |

---

## 빌드 및 실행

```bash
flutter pub get
flutter run
```

Drift 스키마 변경 시:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 프로젝트 문서

| 파일                                                             | 내용 |
|----------------------------------------------------------------|------|
| [PROJECT.md](docs/project.md)                                  | 폴더 구조, 데이터 모델, 상태 관리, 테마 색상 |
| [docs/app_features.md](docs/app_features.md)                   | 화면별 기능 상세 명세 |
| [docs/architecture_analysis.md](docs/architecture_analysis.md) | 아키텍처, Provider 의존 관계, 데이터 흐름 |
| [tasks.md](docs/tasks.md)                                      | AI 협업 작업 현황 (단계별 완료·미완료 추적) |
| [docs/TODO.md](docs/TODO.md)                                   | 미완성 작업 목록 |
| [docs/changelog.md](docs/changelog.md)                         | 작업 변경 이력 |
