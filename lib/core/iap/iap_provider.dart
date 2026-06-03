// 인앱 결제(광고 제거) Provider 및 구매 Notifier.
// Google Play / App Store 단일 상품(remove_ads) 구매·복원 흐름을 관리한다.
// 구매 완료 시 SharedPreferences에 영구 저장하고 adsRemovedProvider를 갱신한다.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences에 저장 시 사용하는 값
const kAdsRemovedKey = 'ads_removed';

// 스토어에 등록할 상품 ID (Google Play / App Store 동일하게 사용)
const kRemoveAdsProductId = 'poopoolog_remove_ads';

/// 광고 제거 여부. main.dart에서 SharedPreferences 초기값을 주입한다.
final adsRemovedProvider = StateProvider<bool>((_) => false);

/// 구매 UI 상태
enum IAPStatus { idle, loading, error, canceled }

/// 광고 제거 인앱 결제 핸들러
final purchaseNotifierProvider = NotifierProvider<PurchaseNotifier, IAPStatus>(
  PurchaseNotifier.new,
);

class PurchaseNotifier extends Notifier<IAPStatus> {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Timer? _restoreTimer;
  Timer? _buyTimer;

  @override
  IAPStatus build() {
    _sub = InAppPurchase.instance.purchaseStream.listen(_onPurchases);
    ref.onDispose(() {
      _sub?.cancel();
      _restoreTimer?.cancel();
      _buyTimer?.cancel();
    });
    return IAPStatus.idle;
  }

  /// 광고 제거 상품을 신규 구매한다.
  /// buyNonConsumable 호출은 비동기로 진행되며 결과는 purchaseStream → _onPurchases에서 처리된다.
  /// 구매 팝업 취소 시 스트림 이벤트가 오지 않는 경우를 대비해 30초 타이머로 loading 상태를 강제 해제한다.
  Future<void> buy() async {
    state = IAPStatus.loading;
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        state = IAPStatus.error;
        return;
      }
      final response = await iap.queryProductDetails({kRemoveAdsProductId});
      if (response.productDetails.isEmpty) {
        state = IAPStatus.error;
        return;
      }
      await iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );
      // 팝업이 뜬 이후 스트림 이벤트가 오지 않을 경우를 대비한 폴백 타이머
      _buyTimer?.cancel();
      _buyTimer = Timer(const Duration(seconds: 30), () {
        if (state == IAPStatus.loading) state = IAPStatus.canceled;
      });
    } catch (_) {
      state = IAPStatus.error;
    }
  }

  /// 이전 구매 이력을 복원한다.
  /// 복원할 내역이 없으면 스트림 이벤트가 오지 않으므로 5초 타이머로 loading 상태를 강제 해제한다.
  Future<void> restore() async {
    state = IAPStatus.loading;
    try {
      await InAppPurchase.instance.restorePurchases();
      _restoreTimer?.cancel();
      _restoreTimer = Timer(const Duration(seconds: 5), () {
        if (state == IAPStatus.loading) state = IAPStatus.idle;
      });
    } catch (_) {
      state = IAPStatus.error;
    }
  }

  /// 오류 상태를 idle로 초기화한다. SnackBar 표시 후 호출한다.
  void clearError() => state = IAPStatus.idle;

  /// 취소 상태를 idle로 초기화한다. UI에서 canceled 처리 후 호출한다.
  void clearCanceled() => state = IAPStatus.idle;

  /// 구매 스트림 이벤트 핸들러.
  /// purchased·restored 상태 시 영구 저장 후 adsRemovedProvider를 갱신한다.
  /// pendingCompletePurchase는 스토어에 완료 신호를 보내야 구매가 확정되므로 반드시 completePurchase를 호출해야 한다.
  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kRemoveAdsProductId) continue;

      // 스트림 이벤트가 도착했으므로 폴백 타이머 취소
      _buyTimer?.cancel();

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(kAdsRemovedKey, true);
        ref.read(adsRemovedProvider.notifier).state = true;
        state = IAPStatus.idle;
      } else if (p.status == PurchaseStatus.error) {
        state = IAPStatus.error;
      } else if (p.status == PurchaseStatus.canceled) {
        state = IAPStatus.canceled;
      }

      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }
}
