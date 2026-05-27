import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';
import 'package:poopoolog/core/models/mood_display_provider.dart';
import 'package:poopoolog/core/settings/display_settings.dart';
import 'package:poopoolog/features/more/more_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// ---------------------------------------------------------------------------
// 가짜 UrlLauncherPlatform — url_launcher 플랫폼 채널 없이 호출 기록
// ---------------------------------------------------------------------------
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  // canLaunchUrl 자유함수가 내부적으로 canLaunch(String)을 호출하므로 재정의 필요
  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

// ---------------------------------------------------------------------------
// 가짜 PurchaseNotifier — IAP 플랫폼 채널 구독 없이 상태만 제어
// ---------------------------------------------------------------------------
class _FakePurchaseNotifier extends PurchaseNotifier {
  final IAPStatus _initial;
  _FakePurchaseNotifier([this._initial = IAPStatus.idle]);

  @override
  IAPStatus build() => _initial;

  @override
  Future<void> buy() async => state = IAPStatus.loading;

  @override
  Future<void> restore() async => state = IAPStatus.loading;

  // 테스트에서 외부 상태 전환 트리거
  void simulateState(IAPStatus s) => state = s;
}

// ---------------------------------------------------------------------------
// 공통 헬퍼
// ---------------------------------------------------------------------------
Widget _buildScreen(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: MoreScreen()),
  );
}

