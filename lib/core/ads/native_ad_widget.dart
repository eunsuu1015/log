// 타임라인 리스트 사이에 7번째마다 삽입되는 네이티브 광고 위젯.
// adsRemovedProvider가 true이면 빈 위젯으로 대체된다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';

import 'ad_ids.dart';

/// 타임라인 리스트 사이에 삽입되는 네이티브 광고 위젯.
/// 광고 제거 구매 시 빈 위젯으로 대체된다.
/// Android/iOS 네이티브 팩토리 ID: 'listTileNativeAd'
class NativeAdWidget extends ConsumerWidget {
  const NativeAdWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adsRemovedProvider)) return const SizedBox.shrink();
    return const _NativeAdContent();
  }
}

class _NativeAdContent extends StatefulWidget {
  const _NativeAdContent();

  @override
  State<_NativeAdContent> createState() => _NativeAdContentState();
}

class _NativeAdContentState extends State<_NativeAdContent> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = NativeAd(
      adUnitId: AdIds.native,
      factoryId: 'listTileNativeAd',
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
      request: const AdRequest(),
    );
    ad.load();
    _nativeAd = ad;
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();
    return SizedBox(
      height: 80,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
