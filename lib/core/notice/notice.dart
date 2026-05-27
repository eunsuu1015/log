// 앱 공지사항 모델 및 현재 노출 공지 상수.
// id가 빈 문자열이면 공지 없음. 추후 Firebase Remote Config 연동 시 이 파일을 대체한다.

/// SharedPreferences 키 — 사용자가 '다시 보지 않음'을 선택한 공지 ID
const kNoticeDismissedKey = 'notice_dismissed_id';

/// 앱 공지사항 데이터 모델.
class Notice {
  final String id;
  final String title;
  final String message;

  const Notice({
    required this.id,
    required this.title,
    required this.message,
  });
}

/// true로 설정하면 '다시 보지 않음' 여부와 무관하게 공지를 항상 표시한다.
/// 출시 전 반드시 false로 되돌릴 것.
const kForceShowNotice = false;

/// 현재 노출할 공지. id가 비어 있으면 공지 없음으로 처리한다.
/// TODO: Firebase Remote Config 연동 후 원격에서 값을 받아 대체할 것.
const kCurrentNotice = Notice(
  id: 'notice_001',
  title: '공지 제목',
  message: '공지 메세지',
);
