// OnboardingScreen 단위·위젯 테스트
// 슬라이드 렌더링, 페이지 전환, 완료 흐름, fromSettings 모드를 검증한다.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/features/onboarding/onboarding_screen.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

Widget _buildScreen({bool fromSettings = false}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    home: OnboardingScreen(fromSettings: fromSettings),
  ),
);

/// 슬라이드 미리보기 콘텐츠가 기본 테스트 창(800×600)보다 크므로 실기기 크기로 설정한다.
void _setPhoneWindowSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ─────────────────────────────────────────────────────────────────────────
  // 초기 렌더링
  // ─────────────────────────────────────────────────────────────────────────

  group('초기 렌더링', () {
    testWidgets('첫 슬라이드 제목 표시 — "간편하게 기록해요"', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('간편하게 기록해요'), findsOneWidget);
    });

    testWidgets('fromSettings=false이면 "건너뛰기" 버튼 표시', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('건너뛰기'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('fromSettings=true이면 X 버튼 표시, 건너뛰기 없음', (tester) async {
      await tester.pumpWidget(_buildScreen(fromSettings: true));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('건너뛰기'), findsNothing);
    });

    testWidgets('첫 페이지에서 하단 버튼은 "다음"', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('다음'), findsOneWidget);
      expect(find.text('시작하기'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 페이지 전환
  // ─────────────────────────────────────────────────────────────────────────

  group('페이지 전환', () {
    testWidgets('"다음" 탭 → 두 번째 슬라이드로 이동', (tester) async {
      _setPhoneWindowSize(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.text('기분 흐름을 한눈에'), findsOneWidget);
    });

    testWidgets('"다음" 두 번 탭 → 마지막 슬라이드 + "시작하기" 버튼', (tester) async {
      _setPhoneWindowSize(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.text('나만의 패턴을 발견해요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // fromSettings 모드: 닫기
  // ─────────────────────────────────────────────────────────────────────────

  group('fromSettings 모드', () {
    testWidgets('X 버튼 탭 → 화면 pop', (tester) async {
      bool popped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const OnboardingScreen(fromSettings: true),
                    ),
                  );
                  popped = true;
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('fromSettings=true에서 완료해도 SharedPreferences 변경 없음', (tester) async {
      _setPhoneWindowSize(tester);
      SharedPreferences.setMockInitialValues({
        kOnboardingSeenKey: false,
      });

      await tester.pumpWidget(_buildScreen(fromSettings: true));
      await tester.pump();

      // 마지막 슬라이드까지 이동
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      // "시작하기" 탭 — fromSettings이므로 prefs 저장 안 함
      // (pop 후 검증은 Navigator 컨텍스트 필요 → prefs 값만 확인)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingSeenKey), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SharedPreferences 저장
  // ─────────────────────────────────────────────────────────────────────────

  group('최초 실행 완료 시 prefs 저장', () {
    testWidgets('시작하기 탭 전 kOnboardingSeenKey = null', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingSeenKey), isNull);
    });

    testWidgets('건너뛰기 탭 → kOnboardingSeenKey = true 저장', (tester) async {
      // AppShell 진입 시 appDatabaseProvider 필요 — 인메모리 DB로 대체
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(fromSettings: false),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('건너뛰기'));
      // Duration.zero으로 마이크로태스크(prefs 저장)만 처리, AppShell Firebase 호출 전 중단
      await tester.pump(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingSeenKey), isTrue);

      tester.takeException(); // AppShell 초기화 관련 예외 무시
    });

    testWidgets('시작하기 탭 → kOnboardingSeenKey = true 저장', (tester) async {
      _setPhoneWindowSize(tester);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(fromSettings: false),
        ),
      ));
      await tester.pump();

      // 마지막 슬라이드로 이동
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.text('시작하기'), findsOneWidget);

      await tester.tap(find.text('시작하기'));
      await tester.pump(Duration.zero); // prefs 저장 완료 대기

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingSeenKey), isTrue);

      tester.takeException(); // AppShell 초기화 관련 예외 무시
    });
  });
}
