// 앱 공지사항 모델 및 현재 노출 공지 상수.
// id가 빈 문자열이면 공지 없음. 추후 Firebase Remote Config 연동 시 이 파일을 대체한다.

/// SharedPreferences 키 — 사용자가 '다시 보지 않음'을 선택한 공지 ID
const kNoticeDismissedKey = 'notice_dismissed_id';

/// SharedPreferences 키 — 공지 팝업 노출 횟수.
/// 단일 고정 키로 관리하며, 공지 ID가 바뀌면 [kNoticeShowCountIdKey]와 비교해 자동 리셋한다.
const kNoticeShowCountKey = 'notice_show_count';

/// SharedPreferences 키 — [kNoticeShowCountKey]가 어떤 공지 ID 기준인지 기록.
/// 현재 공지 ID와 다르면 카운트를 0으로 간주해 키 누적 없이 리셋한다.
const kNoticeShowCountIdKey = 'notice_show_count_id';

/// SharedPreferences 키 — 업데이트 팝업 노출 횟수.
/// 단일 고정 키로 관리하며, 플랫폼_버전이 바뀌면 [kUpdateShowCountIdKey]와 비교해 자동 리셋한다.
const kUpdateShowCountKey = 'update_show_count';

/// SharedPreferences 키 — [kUpdateShowCountKey]가 어떤 "{platform}_{version}" 기준인지 기록.
/// 현재 조합과 다르면 카운트를 0으로 간주해 키 누적 없이 리셋한다.
const kUpdateShowCountIdKey = 'update_show_count_id';

/// 앱 공지사항 데이터 모델.
class Notice {
  final String id;
  final String title;
  final String message;

  const Notice({required this.id, required this.title, required this.message});
}
