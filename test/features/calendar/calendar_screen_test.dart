import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/features/calendar/calendar_provider.dart';
import 'package:poopoolog/features/calendar/calendar_screen.dart';
import 'package:poopoolog/shared/widgets/entry_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildScreen(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: CalendarScreen()),
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
    testWidgets('캘린더 타이틀·FAB 렌더링', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('캘린더'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('현재 달 보기: AppBar에 오늘 버튼 없음', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(now.year, now.month),
        ),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('오늘'), findsNothing);
    });

    testWidgets('다른 달 보기: AppBar에 오늘 버튼 노출', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = _makeDb();
      // firstDay(2026-05-01) 이후 & 오늘 달과 다른 달: 다음 달 사용
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(nextMonth.year, nextMonth.month),
        ),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('오늘'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 월 헤더 텍스트
  // ─────────────────────────────────────────────────────────────────────────

  group('월 헤더 텍스트', () {
    testWidgets('focusedMonth에 따라 N년 M월 텍스트 표시', (tester) async {
      final db = _makeDb();
      // firstDay(2026-05-01) 이후 달 사용: 2026년 6월
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith((ref) => DateTime(2026, 6)),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('2026년 6월'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DayPanel
  // ─────────────────────────────────────────────────────────────────────────

  group('DayPanel', () {
    testWidgets('기록 있는 날짜 선택 → DayPanel 헤더 표시', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = _makeDb();
      final targetDate = DateTime(2026, 5, 10, 9, 0);
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(targetDate),
          visited: const Value(true),
        ),
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(2026, 5),
        ),
        selectedDayProvider.overrideWith((ref) => targetDate),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('5월 10일'), findsOneWidget);
    });

    testWidgets('DayPanel에 EntryCard 렌더링 (기분 레이블·메모·시간)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = _makeDb();
      final targetDate = DateTime(2026, 5, 10, 9, 0);
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(targetDate),
          visited: const Value(true),
          memo: const Value('테스트 메모'),
        ),
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(2026, 5),
        ),
        selectedDayProvider.overrideWith((ref) => targetDate),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard), findsOneWidget);
      expect(find.text('테스트 메모'), findsOneWidget);
      expect(find.text('다녀옴'), findsOneWidget); // visited=true, mood=null → moodLabel
      expect(find.text('오전 9:00'), findsOneWidget); // timeStr
    });

    testWidgets('날짜 미선택(selectedDay=null): DayPanel 없음', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        selectedDayProvider.overrideWith((ref) => null),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 추가 버튼은 제거됨 — DayPanel 자체도 없으므로 날짜 헤더 없음
      expect(find.text('추가'), findsNothing);
    });

    testWidgets('같은 날 기록 여러 개 → EntryCard 여러 개 렌더링', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = _makeDb();
      final day = DateTime(2026, 5, 15);
      for (final hour in [8, 12, 18]) {
        await db.insertEntry(
          EntriesCompanion(
            recordedAt: Value(DateTime(2026, 5, 15, hour)),
            visited: const Value(true),
          ),
        );
      }

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(2026, 5),
        ),
        selectedDayProvider.overrideWith((ref) => day),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard), findsNWidgets(3));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 최초 기록일 이전 달
  // ─────────────────────────────────────────────────────────────────────────

  group('최초 기록일 이전 달', () {
    testWidgets('기록보다 이전 달 보기: _BeforeEarliestState 표시', (tester) async {
      final db = _makeDb();
      final now = DateTime.now();
      // 다음 달에 기록 삽입 → earliestDate = 다음 달 (firstDay 이후)
      final nextMonth = DateTime(now.year, now.month + 1);
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(DateTime(nextMonth.year, nextMonth.month, 1)),
          visited: const Value(true),
        ),
      );

      // 이번 달로 포커스 (firstDay=2026-05-01 이후, 기록 날짜 이전)
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(now.year, now.month),
        ),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('푸푸로그를 시작하기 전이에요!'), findsOneWidget);
      expect(
        find.textContaining('${nextMonth.year}년 ${nextMonth.month}월 1일'),
        findsOneWidget,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 미래 날짜
  // ─────────────────────────────────────────────────────────────────────────

  group('미래 날짜', () {
    testWidgets('미래 날짜 선택 → DayPanel 표시 + 빈 상태 UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = _makeDb();
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(futureDate.year, futureDate.month),
        ),
        selectedDayProvider.overrideWith((ref) => futureDate),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 미래 날짜도 DayPanel 표시 (기록 없으면 빈 상태 UI)
      expect(find.text('저장된 기록이 없어요'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 오늘 버튼 동작
  // ─────────────────────────────────────────────────────────────────────────

  group('오늘 버튼 동작', () {
    testWidgets('오늘 버튼 탭 → calendarFocusedMonth 현재 달로 변경', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = _makeDb();
      final now = DateTime.now();
      // firstDay(2026-05-01) 이후이면서 오늘 달과 다른 달: 다음 달
      final nextMonth = DateTime(now.year, now.month + 1);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        calendarFocusedMonthProvider.overrideWith(
          (ref) => DateTime(nextMonth.year, nextMonth.month),
        ),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();

      final focused = container.read(calendarFocusedMonthProvider);
      expect(focused.year, now.year);
      expect(focused.month, now.month);
    });
  });
}
