// 전면 광고 로드·노출·빈도 관리 싱글톤.
// 최초 10회 저장 시 첫 전면 광고를 노출하고, 이후 7회마다 1회 노출한다.
// adsRemovedProvider가 true이면 건너뛴다.

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_ids.dart';

const _kSaveCountKey = 'ad_save_count';

/// 최초 전면 광고 노출 기준 저장 횟수
const _kFirstAdThreshold = 10;

/// 최초 이후 전면 광고 노출 주기
const _kInterstitialFrequency = 7;

/// 전면 광고 로드·노출 및 빈도 관리 싱글톤.
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  /// 앱 시작 시 전면 광고를 미리 로드한다.
  void preload() {
    if (_isLoading || _interstitialAd != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// 기록 저장 완료 후 호출.
  /// 빈도 조건 충족 시 전면 광고를 표시하고, 완료(또는 스킵) 후 [onComplete]를 호출한다.
  /// [adsRemoved]가 true이면 광고를 건너뛴다.
  Future<void> onRecordSaved({
    VoidCallback? onComplete,
    bool adsRemoved = false,
  }) async {
    if (adsRemoved) {
      onComplete?.call();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_kSaveCountKey) ?? 0) + 1;
    await prefs.setInt(_kSaveCountKey, count);

    final isFirst = count == _kFirstAdThreshold;
    final isSubsequent = count > _kFirstAdThreshold &&
        (count - _kFirstAdThreshold) % _kInterstitialFrequency == 0;

    if ((isFirst || isSubsequent) && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          preload();
          onComplete?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          preload();
          onComplete?.call();
        },
      );
      await _interstitialAd!.show();
    } else {
      if (_interstitialAd == null) preload();
      onComplete?.call();
    }
  }
}
