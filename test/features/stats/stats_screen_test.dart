import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/stats/stats_provider.dart';
import 'package:poopoolog/features/stats/stats_screen.dart';
import 'package:poopoolog/features/stats/widgets/stat_heat_map_grid.dart';
import 'package:poopoolog/features/stats/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildScreen(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: StatsScreen()),
);

void _setupMocks() {
  SharedPreferences.setMockInitialValues({});
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  setUp(_setupMocks);

  // ─────────────────────────────────────────────────────────────────────────
  // AppBar·기본 구조
  // ─────────────────────────────────────────────────────────────────────────

  group('AppBar·기본 구조', () {
    testWidgets('통계 타이틀 렌더링', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('통계'), findsOneWidget);
    });

    testWidgets('기간 선택 칩 4개 렌더링 (이번 달·최근 30일·최근 90일·직접 지정)', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      for (final label in ['이번 달', '최근 30일', '최근 90일', '직접 지정']) {
        expect(find.text(label), findsOneWidget, reason: '$label 칩 없음');
      }
    });

    testWidgets('날짜 범위 레이블 표시 (YYYY.MM.DD 형식 포함)', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 날짜 범위 레이블에 현재 연도가 포함되어 있어야 함
      expect(find.textContaining('${now.year}'), findsWidgets);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 빈 상태 분기 (Case A / Case B)
  // ─────────────────────────────────────────────────────────────────────────

  group('빈 상태 분기', () {
    testWidgets('DB 기록 없음 → Case A: Ghost UI 표시 (잠금 배지 + CTA 버튼)', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('기록하면 통계가 열려요'), findsOneWidget);
      expect(find.text('첫 기록 남기기'), findsOneWidget);
      // Ghost UI는 배경에 더미 SummaryCard를 렌더링하므로 존재 확인
      expect(find.byType(SummaryCard), findsWidgets);
    });

    testWidgets('기록 있음 + 조회 기간에 데이터 없음 → Case B: "이 기간에 기록이 없어요"',
        (tester) async {
      final db = _makeDb();
      // 현재 날짜에 기록 삽입 → earliestEntryDateProvider = non-null
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(DateTime.now()),
          visited: const Value(true),
        ),
      );

      // 2020년 범위로 지정 → 해당 기간 기록 없음
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
        statsRangeProvider.overrideWith(
          (ref) => StatsRange(
            period: StatsPeriod.custom,
            customFrom: DateTime(2020, 1, 1),
            customTo: DateTime(2020, 1, 2),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('이 기간에 기록이 없어요'), findsOneWidget);
      expect(find.byType(SummaryCard), findsNothing);
      expect(find.text('기록하러 가기'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 기간 칩 동작
  // ─────────────────────────────────────────────────────────────────────────

  group('기간 칩 동작', () {
    testWidgets('초기 선택 기간: statsRangeProvider = thisMonth', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(
        container.read(statsRangeProvider).period,
        StatsPeriod.thisMonth,
      );
    });

    testWidgets('"최근 30일" 탭 → statsRangeProvider.period = last30', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('최근 30일'));
      await tester.pump();

      expect(
        container.read(statsRangeProvider).period,
        StatsPeriod.last30,
      );
    });

    testWidgets('"최근 90일" 탭 → statsRangeProvider.period = last90', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('최근 90일'));
      await tester.pump();

      expect(
        container.read(statsRangeProvider).period,
        StatsPeriod.last90,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 통계 본문 렌더링
  // ─────────────────────────────────────────────────────────────────────────

  group('통계 본문 렌더링', () {
    testWidgets('기록 있음 → SummaryCard 2개·"시간대별 방문" 렌더링', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(now),
          visited: const Value(true),
        ),
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(SummaryCard), findsNWidgets(2));
      expect(find.text('시간대별 방문'), findsOneWidget);
    });

    testWidgets('방문 횟수 카드에 실제 횟수 표시', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      for (final hour in [9, 14]) {
        await db.insertEntry(
          EntriesCompanion(
            recordedAt: Value(DateTime(now.year, now.month, now.day, hour)),
            visited: const Value(true),
          ),
        );
      }

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 방문 횟수 카드에 "2회" 표시
      expect(find.text('2회'), findsOneWidget);
    });

    testWidgets('기분 데이터 있음 → "기분 분포" 섹션 표시', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(now),
          visited: const Value(true),
          mood: Value(MoodLevel.good.index),
        ),
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('기분 분포'), findsOneWidget);
    });

    testWidgets('기분 데이터 없음 → "기분 분포" 섹션 미표시', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      // mood=null 기록만 삽입
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(now),
          visited: const Value(true),
        ),
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('기분 분포'), findsNothing);
      expect(find.text('시간대별 방문'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Ghost UI CTA 버튼 동작
  // ─────────────────────────────────────────────────────────────────────────

  group('Ghost UI CTA 버튼 동작', () {
    testWidgets('빈 DB → "첫 기록 남기기" 버튼 탭 → RecordScreen 열림', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('첫 기록 남기기'), findsOneWidget);

      await tester.tap(find.text('첫 기록 남기기'));
      await tester.pumpAndSettle();

      // RecordScreen의 "저장" 버튼이 렌더링되면 화면이 열린 것으로 확인
      expect(find.text('저장'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // StatHeatMapGrid.heatColor 단위 테스트
  // ─────────────────────────────────────────────────────────────────────────

  group('StatHeatMapGrid.heatColor 단위 테스트', () {
    // ThemeData 없이 ColorScheme만 사용하므로 임의 ColorScheme 사용
    final cs = ColorScheme.fromSeed(seedColor: Colors.blue);

    test('count == 0 → surfaceContainerHighest 반환', () {
      final color = StatHeatMapGrid.heatColor(0, 10, cs);
      expect(color, cs.surfaceContainerHighest);
    });

    test('maxCount == 0 → surfaceContainerHighest 반환', () {
      final color = StatHeatMapGrid.heatColor(5, 0, cs);
      expect(color, cs.surfaceContainerHighest);
    });

    test('비율 25% 이하 → _kHeat1 (0xFFD4EDDF)', () {
      // count=1, maxCount=10 → ratio=0.1 ≤ 0.25
      final color = StatHeatMapGrid.heatColor(1, 10, cs);
      expect(color.toARGB32(), 0xFFD4EDDF);
    });

    test('비율 정확히 25% → _kHeat1', () {
      // count=25, maxCount=100 → ratio=0.25
      final color = StatHeatMapGrid.heatColor(25, 100, cs);
      expect(color.toARGB32(), 0xFFD4EDDF);
    });

    test('비율 26~50% → _kHeat2 (0xFF7DC4A0)', () {
      // count=3, maxCount=10 → ratio=0.3
      final color = StatHeatMapGrid.heatColor(3, 10, cs);
      expect(color.toARGB32(), 0xFF7DC4A0);
    });

    test('비율 정확히 50% → _kHeat2', () {
      final color = StatHeatMapGrid.heatColor(5, 10, cs);
      expect(color.toARGB32(), 0xFF7DC4A0);
    });

    test('비율 51~75% → _kHeat3 (0xFF3DA06C)', () {
      // count=6, maxCount=10 → ratio=0.6
      final color = StatHeatMapGrid.heatColor(6, 10, cs);
      expect(color.toARGB32(), 0xFF3DA06C);
    });

    test('비율 정확히 75% → _kHeat3', () {
      final color = StatHeatMapGrid.heatColor(75, 100, cs);
      expect(color.toARGB32(), 0xFF3DA06C);
    });

    test('비율 76~100% → _kHeat4 (0xFF1B5E3A)', () {
      // count=9, maxCount=10 → ratio=0.9
      final color = StatHeatMapGrid.heatColor(9, 10, cs);
      expect(color.toARGB32(), 0xFF1B5E3A);
    });

    test('count == maxCount (100%) → _kHeat4', () {
      final color = StatHeatMapGrid.heatColor(10, 10, cs);
      expect(color.toARGB32(), 0xFF1B5E3A);
    });
  });
}