void _setupMocks() {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'PooPooLog',
    packageName: 'com.tistory.es1015.poopoolog',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------
void main() {
  setUp(_setupMocks);

  // ─────────────────────────────────────────────────────────────────────────
  // _RemoveAdsBanner 렌더링 상태
  // ─────────────────────────────────────────────────────────────────────────

  group('_RemoveAdsBanner 렌더링', () {
    testWidgets('미구매 idle: 구매 버튼·복원 링크 표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      expect(find.text('광고 없애기'), findsOneWidget);
      expect(find.text('₩2,900'), findsOneWidget);
      expect(find.text('구매 복원'), findsOneWidget);
      expect(find.text('배너·전면·네이티브 광고를 영구적으로 제거해요'), findsOneWidget);
    });

    testWidgets('구매 완료: 완료 메시지 표시, 구매 버튼 없음', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      expect(find.text('광고 없이 앱을 이용 중이에요'), findsOneWidget);
      expect(find.text('₩2,900'), findsNothing);
      expect(find.text('구매 복원'), findsNothing);
    });

    testWidgets('loading: CircularProgressIndicator 표시, FilledButton 비활성화', (tester) async {
      final notifier = _FakePurchaseNotifier(IAPStatus.loading);
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 구매/복원 버튼 탭
  // ─────────────────────────────────────────────────────────────────────────

  group('구매/복원 버튼 탭', () {
    testWidgets('₩2,900 탭 → buy() 호출 후 loading 상태', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('₩2,900'));
      await tester.pump();

      expect(container.read(purchaseNotifierProvider), IAPStatus.loading);
    });

    testWidgets('구매 복원 탭 → restore() 호출 후 loading 상태', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('구매 복원'));
      await tester.pump();

      expect(container.read(purchaseNotifierProvider), IAPStatus.loading);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // IAP SnackBar
  // ─────────────────────────────────────────────────────────────────────────

  group('IAP SnackBar', () {
    testWidgets('error 전환 시 오류 SnackBar 표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      notifier.simulateState(IAPStatus.error);
      await tester.pump();

      expect(
        find.text('구매를 처리하는 중 오류가 발생했어요. 다시 시도해 주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('loading→idle && !adsRemoved: 복원 없음 SnackBar 표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      notifier.simulateState(IAPStatus.loading);
      await tester.pump();
      notifier.simulateState(IAPStatus.idle);
      await tester.pump();

      expect(find.text('이전 구매 내역을 찾을 수 없어요.'), findsOneWidget);
    });

    testWidgets('loading→idle && adsRemoved=true: SnackBar 표시 안 됨', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      // 구매 성공으로 adsRemoved=true가 먼저 세팅된 상황 시뮬레이션
      container.read(adsRemovedProvider.notifier).state = true;
      notifier.simulateState(IAPStatus.loading);
      await tester.pump();
      notifier.simulateState(IAPStatus.idle);
      await tester.pump();

      expect(find.text('이전 구매 내역을 찾을 수 없어요.'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 설정 섹션 현재값 표시
  // ─────────────────────────────────────────────────────────────────────────

  group('설정 섹션 현재값', () {
    testWidgets('기본값: 기기 설정 사용 / 색상 도트 / 일요일', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      expect(find.text('기기 설정 사용'), findsOneWidget);
      expect(find.text('색상 도트'), findsOneWidget);
      // startWeekdaySundayProvider 기본값 = true → 일요일 시작
      expect(find.text('일요일'), findsOneWidget);
    });

    testWidgets('startSunday=true: 일요일 표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        startWeekdaySundayProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      expect(find.text('일요일'), findsOneWidget);
    });

    testWidgets('moodDisplay=face: 얼굴 아이콘 표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        moodDisplayProvider.overrideWith((ref) => MoodDisplay.face),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      expect(find.text('얼굴 아이콘'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 데이터 초기화 다이얼로그
  // ─────────────────────────────────────────────────────────────────────────

  group('데이터 초기화', () {
    ProviderContainer makeContainerWithDb(AppDatabase db) {
      final notifier = _FakePurchaseNotifier();
      return ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        appDatabaseProvider.overrideWithValue(db),
      ]);
    }

    testWidgets('탭 시 다이얼로그 표시', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final container = makeContainerWithDb(db);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('데이터 초기화'), 100.0);
      await tester.ensureVisible(find.text('데이터 초기화'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('데이터 초기화'));
      await tester.pumpAndSettle();

      // 다이얼로그의 취소/삭제 버튼으로 표시 확인
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);

      // 정리
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
    });

    testWidgets('취소 탭: 다이얼로그 닫히고 DB 유지', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.insertEntry(EntriesCompanion(recordedAt: Value(DateTime.now())));
      addTearDown(db.close);
      final container = makeContainerWithDb(db);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('데이터 초기화'), 100.0);
      await tester.ensureVisible(find.text('데이터 초기화'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('데이터 초기화'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text('취소'), findsNothing);

      final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(entries.length, 1);
    });

    testWidgets('삭제 확인: 모든 기록 삭제됨', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.insertEntry(EntriesCompanion(recordedAt: Value(DateTime.now())));
      addTearDown(db.close);
      final container = makeContainerWithDb(db);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('데이터 초기화'), 100.0);
      await tester.ensureVisible(find.text('데이터 초기화'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('데이터 초기화'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(entries, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 버전 히든 탭 기능
  // ─────────────────────────────────────────────────────────────────────────

  group('버전 히든 탭', () {
    testWidgets('앱 버전 5회 탭 → 테스트 데이터 추가 다이얼로그 표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle(); // _appVersionProvider FutureProvider 완료 대기

      await tester.scrollUntilVisible(find.text('앱 버전'), 100.0);
      await tester.ensureVisible(find.text('앱 버전'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('앱 버전'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('테스트 데이터 추가'), findsOneWidget);

      // 정리
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
    });

    testWidgets('4회 탭에서는 다이얼로그 미표시', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('앱 버전'), 100.0);
      await tester.ensureVisible(find.text('앱 버전'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('앱 버전'));
        await tester.pump();
      }
      await tester.pump();

      expect(find.text('테스트 데이터 추가'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 피드백 보내기 버튼
  // ─────────────────────────────────────────────────────────────────────────

  group('피드백 보내기 버튼', () {
    testWidgets('URL 미설정 시 launchUrl 호출 안 됨', (tester) async {
      final fakeLauncher = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakeLauncher;

      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        feedbackUrlProvider.overrideWith((ref) => ''),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('피드백 보내기'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, isEmpty);
    });

    testWidgets('URL 설정 시 해당 URL로 launchUrl 호출됨', (tester) async {
      final fakeLauncher = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakeLauncher;

      const testUrl = 'https://example.com/feedback';
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        feedbackUrlProvider.overrideWith((ref) => testUrl),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('피드백 보내기'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, [testUrl]);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 설정 바텀시트
  // ─────────────────────────────────────────────────────────────────────────

  group('설정 바텀시트', () {
    ProviderContainer makeContainer() {
      final notifier = _FakePurchaseNotifier();
      return ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
    }

    testWidgets('다크모드 탭 → 바텀시트 열림 (라이트 모드·다크 모드 옵션 표시)', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('다크모드'));
      await tester.pumpAndSettle();

      // 기본값 '기기 설정 사용' 외에 바텀시트에서만 보이는 옵션 확인
      expect(find.text('라이트 모드'), findsOneWidget);
      expect(find.text('다크 모드'), findsOneWidget); // tile 레이블은 '다크모드'(공백 없음)
    });

    testWidgets('기분 표시 방식 탭 → 바텀시트 열림 (얼굴 아이콘 옵션 표시)', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('기분 표시 방식'));
      await tester.pumpAndSettle();

      // 기본값 '색상 도트'는 tile에 이미 표시; 바텀시트 옵션에서 '얼굴 아이콘' 확인
      expect(find.text('얼굴 아이콘'), findsAtLeastNWidgets(1));
    });

    testWidgets('주 시작 요일 탭 → 바텀시트 열림 (월요일 옵션 표시)', (tester) async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('주 시작 요일'));
      await tester.pumpAndSettle();

      // '월요일'은 tile에 없고 바텀시트 옵션에만 존재 (기본 startSunday=true → tile: '일요일')
      expect(find.text('월요일'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 앱 가이드
  // ─────────────────────────────────────────────────────────────────────────

  group('앱 가이드', () {
    testWidgets('앱 가이드 탭 → 온보딩 화면 열림 (fromSettings=true)', (tester) async {
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.tap(find.text('앱 가이드'));
      await tester.pumpAndSettle();

      // OnboardingScreen 첫 슬라이드 제목 및 닫기(X) 버튼 확인
      expect(find.text('간편하게 기록해요'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('건너뛰기'), findsNothing); // fromSettings=true이면 건너뛰기 없음
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 개인정보처리방침 버튼
  // ─────────────────────────────────────────────────────────────────────────

  group('개인정보처리방침 버튼', () {
    testWidgets('URL 미설정 시 launchUrl 호출 안 됨', (tester) async {
      final fakeLauncher = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakeLauncher;

      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        privacyPolicyUrlProvider.overrideWith((ref) => ''),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('개인정보처리방침'), 100.0);
      await tester.tap(find.text('개인정보처리방침'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, isEmpty);
    });

    testWidgets('URL 설정 시 해당 URL로 launchUrl 호출됨', (tester) async {
      final fakeLauncher = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakeLauncher;

      const testUrl = 'https://example.com/privacy';
      final notifier = _FakePurchaseNotifier();
      final container = ProviderContainer(overrides: [
        purchaseNotifierProvider.overrideWith(() => notifier),
        adsRemovedProvider.overrideWith((ref) => false),
        privacyPolicyUrlProvider.overrideWith((ref) => testUrl),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('개인정보처리방침'), 100.0);
      await tester.tap(find.text('개인정보처리방침'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, [testUrl]);
    });
  });
}
