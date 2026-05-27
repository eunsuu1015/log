// Firebase Remote Config에서 app_config를 fetch하고 AppConfig로 파싱한다.
// 네트워크 실패 또는 파싱 오류 시 AppConfig.fallback을 반환해 앱이 정상 동작하도록 한다.

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../utils/logger.dart';
import 'app_config.dart';

/// Remote Config 파라미터 키
const _kConfigKey = 'app_config';

/// Remote Config fetch 타임아웃
const _kFetchTimeout = Duration(seconds: 10);

/// 캐시 만료 시간 (릴리즈: 1시간, 개발 중 짧게 설정 가능)
const _kMinFetchInterval = Duration(hours: 1);

/// Remote Config를 초기화하고 app_config를 fetch해 반환하는 서비스.
class RemoteConfigService {
  RemoteConfigService._();

  /// Remote Config를 초기화하고 최신 app_config를 반환한다.
  /// 파라미터 미설정·파싱 오류·네트워크 실패 모두 [AppConfig.fallback]으로 처리한다.
  static Future<AppConfig> fetchAppConfig() async {
    logger.i('[RemoteConfig] fetch 시작');
    try {
      final rc = FirebaseRemoteConfig.instance;

      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: _kFetchTimeout,
        minimumFetchInterval: _kMinFetchInterval,
      ));

      final activated = await rc.fetchAndActivate();
      logger.i('[RemoteConfig] fetchAndActivate 완료 — activated: $activated');

      final jsonString = rc.getString(_kConfigKey);
      logger.i('[RemoteConfig] 수신 데이터: $jsonString');

      if (jsonString.isEmpty) {
        logger.w('[RemoteConfig] 파라미터 없음, fallback 사용');
        return AppConfig.fallback;
      }

      final config = AppConfig.fromJsonString(jsonString);
      logger.i('[RemoteConfig] 파싱 결과 — notice.id: ${config.notice.id}, '
          'android: ${config.android.latestVersion}(force=${config.android.forceUpdate}), '
          'ios: ${config.ios.latestVersion}(force=${config.ios.forceUpdate})');
      return config;
    } catch (e) {
      logger.w('[RemoteConfig] fetch 실패, fallback 사용 — $e');
      return AppConfig.fallback;
    }
  }
}
