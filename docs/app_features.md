# PooPooLog — 화면별 기능 명세

> 폴더 구조·데이터 모델·Provider 목록은 [PROJECT.md](project.md) 참고.
> 아키텍처·데이터 흐름 상세는 [architecture_analysis.md](architecture_analysis.md) 참고.

---

## 목차

1. [캘린더 탭](#1-캘린더-탭)
2. [타임라인 탭](#2-타임라인-탭)
3. [통계 탭](#3-통계-탭)
4. [기록 입력·수정 화면](#4-기록-입력수정-화면)
5. [더보기 탭](#5-더보기-탭)
6. [온보딩](#6-온보딩)
7. [광고 (AdMob)](#7-광고-admob)
8. [Android 홈 화면 위젯](#8-android-홈-화면-위젯)
9. [앱 시작 시 처리 (Remote Config)](#9-앱-시작-시-처리-remote-config)

---

## 1. 캘린더 탭

**파일** `lib/features/calendar/calendar_screen.dart`

### 주요 기능

| 기능 | 설명 |
|------|------|
| 월간 달력 | `table_calendar`, 좌우 스와이프로 월 이동 |
| 기분 도트 | 기록 있는 날짜 아래 기분 색상 도트 (최대 5개, 초과 시 `+N`). 기분 표시 방식 설정과 무관하게 항상 색상 도트 표시 |
| 날짜 선택 | 기록 있음 → 하단 패널 표시 / 기록 없음 → 기록 입력 화면 이동 |
| 월 피커 | 헤더 탭 시 Cupertino 드럼롤 연·월 선택기. 최초 기록일 기준 minDate 제한 |
| 오늘 이동 | 현재 월이 아닐 때 AppBar에 "오늘로 돌아가기" 버튼 노출 |
| 기록 추가 | 우하단 FAB(+) 탭 → 기록 입력 화면 |
| 과거 경계 | 최초 기록일보다 이전 달을 스와이프로 넘어갈 경우 달력 대신 "푸푸로그를 시작하기 전이에요!" 안내 화면 표시 |

### 날짜 하단 패널 (`_DayPanel`)

선택된 날짜에 기록이 있을 때 표시.

- `"m월 d일"` 헤더 + **추가** 버튼
- 해당 날의 기록 목록 (`EntryCard` 리스트)
- 리스트 하단 80px 여백 (FAB에 가리지 않도록)
- 기록 탭 → 수정 화면으로 이동

### 하위 위젯

| 위젯 | 역할 |
|------|------|
| `MoodDotRow` | Entry 목록 → 기분 색상 도트 최대 5개, 초과 시 `+N` |
| `MonthPickerSheet` | CupertinoPicker 2개 (연도·월) |

---

## 2. 타임라인 탭

**파일** `lib/features/timeline/timeline_screen.dart`

### 주요 기능

| 기능 | 설명 |
|------|------|
| 전체 기록 | 최신순 정렬, 날짜별 그룹 |
| 날짜 헤더 | 모든 날짜 `"m월 d일 (요일)"` 형식 통일. 오늘은 Primary 컬러 + 좌측 수직 바로 강조 |
| 기분 필터 | 상단 칩 6개: 전체 / 좋음 / 보통 / 나쁨 / 다녀옴 / 안 감 |
| 기록 카드 | 기분 도트, 기분 레이블, 메모(2줄 요약), 시간 표시 |
| 네이티브 광고 | 누적 엔트리 수가 10의 배수인 위치에 광고 카드 삽입 |
| Pull-to-refresh | 아래로 당겨 새로고침 |
| 페이징 | 초기 최근 6개월 로드, 스크롤 끝에서 6개월씩 추가 |
| 빈 상태 | 기록 없음 / 필터 결과 없음 각각 다른 안내 메시지 |

### 하위 위젯

| 위젯 | 역할 |
|------|------|
| `FilterChipRow` | 기분 필터 칩 6개, `timelineFilterProvider` 읽기·쓰기 |
| `DateHeader` | 날짜 그룹 헤더, 오늘·어제 색상 강조 |
| `EntryCard` (`shared/widgets/`) | 기분 도트, 레이블, 메모(2줄), 시간 표시 |

---

## 3. 통계 탭

**파일** `lib/features/stats/stats_screen.dart`

### 기간 선택

| 옵션 | 설명 |
|------|------|
| 이번 달 | 1일 ~ 오늘 |
| 최근 30일 | 오늘 기준 30일 전 ~ 오늘 |
| 최근 90일 | 이번 달 포함 최근 3개월 |
| 직접 지정 | `DateRangePicker`로 시작·종료일 선택 |

### 요약 카드

- **방문한 날 수** — `"n일"` + `"n일 중 방문한 날"`
- **총 방문 횟수** — `"n회"` + `"n일 동안 방문 횟수"`

### 차트

| 차트 | 설명 |
|------|------|
| 기분 분포 도넛 차트 | 좋음·보통·나쁨 비율(%) 도넛. 우측에 기분별 횟수 범례 |
| 시간대별 히트맵 그리드 | 0~23시 24칸, 6열×4행. 비율 기반 4단계 초록 계열 색상 (≤25%→연→진). 최다 방문 셀에 primary 테두리 강조. 상단 피크 시간 요약 카드. 헤더에 범례·"자세히 보기 ↑" 버튼 포함 |

#### 시간대 자세히 보기 (DraggableScrollableSheet)

| 그룹 | 시간 범위 |
|------|-----------|
| 새벽 | 0 ~ 5시 |
| 아침 | 6 ~ 11시 |
| 오후 | 12 ~ 17시 |
| 저녁 | 18 ~ 23시 |

기록 있는 시간대만 표시. 최다 방문 시간대에 "최다" 뱃지.

- 기간 내 데이터 없으면 Ghost UI (흐릿한 더미 통계 + 잠금 배지 + "첫 기록 남기기" CTA)
- 기간 선택 후 데이터 없으면 `"이 기간에 기록이 없어요"` 표시
- 화면 하단에 배너 광고 고정

---

## 4. 기록 입력·수정 화면

**파일** `lib/features/record/record_screen.dart`

### 입력 필드

| 필드 | 위젯 | 설명 |
|------|------|------|
| 날짜·시간 | `CupertinoDatePicker` | iOS 드럼롤 휠, 미래 시간 불가, 최소 2026-05-01 |
| 방문 여부 | `SwitchListTile` | true/false 토글, null 없음, 초기값 true |
| 기분 | 버튼 3개 | 좋음·보통·나쁨, 재탭하면 null (선택 해제) |
| 메모 | `TextField` (4줄) | 자유 텍스트, 빈 문자열은 null로 저장 |
| 빠른 태그 | `ActionChip` 13개 | 카테고리별(상태·증상·식사·기타) 분류. 탭하면 메모에 추가 |

**빠른 태그 카테고리:**

| 카테고리 | 태그 |
|----------|------|
| 상태 | 쾌변·설사·묽음·딱딱함 |
| 증상 | 배아픔·잔변감·급했음·냄새 심함·냄새 없음 |
| 식사 | 식후·공복 |
| 기타 | 스트레스·운동 후 |

### 동작 규칙

- `visited = false`로 변경 시 `mood` 자동 null 초기화
- 기분 선택 시 `visited` 자동 true 설정
- `presetDate` 전달 시 해당 날짜·현재 시각으로 초기화
- 저장 완료 후 전면 광고 노출 (최초 10회 저장 시 첫 노출, 이후 7회마다 1회)

### 수정 모드

- 기존 `Entry` 데이터로 폼 초기화
- 하단에 **삭제** 버튼 추가 (확인 다이얼로그 포함)

---

## 5. 더보기 탭

**파일** `lib/features/more/more_screen.dart`

| 섹션 | 항목 | 설명 |
|------|------|------|
| 결제 | 광고 없애기 | ₩2,900 일회성 인앱 결제로 모든 광고 영구 제거. `adsRemovedProvider` → `shared_preferences` 저장. 구매 복원 지원 |
| 설정 | 다크모드 | 라이트 / 다크 / 기기 설정, `shared_preferences` 저장 |
| 설정 | 기분 표시 방식 | `SegmentedButton` — 색상 도트 / 얼굴 아이콘 전환. `moodDisplayProvider` → `shared_preferences` 저장. 캘린더·타임라인·통계·기록 입력 전 화면 즉시 반영 |
| 설정 | 주 시작 요일 | 달력 주 시작 요일 — 월요일 / 일요일. `startWeekdaySundayProvider` → `shared_preferences` 저장 |
| 지원 | 앱 가이드 | 온보딩 화면 재표시 (X 버튼으로 닫기, prefs 저장 없음) |
| 지원 | 피드백 보내기 | Google Forms 외부 링크 (`FEEDBACK_URL` dart-define 주입) |
| 정보 | 개인정보처리방침 | 외부 링크 (`PRIVACY_POLICY_URL` dart-define 주입) |
| 정보 | 오픈소스 라이선스 | `showLicensePage` |
| 정보 | 앱 버전 | 버전 표시 (5회 탭 시 테스트 데이터 생성 히든 기능) |
| 데이터 | 내보내기 (CSV) | 전체 기록을 CSV로 내보내기 (`share_plus`) |
| 데이터 | 가져오기 (CSV) | CSV 파일에서 기록 Upsert — 동일 `recordedAt` 있으면 덮어쓰고 없으면 추가. 확인 다이얼로그 포함. 헤더 컬럼명 기반 파싱으로 버전 호환 (`file_picker`) |
| 데이터 | 데이터 초기화 | 확인 다이얼로그 후 전체 삭제 → 선택 날짜·포커스 월 오늘 리셋 → 캘린더 탭으로 이동 |

### 히든 기능 — 테스트 데이터 생성

앱 버전 항목을 **5회 탭** 시 활성화.

- 2025년 10월 1일 ~ 오늘까지 매일 0~4개 랜덤 기록 삽입
- `visited`: true / false 랜덤 (UI 스펙 상 null 제외)
- `mood`: null 포함 4종 랜덤 (25% null / good / okay / bad)
- `memo`: null 또는 빠른태그 문구 중 랜덤 (25% null)
- 생성 중 로딩 다이얼로그 표시, 완료 후 SnackBar 알림

---

## 6. 온보딩

**파일** `lib/features/onboarding/onboarding_screen.dart`

앱 최초 실행 시 3장 슬라이드 화면을 표시한다. 완료 또는 건너뛰기 시 `SharedPreferences`에 완료 여부를 저장해 이후 미표시.

| 슬라이드 | 제목 | 내용 |
|----------|------|------|
| 1장 | 매일 기록하는 습관 | 기록 입력 카드 UI 미리보기 |
| 2장 | 기분 흐름을 한눈에 | 미니 캘린더 그리드 + 기분 도트 미리보기 |
| 3장 | 통계로 내 몸 이해 | 요약 카드 + 기분 도넛 차트 + 히트맵 미리보기 |

- "건너뛰기" 버튼 → 즉시 홈 화면
- "시작하기" 완료 → `kOnboardingSeenKey = true` 저장 후 홈 화면
- 더보기 > "앱 가이드" → 언제든 다시 볼 수 있음 (prefs 저장 없이 X 버튼으로 닫기만)

---

## 7. 광고 (AdMob)

> 현재 테스트 ID 사용 중. 출시 전 `lib/core/ads/ad_ids.dart`의 ID를 실제 AdMob ID로 교체 필요.
> `AndroidManifest.xml`의 `APPLICATION_ID`, `ios/Runner/Info.plist`의 `GADApplicationIdentifier`도 함께 교체.

| 광고 유형 | 위치 | 빈도 |
|-----------|------|------|
| 전면 (Interstitial) | 기록 저장 완료 후 | 최초 10회 저장 시 첫 노출, 이후 7회마다 1회 (`ad_save_count` SharedPreferences 카운트) |
| 배너 (Banner) | 통계 화면 하단 | 항상 표시 |
| 네이티브 (Native) | 타임라인 리스트 | 누적 엔트리 수가 10의 배수인 위치마다 삽입 |


---

## 8. Android 홈 화면 위젯

**파일** `android/.../widget/PooPooWidget.kt`, `lib/core/widget/home_widget_service.dart`

### 위젯 3종

| 크기 | dp | 표시 정보 |
|------|----|-----------|
| 1×1 | ~57×57 | 오늘 방문 횟수 + + 버튼 |
| 2×1 | ~120×57 | 오늘 방문 횟수 + 마지막 시각 + + 버튼 |
| 2×2 | ~120×120 | 오늘 방문 횟수 + 마지막 시각 + 마지막 기분 + 오늘 기분 도트 목록 + + 버튼 |

### 탭 액션

| 탭 위치 | 동작 |
|---------|------|
| 위젯 본체 | 앱 열기 (캘린더 탭) |
| + 버튼 | 기록 입력 화면 바로 열기 |

### 갱신 트리거

| 시점 | 처리 |
|------|------|
| 기록 저장·삭제 | `HomeWidgetService.update()` → `home_widget.updateWidget()` |
| 자정 | `AlarmManager.setRepeating` (매일 00:00, 비정확 허용) |
| 재부팅 | `BootReceiver` → `PooPooWidget.updateAll()` + 알람 재등록 |
| 주기 fallback | `updatePeriodMillis="1800000"` (30분) |

### 디자인

- 배경: `GlanceMaterialTheme` widgetBackground (라이트/다크 자동)
- 방문 횟수: `fontSize=26sp`, bold (1×1) / `22sp` bold (2×1, 2×2)
- 레이블: `fontSize=9~11sp`, onSurfaceVariant 색상
- + 버튼: 원형 32dp, primary 색상 배경
- 기분 도트: 원형 8dp, 기분 색상 (좋음 #3DA06C / 보통 #CC7D30 / 나쁨 #C64848 / 없음 #8CA896) — 앱 AppTheme과 동일
- + 버튼: 원형 32dp, #2D6A4F (AppColors.lightPrimary) 배경 — 앱 FAB과 동일
- cornerRadius: 16dp

---

## 9. 앱 시작 시 처리 (Remote Config)

**파일** `lib/core/remote_config/`, `lib/features/update/`, `lib/features/notice/`

### 처리 순서 (AppShell initState)

```
1. Remote Config fetch (app_config JSON)
2. 강제 업데이트 확인  ──→  필요 시 팝업 표시 후 이후 로직 중단
3. 홈 위젯 액션 확인
4. 공지사항 팝업 확인
```

### Remote Config 파라미터

| 키 | 타입 | 설명 |
|----|------|------|
| `app_config` | JSON | 공지·업데이트 통합 설정 |

```json
{
  "notice": {
    "id": "notice_001",
    "title": "공지 제목",
    "message": "공지 내용",
    "notice_date": "2026-05-23",
    "created_at": "2026-05-23",
    "show": 1
  },
  "android": {
    "latest_version": "1.0.0",
    "force_update": false,
    "show": 1
  },
  "ios": {
    "latest_version": "1.0.0",
    "force_update": false,
    "show": 1
  }
}
```

`show` 값의 의미:

| 값 | 동작 |
|----|------|
| `0` | 항상 노출 |
| `1` 이상 | 해당 횟수만큼만 노출 (앱 실행마다 SharedPreferences에 카운트 저장) |

### 강제 업데이트

| 조건 | 동작 |
|------|------|
| 현재 버전 ≥ `latest_version` | 팝업 미표시 |
| 현재 버전 < `latest_version` + `force_update: false` + `show >= 1` + 노출 횟수 소진 | 팝업 미표시 |
| 현재 버전 < `latest_version` + `force_update: false` | 확인(스토어 이동)/취소 선택 팝업 |
| 현재 버전 < `latest_version` + `force_update: true` | `show` 무관하게 항상 닫기 불가 팝업 표시 |
| Remote Config fetch 실패 | `AppConfig.fallback` 사용 (강제 업데이트 없음) |

- 버전 형식: `major.minor.patch` (예: `1.0.0`)
- 강제 업데이트 시 뒤로가기·다이얼로그 외부 탭 모두 차단 (`PopScope(canPop: false)`, `barrierDismissible: false`)
- 노출 횟수는 플랫폼+버전 조합 키(`update_show_count_{platform}_{version}`)로 저장, 버전이 바뀌면 새로 카운트

### 공지사항

| 조건 | 동작 |
|------|------|
| `notice.id` 비어 있음 | 공지 없음, 팝업 미표시 |
| 사용자가 '다시 보지 않음' 선택 | `SharedPreferences`에 id 저장, 이후 완전히 미표시 |
| `show >= 1` + 노출 횟수 소진 | 팝업 미표시 |
| `show == 0` | 항상 노출 ('다시 보지 않음' 선택 전까지) |
| `id` 변경 시 | '다시 보지 않음' 및 노출 카운트 모두 새로 시작 |

- 노출 횟수는 공지 ID 기반 키(`notice_show_count_{id}`)로 저장
