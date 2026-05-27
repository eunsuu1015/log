import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/record/record_provider.dart';
import 'package:poopoolog/features/record/record_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// 단순 렌더링·상태 테스트용 — RecordScreen을 홈으로 직접 마운트
Widget _buildScreen(ProviderContainer container, {Entry? existingEntry}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: RecordScreen(existingEntry: existingEntry),
      ),
    );

/// 저장/삭제 후 네비게이션(pop) 검증용 — 이전 라우트에서 push
Widget _buildScreenWithNav(
  ProviderContainer container, {
  Entry? existingEntry,
}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.push<void>(
              ctx,
              MaterialPageRoute(
                builder: (_) => RecordScreen(existingEntry: existingEntry),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
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
    testWidgets('"기록 입력" 타이틀·닫기(×) 버튼 렌더링', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('기록 입력'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('섹션 레이블·저장 버튼 렌더링', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      for (final label in ['날짜 · 시간', '화장실', '기분', '메모']) {
        expect(find.text(label), findsOneWidget, reason: '$label 없음');
      }
      expect(find.text('저장'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 폼 초기값·빠른 태그
  // ─────────────────────────────────────────────────────────────────────────

  group('폼 초기값·빠른 태그', () {
    testWidgets('신규 생성 초기값: visited=true (스위치 on)·저장 버튼 활성화', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);

      final state = container.read(recordFormProvider(null));
      expect(state.visited, isTrue);
      expect(state.mood, isNull);
      expect(state.isSaving, isFalse);

      final saveBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('빠른 태그 6개 렌더링 (쾌변·설사·묽음·배아픔·잔변감·급했음)', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 빠른 태그는 ListView 하단에 위치하므로 스크롤 후 확인
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      for (final tag in ['쾌변', '설사', '묽음', '배아픔', '잔변감', '급했음']) {
        expect(find.text(tag), findsOneWidget, reason: '$tag 태그 없음');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 기분 선택·해제
  // ─────────────────────────────────────────────────────────────────────────

  group('기분 선택·해제', () {
    testWidgets('"좋음" 탭 → formState.mood = MoodLevel.good', (tester) async {
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

      expect(container.read(recordFormProvider(null)).mood, MoodLevel.good);
    });

    testWidgets('"좋음" 재탭 → mood = null (선택 해제)', (tester) async {
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
      await tester.tap(find.text('좋음'));
      await tester.pump();

      expect(container.read(recordFormProvider(null)).mood, isNull);
    });

    testWidgets('"보통" 탭 → mood = okay / "나쁨" 탭 → mood = bad', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('보통'));
      await tester.pump();
      expect(container.read(recordFormProvider(null)).mood, MoodLevel.okay);

      await tester.tap(find.text('나쁨'));
      await tester.pump();
      expect(container.read(recordFormProvider(null)).mood, MoodLevel.bad);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 방문 여부 ↔ 기분 연동
  // ─────────────────────────────────────────────────────────────────────────

  group('방문 여부 ↔ 기분 연동', () {
    testWidgets('기분 선택 후 스위치 off → mood null 자동 초기화', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 좋음 선택
      await tester.tap(find.text('좋음'));
      await tester.pump();
      expect(container.read(recordFormProvider(null)).mood, MoodLevel.good);

      // 스위치 off
      await tester.tap(find.text('화장실에 다녀왔어요'));
      await tester.pump();

      final state = container.read(recordFormProvider(null));
      expect(state.visited, isFalse);
      expect(state.mood, isNull);
    });

    testWidgets('스위치 off 후 기분 선택 → visited 자동 true', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      // 스위치 off
      await tester.tap(find.text('화장실에 다녀왔어요'));
      await tester.pump();
      expect(container.read(recordFormProvider(null)).visited, isFalse);

      // 기분 선택
      await tester.tap(find.text('보통'));
      await tester.pump();

      final state = container.read(recordFormProvider(null));
      expect(state.visited, isTrue);
      expect(state.mood, MoodLevel.okay);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 빠른 태그 동작
  // ─────────────────────────────────────────────────────────────────────────

  group('빠른 태그 동작', () {
    testWidgets('"쾌변" 탭 → 메모 필드에 추가, formState.memo = "쾌변"', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('쾌변'));
      await tester.pump();

      expect(container.read(recordFormProvider(null)).memo, '쾌변');
    });

    testWidgets('빠른 태그 2번 탭 → 공백으로 이어 붙임', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('쾌변'));
      await tester.pump();
      await tester.tap(find.text('설사'));
      await tester.pump();

      expect(container.read(recordFormProvider(null)).memo, '쾌변 설사');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 닫기 버튼
  // ─────────────────────────────────────────────────────────────────────────

  group('닫기 버튼', () {
    testWidgets('X 버튼 탭 → 저장 없이 화면 닫힘', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreenWithNav(container));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('기록 입력'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 화면 닫힘
      expect(find.text('기록 입력'), findsNothing);
      // DB에 기록 없음
      final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(entries, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 저장
  // ─────────────────────────────────────────────────────────────────────────

  group('저장', () {
    testWidgets('저장 탭 → DB 삽입 후 화면 닫힘', (tester) async {
      final db = _makeDb();
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // 광고 제거 상태로 onComplete 즉시 호출 → Navigator.pop 보장
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreenWithNav(container));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('기록 입력'), findsOneWidget);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // 화면 닫힘
      expect(find.text('기록 입력'), findsNothing);
      // DB에 기록 삽입됨
      final entries = await db.getEntriesInRange(
        DateTime(2000),
        DateTime(2200),
      );
      expect(entries.length, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 수정 모드
  // ─────────────────────────────────────────────────────────────────────────

  group('수정 모드', () {
    Future<Entry> insertAndFetch(AppDatabase db) async {
      await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(DateTime(2026, 5, 10, 9)),
          visited: const Value(true),
          mood: const Value(0), // good
          memo: const Value('수정 테스트'),
        ),
      );
      return (await db.getEntriesInRange(DateTime(2000), DateTime(2200))).first;
    }

    testWidgets('기존 값으로 폼 초기화 + 삭제 버튼 표시', (tester) async {
      final db = _makeDb();
      final entry = await insertAndFetch(db);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container, existingEntry: entry));
      await tester.pumpAndSettle();

      // 기존 memo 표시
      expect(find.text('수정 테스트'), findsOneWidget);
      // 삭제 버튼 표시
      expect(find.text('삭제'), findsOneWidget);
      // formState mood 초기화 확인
      expect(
        container.read(recordFormProvider(entry)).mood,
        MoodLevel.good,
      );
    });

    testWidgets('삭제 다이얼로그 → 취소 → DB 기록 유지', (tester) async {
      final db = _makeDb();
      final entry = await insertAndFetch(db);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreen(container, existingEntry: entry));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // 다이얼로그 닫힘
      expect(find.text('이 기록을 삭제할까요?'), findsNothing);
      // DB 기록 유지
      final remaining = await db.getEntriesInRange(
        DateTime(2000),
        DateTime(2200),
      );
      expect(remaining.length, 1);
    });

    testWidgets('삭제 다이얼로그 → 삭제 확인 → DB 제거 후 화면 닫힘', (tester) async {
      final db = _makeDb();
      final entry = await insertAndFetch(db);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        adsRemovedProvider.overrideWith((ref) => true),
      ]);
      addTearDown(container.dispose);
      addTearDown(db.close);

      await tester.pumpWidget(_buildScreenWithNav(container, existingEntry: entry));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 삭제 버튼 탭 (하단 바)
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인 버튼 탭
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await tester.pumpAndSettle();

      // 화면 닫힘
      expect(find.text('기록 입력'), findsNothing);
      // DB에서 제거됨
      final remaining = await db.getEntriesInRange(
        DateTime(2000),
        DateTime(2200),
      );
      expect(remaining.length, 0);
    });
  });
}
