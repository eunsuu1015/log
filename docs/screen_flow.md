# 화면별 플로우

---

## 1. 앱 실행 플로우

```
[스플래시] (네이티브 — flutter_native_splash)
    │
    ▼
[main.dart 초기화]
    Firebase.initializeApp()
    MobileAds.initialize() + AdService.preload()
    SharedPreferences 로드
      ├─ 테마 모드
      ├─ 기분 표시 방식 (dot / face)
      ├─ 주 시작 요일
      ├─ 광고 제거 여부
      └─ 온보딩 완료 여부
    │
    ├─ 온보딩 미완료 ──► [온보딩 화면]
    │                        └─ 완료 / 건너뛰기 ──► [AppShell]
    │
    └─ 온보딩 완료 ───► [AppShell]
                            │
                            └─ initState (postFrameCallback)
                                  │
                                  ▼
                            [업데이트 확인]
                            Remote Config fetch
                              ├─ 현재 버전 ≥ latest_version → 통과
                              ├─ 낮음 + force=false + show 횟수 소진 → 통과
                              ├─ 낮음 + force=false → 확인/취소 팝업 → 통과 (노출 횟수 +1)
                              └─ 낮음 + force=true  → 강제 팝업 (show 무관) → 이후 중단
                                  │ 통과
                                  ▼
                            [홈 위젯 액션 감지]
                              ├─ open_record 인텐트 → [기록 화면]
                              └─ 없음 → 통과
                                  │
                                  ▼
                            [공지사항 팝업]
                              ├─ notice.id 없음 → 스킵
                              ├─ '다시 보지 않음' 선택한 id → 스킵
                              ├─ show >= 1 + 노출 횟수 소진 → 스킵
                              └─ 표시 조건 충족 → 팝업 표시 (노출 횟수 +1)
```

---

## 2. 온보딩 화면

```
[온보딩 화면]
    │
    ├─ 건너뛰기 버튼 탭
    │     └─ SharedPreferences onboarding_seen = true
    │           └─► [AppShell] (fade 전환)
    │
    ├─ 다음 버튼 탭 (1→2→3 슬라이드)
    │
    └─ 시작하기 버튼 탭 (마지막 슬라이드)
          └─ SharedPreferences onboarding_seen = true
                └─► [AppShell] (fade 전환)

※ 더보기 > 앱 가이드에서 열면 (fromSettings=true)
    └─ X 버튼으로 닫기만 가능 (prefs 저장 없음)
```

---

## 3. 캘린더 화면

```
[캘린더 화면]
    │
    ├─ 월 헤더 탭
    │     └─► [월 선택 피커 바텀시트]
    │               └─ 월 선택 → 해당 월로 이동
    │
    ├─ 좌우 스와이프
    │     └─ 이전/다음 달 이동
    │           └─ focusedMonth 변경 → monthlyEntriesProvider 갱신
    │
    ├─ 날짜 탭
    │     ├─ 기록 없는 날 (과거/오늘) → [기록 화면] (해당 날짜 프리셋)
    │     ├─ 기록 있는 날 → 하단 DayPanel 표시
    │     └─ 미래 날짜 → DayPanel 없음 (탭 무반응)
    │
    ├─ DayPanel
    │     ├─ 추가 버튼 → [기록 화면] (해당 날짜 프리셋)
    │     └─ EntryCard 탭 → [기록 화면] (수정 모드)
    │
    ├─ FAB (+) 탭
    │     └─► [기록 화면] (날짜 프리셋 없음)
    │
    └─ 오늘 버튼 (다른 달 보는 중)
          └─ 오늘 날짜 달로 이동 + 오늘 날짜 선택

[기록 화면] 닫힌 후
    └─ monthlyEntriesProvider, timelineProvider, earliestEntryDateProvider invalidate
```

---

## 4. 타임라인 화면

```
[타임라인 화면]
    │
    ├─ 필터 칩 탭 (전체 / 좋음 / 보통 / 나쁨 / 다녀옴 / 안 감)
    │     └─ timelineFilterProvider 변경 → 리스트 갱신
    │
    ├─ 리스트 스크롤 끝 도달
    │     └─ loadMore() → 6개월씩 확장
    │
    ├─ 아래로 당기기 (RefreshIndicator)
    │     └─ timelineProvider, earliestEntryDateProvider invalidate
    │
    ├─ EntryCard 탭
    │     └─► [기록 화면] (수정 모드)
    │
    ├─ FAB (+) 탭
    │     └─► [기록 화면] (신규)
    │
    ├─ 기록 없음 (신규 유저)
    │     └─ "첫 기록 남기기" 버튼 → [기록 화면]
    │
    └─ 기록 없음 (필터 결과 없음)
          └─ 안내 문구만 표시

[기록 화면] 닫힌 후
    └─ timelineProvider, monthlyEntriesProvider, statsResultProvider,
       earliestEntryDateProvider invalidate
```

