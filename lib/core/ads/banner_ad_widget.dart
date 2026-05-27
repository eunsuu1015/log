// 통계 화면 하단에 표시하는 배너 광고 위젯.
// adsRemovedProvider가 true이면 빈 위젯으로 대체된다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';

import 'ad_ids.dart';

/// 통계 화면 하단에 고정되는 배너 광고 위젯.
/// 광고 제거 구매 시 빈 위젯으로 대체된다.
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adsRemovedProvider)) return const SizedBox.shrink();
    return const _BannerAdContent();
  }
}

class _BannerAdContent extends StatefulWidget {
  const _BannerAdContent();

  @override
  State<_BannerAdContent> createState() => _BannerAdContentState();
}

class _BannerAdContentState extends State<_BannerAdContent> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
