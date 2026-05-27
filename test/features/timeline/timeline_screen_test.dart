import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';
import 'package:poopoolog/features/timeline/timeline_screen.dart';
import 'package:poopoolog/features/timeline/widgets/date_header.dart';
import 'package:poopoolog/shared/widgets/entry_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildScreen(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: TimelineScreen()),
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
    testWidgets('타임라인 타이틀·FAB 렌더링', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('타임라인'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('필터 칩 6개 표시 (전체·좋음·보통·나쁨·다녀옴·안 감)', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      for (final label in ['전체', '좋음', '보통', '나쁨', '다녀옴', '안 감']) {
        expect(find.text(label), findsOneWidget, reason: '$label 칩 없음');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 빈 상태 분기 (Case A / Case B)
  // ─────────────────────────────────────────────────────────────────────────

  group('빈 상태 분기', () {
    testWidgets('DB 기록 없음 → Case A: "아직 기록이 없어요"', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('아직 기록이 없어요'), findsOneWidget);
      expect(find.byType(EntryCard), findsNothing);
    });

    testWidgets('기록 있음 + 필터 결과 없음 → Case B: "해당 조건의 기록이 없어요"',
        (tester) async {
      final db = _makeDb();
      // good 기록만 삽입
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(DateTime.now().subtract(const Duration(days: 3))),
          visited: const Value(true),
          mood: Value(MoodLevel.good.index),
        ),
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // bad 필터 적용 → 결과 없음 (good 기록만 있으므로)
        timelineFilterProvider.overrideWith((ref) => TimelineFilter.bad),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('해당 조건의 기록이 없어요'), findsOneWidget);
      expect(find.byType(EntryCard), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 기록 리스트 렌더링
  // ─────────────────────────────────────────────────────────────────────────

  group('기록 리스트 렌더링', () {
    testWidgets('최근 기록 있음 → EntryCard 렌더링 (메모 텍스트 표시)', (tester) async {
      final db = _makeDb();
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(DateTime.now().subtract(const Duration(days: 2))),
          visited: const Value(true),
          memo: const Value('오늘의 기록'),
        ),
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard), findsOneWidget);
      expect(find.text('오늘의 기록'), findsOneWidget);
    });

    testWidgets('날짜 헤더(DateHeader) 렌더링 — N월 D일 형식·건수 배지', (tester) async {
      final db = _makeDb();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(
            DateTime(yesterday.year, yesterday.month, yesterday.day, 10),
          ),
          visited: const Value(true),
        ),
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(DateHeader), findsOneWidget);
      expect(
        find.textContaining(
          '${yesterday.month}월 ${yesterday.day}일',
        ),
        findsOneWidget,
      );
      expect(find.text('1건'), findsOneWidget);
    });

    testWidgets('같은 날 기록 2건 → 헤더에 2건 배지', (tester) async {
      final db = _makeDb();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      for (final hour in [9, 14]) {
        await db.insertEntry(
          EntriesCompanion(
            recordedAt: Value(
              DateTime(yesterday.year, yesterday.month, yesterday.day, hour),
            ),
            visited: const Value(true),
          ),
        );
      }

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(DateHeader), findsOneWidget);
      expect(find.byType(EntryCard), findsNWidgets(2));
      expect(find.text('2건'), findsOneWidget);
    });

    testWidgets('다른 날짜 기록 2일치 → DateHeader 2개·EntryCard 2개', (tester) async {
      final db = _makeDb();
      for (final daysAgo in [1, 3]) {
        final d = DateTime.now().subtract(Duration(days: daysAgo));
        await db.insertEntry(
          EntriesCompanion(
            recordedAt: Value(
              DateTime(d.year, d.month, d.day, 9),
            ),
            visited: const Value(true),
          ),
        );
      }

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(DateHeader), findsNWidgets(2));
      expect(find.byType(EntryCard), findsNWidgets(2));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 필터 칩 동작
  // ─────────────────────────────────────────────────────────────────────────

  group('필터 칩 동작', () {
    testWidgets('좋음 칩 탭 → timelineFilterProvider = good', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('좋음'));
      await tester.pump();

      expect(container.read(timelineFilterProvider), TimelineFilter.good);
    });

    testWidgets('전체 → 좋음 필터 적용 → good 기록 1건만 표시', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      // good 기록
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(
            DateTime(now.year, now.month, now.day, 9).subtract(
              const Duration(days: 1),
            ),
          ),
          visited: const Value(true),
          mood: Value(MoodLevel.good.index),
        ),
      );
      // bad 기록
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(
            DateTime(now.year, now.month, now.day, 9).subtract(
              const Duration(days: 2),
            ),
          ),
          visited: const Value(true),
          mood: Value(MoodLevel.bad.index),
        ),
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 전체 필터: 2건 표시
      expect(find.byType(EntryCard), findsNWidgets(2));

      // '좋음' 필터 탭 (칩이 EntryCard의 moodLabel과 텍스트 중복 → .first 로 칩 지정)
      await tester.tap(find.text('좋음').first);
      await tester.pumpAndSettle();

      // good 기록 1건만 표시
      expect(find.byType(EntryCard), findsOneWidget);
    });

    testWidgets('안 감 칩 탭 → notVisited 기록만 표시', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      // visited=true 기록
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(now.subtract(const Duration(days: 1))),
          visited: const Value(true),
        ),
      );
      // visited=false 기록
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(now.subtract(const Duration(days: 2))),
          visited: const Value(false),
        ),
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 전체: 2건
      expect(find.byType(EntryCard), findsNWidgets(2));

      // '안 감' 필터 탭 (칩이 EntryCard의 moodLabel과 텍스트 중복 → .first 로 칩 지정)
      await tester.tap(find.text('안 감').first);
      await tester.pumpAndSettle();

      // visited=false 기록 1건만 표시
      expect(find.byType(EntryCard), findsOneWidget);
    });
  });
}