---

## 5. 통계 화면

```
[통계 화면]
    │
    ├─ 기간 칩 탭 (이번 달 / 최근 30일 / 최근 90일 / 직접 지정)
    │     ├─ 이번 달·최근 30일·최근 90일 → statsRangeProvider 변경
    │     └─ 직접 지정 → 날짜 범위 피커 → statsRangeProvider 변경
    │
    ├─ 시간대별 방문 히트맵 "자세히 보기"
    │     └─► [시간대 바 차트 바텀시트]
    │
    ├─ 기록 없음 (신규 유저, Ghost UI)
    │     └─ "첫 기록 남기기" 버튼 → [기록 화면]
    │           └─ 닫힌 후 → statsResultProvider, earliestEntryDateProvider,
    │                         monthlyEntriesProvider, timelineProvider invalidate
    │
    └─ 기록 없음 (기간 내 기록 없음)
          └─ 안내 문구만 표시
```

---

## 6. 기록 화면

```
[기록 화면]
    │
    ├─ 모드 구분
    │     ├─ 신규 (existingEntry == null) → 빈 폼
    │     └─ 수정 (existingEntry != null) → 기존 데이터 채움
    │
    ├─ 화장실 스위치 토글
    │     ├─ ON  → visited = true
    │     └─ OFF → visited = false, mood = null 초기화
    │
    ├─ 기분 버튼 탭 (좋음 / 보통 / 나쁨)
    │     ├─ 미선택 → 선택
    │     └─ 선택됨 → 선택 해제 (null)
    │
    ├─ 날짜·시간 탭
    │     └─► CupertinoDatePicker (미래 시간 선택 불가)
    │
    ├─ 메모 입력 + 빠른 태그 탭
    │     └─ 태그 탭 → 메모에 텍스트 추가
    │
    ├─ 저장 버튼
    │     ├─ 신규 → DB insert
    │     ├─ 수정 → DB update
    │     ├─ HomeWidgetService 갱신
    │     ├─ AdService.onRecordSaved() → 최초 10회 저장 후 첫 노출, 이후 7회마다 전면 광고
    │     └─ Navigator.pop()
    │
    ├─ 삭제 버튼 (수정 모드만)
    │     └─ 확인 다이얼로그
    │           ├─ 취소 → 그대로
    │           └─ 확인 → DB delete → Navigator.pop()
    │
    └─ X (닫기) 버튼 / 뒤로가기
          └─ Navigator.pop() (저장 없음)
```

---

## 7. 더보기 화면

```
[더보기 화면]
    │
    ├─ [결제] 광고 제거 (₩2,900)
    │     ├─ 구매 버튼 → 인앱 결제 → adsRemovedProvider = true
    │     └─ 구매 복원 → 복원 처리
    │
    ├─ [설정]
    │     ├─ 다크모드 탭 → 바텀시트 (기기 설정 / 라이트 / 다크)
    │     ├─ 기분 표시 방식 탭 → 바텀시트 (색상 도트 / 얼굴 아이콘)
    │     └─ 주 시작 요일 탭 → 바텀시트 (일요일 / 월요일)
    │
    ├─ [지원]
    │     ├─ 앱 가이드 탭 → [온보딩 화면] (fromSettings=true)
    │     ├─ 피드백 보내기 탭 → 외부 브라우저 (피드백 URL)
    │     ├─ 앱 평가 탭 → 스토어 평가 팝업 (in_app_review)
    │     └─ 개인정보처리방침 탭 → 외부 브라우저 (URL)
    │
    ├─ [정보]
    │     ├─ 오픈소스 라이선스 탭 → [라이선스 화면]
    │     └─ 앱 버전 탭 (5회) → 히든 테스트 데이터 생성 기능 활성화
    │
    └─ [데이터]
          ├─ CSV 내보내기 → share_plus로 파일 공유
          ├─ CSV 가져오기 → file_picker → Upsert 방식 DB 저장
          └─ 데이터 초기화 → 확인 다이얼로그
                └─ 확인 → 전체 삭제 → 캘린더 탭으로 이동
```

---

## 8. 업데이트 / 공지 팝업

```
[업데이트 팝업]
    │
    ├─ force_update=false
    │     ├─ 업데이트 버튼 → 스토어 이동
    │     └─ 취소 버튼 → 팝업 닫고 앱 계속 이용
    │
    └─ force_update=true
          └─ 업데이트 버튼만 → 스토어 이동 (뒤로가기/닫기 불가)

[공지사항 팝업]
    ├─ 확인 버튼 → 팝업 닫힘 (show 횟수 남아있으면 다음 실행 시 재표시)
    └─ 다시 보지 않음 → SharedPreferences에 notice.id 저장 → 이후 완전히 미표시
```
