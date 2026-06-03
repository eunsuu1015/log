// isOutdated() 버전 비교 로직 단위 테스트 +
// UpdateDialog / NoticeDialog 위젯 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/notice/notice.dart';
import 'package:poopoolog/core/remote_config/app_config.dart';
import 'package:poopoolog/features/notice/notice_dialog.dart';
import 'package:poopoolog/features/update/force_update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// ---------------------------------------------------------------------------
// 가짜 UrlLauncherPlatform
// ---------------------------------------------------------------------------
class _FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

UpdateConfig _cfg(String latest, {bool forceUpdate = false, int show = 0}) =>
    UpdateConfig(latestVersion: latest, forceUpdate: forceUpdate, show: show);

// ---------------------------------------------------------------------------
// UpdateConfig.isOutdated() 단위 테스트
// ---------------------------------------------------------------------------
void main() {
  group('UpdateConfig.show 기본값', () {
    test('show 미지정 → 0', () => expect(_cfg('1.0.0').show, 0));
    test('show=2 지정 → 2', () => expect(_cfg('1.0.0', show: 2).show, 2));
  });

  group('UpdateConfig.isOutdated()', () {
    test('patch 버전 낮으면 true', () {
      expect(_cfg('0.1.1').isOutdated('0.1.0'), isTrue);
    });

    test('minor 버전 낮으면 true', () {
      expect(_cfg('0.2.0').isOutdated('0.1.0'), isTrue);
    });

    test('major 버전 낮으면 true', () {
      expect(_cfg('1.0.0').isOutdated('0.1.0'), isTrue);
    });

    test('동일 버전이면 false', () {
      expect(_cfg('1.0.0').isOutdated('1.0.0'), isFalse);
    });

    test('현재가 더 높으면 false', () {
      expect(_cfg('1.0.0').isOutdated('1.1.0'), isFalse);
    });

    test('major 높으면 minor/patch 무관하게 false', () {
      expect(_cfg('1.9.9').isOutdated('2.0.0'), isFalse);
    });

    test('잘못된 형식이면 false (예외 무시)', () {
      expect(_cfg('1.0.0').isOutdated('abc'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // UpdateDialog 위젯 테스트
  // ---------------------------------------------------------------------------
  group('UpdateDialog', () {
    late _FakeUrlLauncher fakeLauncher;

    setUp(() {
      fakeLauncher = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fakeLauncher;
    });

    testWidgets('제목·버전·업데이트 버튼 렌더링', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.2.3',
              forceUpdate: false,
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('업데이트 안내'), findsOneWidget);
      expect(find.textContaining('1.2.3'), findsOneWidget);
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('force_update=false → "나중에" 버튼 노출', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.0.1',
              forceUpdate: false,
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('나중에'), findsOneWidget);
    });

    testWidgets('force_update=true → "나중에" 버튼 없음', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.0.1',
              forceUpdate: true,
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('나중에'), findsNothing);
    });

    testWidgets('"나중에" 버튼 탭 → 팝업 닫힘', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.0.1',
              forceUpdate: false,
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('나중에'));
      await tester.pumpAndSettle();

      expect(find.text('업데이트 안내'), findsNothing);
    });

    testWidgets('releaseNotes 있으면 "업데이트 내용" 섹션 표시', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.0.1',
              forceUpdate: false,
              releaseNotes: '• 버그 수정\n• 성능 개선',
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('업데이트 내용'), findsOneWidget);
      expect(find.textContaining('버그 수정'), findsOneWidget);
    });

    testWidgets('releaseNotes 없으면 "업데이트 내용" 섹션 미표시', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.0.1',
              forceUpdate: false,
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('업데이트 내용'), findsNothing);
    });

    testWidgets('업데이트 버튼 탭 → 스토어 URL 호출', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const UpdateDialog(
              latestVersion: '1.0.1',
              forceUpdate: false,
            ),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('업데이트'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launched, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // NoticeDialog 위젯 테스트
  // ---------------------------------------------------------------------------
  group('NoticeDialog', () {
    const testNotice = Notice(
      id: 'test_001',
      title: '테스트 공지',
      message: '공지 내용입니다.',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('제목·내용 렌더링', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const NoticeDialog(notice: testNotice),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('테스트 공지'), findsOneWidget);
      expect(find.text('공지 내용입니다.'), findsOneWidget);
    });

    testWidgets('확인 버튼 탭 → 팝업 닫힘', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const NoticeDialog(notice: testNotice),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('테스트 공지'), findsNothing);
    });

    testWidgets('다시 보지 않음 탭 → SharedPreferences에 notice.id 저장 후 닫힘',
        (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const NoticeDialog(notice: testNotice),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('다시 보지 않음'));
      await tester.pumpAndSettle();

      expect(find.text('테스트 공지'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNoticeDismissedKey), 'test_001');
    });

    testWidgets('확인 버튼은 SharedPreferences에 저장하지 않음', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => TextButton(
          onPressed: () => showDialog(
            context: ctx,
            builder: (_) => const NoticeDialog(notice: testNotice),
          ),
          child: const Text('열기'),
        )),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kNoticeDismissedKey), isNull);
    });
  });
}
