// 테스트·디버그 전용 플래그 모음.
// 출시 전 모든 값이 비활성화(false / null) 상태인지 반드시 확인할 것.

import '../remote_config/app_config.dart';

/// true 시 타임라인 AppBar에 AdMob Android ID 확인 버튼을 표시한다.
const bool kDebugShowAdIds = false;

/// true 시 '다시 보지 않음' 여부·노출 횟수를 무시하고 공지사항 팝업을 항상 표시한다.
const bool kForceShowNotice = false;

/// true 시 더보기 화면 '앱 버전' 5번 눌렀을 때 데이터 추가하는 기능 노출
const bool kAppVersionAddData = true;

/// null이 아니면 Firebase Remote Config fetch를 건너뛰고 이 값을 직접 사용한다.
/// 아래 주석을 해제하고 원하는 값을 입력해 Remote Config 응답을 시뮬레이션할 수 있다.
const AppConfig? kDebugRemoteConfig = null;
// const AppConfig? kDebugRemoteConfig = AppConfig(
//   notice: NoticeConfig(
//     id: 'test-notice-1',
//     title: '테스트 공지 제목',
//     message: '공지 내용을 여기에 입력하세요.',
//     noticeDate: '2026-06-04',
//     createdAt: '2026-06-04',
//     show: 0,                    // 0 = 항상 노출, 1+ = n회만 노출
//   ),
//   android: UpdateConfig(latestVersion: '999.0.0', forceUpdate: true),
//   ios: UpdateConfig(latestVersion: '999.0.0', forceUpdate: false),
// );
