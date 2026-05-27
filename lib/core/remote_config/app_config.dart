// Firebase Remote Config에서 받아오는 app_config JSON의 데이터 모델.
// notice: 공지사항, update: 앱 버전/강제 업데이트 정보를 담는다.

import 'dart:convert';

// ---------------------------------------------------------------------------
// 하위 모델
// ---------------------------------------------------------------------------

/// 공지사항 데이터. id가 빈 문자열이면 공지 없음으로 처리한다.
class NoticeConfig {
  final String id;
  final String title;
  final String message;
  final String noticeDate;
  final String createdAt;

  const NoticeConfig({
    required this.id,
    required this.title,
    required this.message,
    required this.noticeDate,
    required this.createdAt,
  });

  factory NoticeConfig.fromJson(Map<String, dynamic> json) => NoticeConfig(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        noticeDate: json['notice_date'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

  bool get isEmpty => id.isEmpty;
}

/// 앱 업데이트 정보. latest_version과 현재 버전을 비교해 강제 업데이트 여부를 판단한다.
class UpdateConfig {
  final String latestVersion;
  final bool forceUpdate;

  const UpdateConfig({
    required this.latestVersion,
    required this.forceUpdate,
  });

  factory UpdateConfig.fromJson(Map<String, dynamic> json) => UpdateConfig(
        latestVersion: json['latest_version'] as String? ?? '1.0.0',
        forceUpdate: json['force_update'] as bool? ?? false,
      );

  /// currentVersion < latestVersion 이면 true (업데이트 필요).
  /// `1.0.0` 형식 버전 문자열을 비교하며, 파싱 오류 시 false를 반환한다.
  bool isOutdated(String currentVersion) {
    try {
      final c = currentVersion.trim().split('.').map(int.parse).toList();
      final l = latestVersion.trim().split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        if (c[i] < l[i]) return true;
        if (c[i] > l[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// 최상위 모델
// ---------------------------------------------------------------------------

/// Remote Config `app_config` 파라미터 전체 모델.
/// 업데이트 정보는 android / ios 플랫폼별로 구분한다.
class AppConfig {
  final NoticeConfig notice;
  final UpdateConfig android;
  final UpdateConfig ios;

  const AppConfig({
    required this.notice,
    required this.android,
    required this.ios,
  });

  /// Remote Config에서 가져온 JSON 문자열을 파싱한다.
  factory AppConfig.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppConfig(
      notice: NoticeConfig.fromJson(map['notice'] as Map<String, dynamic>? ?? {}),
      android: UpdateConfig.fromJson(map['android'] as Map<String, dynamic>? ?? {}),
      ios: UpdateConfig.fromJson(map['ios'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// 네트워크 실패 시 사용할 기본값 — 공지 없음, 강제 업데이트 없음.
  static const AppConfig fallback = AppConfig(
    notice: NoticeConfig(
      id: '', title: '', message: '', noticeDate: '', createdAt: '',
    ),
    android: UpdateConfig(latestVersion: '0.1.0', forceUpdate: false),
    ios: UpdateConfig(latestVersion: '0.1.0', forceUpdate: false),
  );
}

