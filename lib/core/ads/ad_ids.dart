// 광고 단위 ID 모음. dart-define-from-file(secrets.json)에서 실제 ID를 주입한다.
// secrets.json 없이 실행 시 Google 공식 테스트 ID(defaultValue)로 자동 폴백된다.

import 'dart:io';

/// 광고 단위 ID 모음.
/// 실제 ID는 secrets.json (dart-define-from-file)에 입력하고 .gitignore로 관리한다.
/// secrets.json 없이 실행 시 defaultValue(테스트 ID)로 폴백된다.
class AdIds {
  AdIds._();

  static String get banner => Platform.isAndroid
      ? const String.fromEnvironment(
          'ADMOB_BANNER_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/6300978111',
        )
      : const String.fromEnvironment(
          'ADMOB_BANNER_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/2934735716',
        );

  static String get interstitial => Platform.isAndroid
      ? const String.fromEnvironment(
          'ADMOB_INTERSTITIAL_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/1033173712',
        )
      : const String.fromEnvironment(
          'ADMOB_INTERSTITIAL_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/4411468910',
        );

  static String get native => Platform.isAndroid
      ? const String.fromEnvironment(
          'ADMOB_NATIVE_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/2247696110',
        )
      : const String.fromEnvironment(
          'ADMOB_NATIVE_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/3986624511',
        );
}
