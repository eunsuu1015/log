// HomeWidgetService 단위 테스트
//
// 테스트 전략:
// • buildData()는 순수 로직 → Entry 리스트·DateTime 조합으로 직접 검증
// • update()는 home_widget 네이티브 채널을 사용하므로
//   MethodChannel 모킹 후 "채널이 올바른 키로 호출되는지" 통합 검증
// ---------------------------------------------------------------------------

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/widget/home_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// home_widget 채널을 가로채 호출 기록을 저장한다.
List<MethodCall> _mockHomeWidgetChannel({Object? returnValue = true}) {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('home_widget'),
    (call) async {
      calls.add(call);
      return returnValue;
    },
  );
  return calls;
}

Future<Entry> _insert(
  AppDatabase db, {
  required DateTime recordedAt,
  bool? visited = true,
  int? mood,
  String? memo,
}) async {
  await db.insertEntry(
    EntriesCompanion(
      recordedAt: Value(recordedAt),
      visited: Value(visited),
      mood: Value(mood),
      memo: Value(memo),
    ),
  );
  return (await db.getEntriesInRange(DateTime(2000), DateTime(2200))).last;
}

// ---------------------------------------------------------------------------
// buildData() — 순수 로직 테스트
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ─────────────────────────────────────────────────────────────────────────
  // 빈 기록
  // ─────────────────────────────────────────────────────────────────────────

  group('buildData() — 기록 없음', () {
    test('visitCount = "0", 나머지 문자열은 빈 값', () {
      final data = HomeWidgetService.buildData([], DateTime(2026, 5, 21));
      expect(data.visitCount, '0');
      expect(data.lastTime, '');
      expect(data.lastMoodColor, '');
      expect(data.todayRecords, '');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 방문 기록 있음
  // ─────────────────────────────────────────────────────────────────────────

  group('buildData() — 방문 기록', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('방문 횟수만큼 visitCount 증가', () async {
      final base = DateTime(2026, 5, 1);
      await _insert(db, recordedAt: base.add(const Duration(hours: 9)));
      await _insert(db, recordedAt: base.add(const Duration(hours: 10)));
      final entries =
          await db.getEntriesInRange(base, base.add(const Duration(days: 1)));
      final data =
          HomeWidgetService.buildData(entries, base.add(const Duration(hours: 9)));
      expect(data.visitCount, '2');
    });

    test('visited=false는 visitCount에 포함되지 않음', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true);
      await _insert(db, recordedAt: now, visited: false);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.visitCount, '1');
    });

    test('lastTime은 마지막 방문 기록의 HH:mm', () async {
      final now = DateTime.now();
      final t1 = DateTime(now.year, now.month, now.day, 9, 5);
      final t2 = DateTime(now.year, now.month, now.day, 14, 32);
      await _insert(db, recordedAt: t1);
      await _insert(db, recordedAt: t2);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastTime, '14:32');
    });

    test('lastTime — 자정(0:00) → "00:00"', () async {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 0, 0);
      await _insert(db, recordedAt: midnight);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastTime, '00:00');
    });

    test('기분 없는 방문 — lastMoodColor 회색 #8CA896', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: null);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodColor, '#8CA896');
    });

    test('기분=좋음 — lastMoodColor #3DA06C', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: 0);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodColor, '#3DA06C');
    });

    test('기분=보통 — lastMoodColor #CC7D30', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: 1);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodColor, '#CC7D30');
    });

    test('기분=나쁨 — lastMoodColor #C64848', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: 2);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodColor, '#C64848');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // todayRecords ("HH:mm|#COLOR,..." 형식)
  // ─────────────────────────────────────────────────────────────────────────

  group('buildData() — todayRecords', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('방문 기록 없으면 빈 문자열', () {
      final data = HomeWidgetService.buildData([], DateTime.now());
      expect(data.todayRecords, '');
    });

    test('단일 기록 — "HH:mm|#COLOR" 형식', () async {
      final now = DateTime.now();
      final t = DateTime(now.year, now.month, now.day, 9, 5);
      await _insert(db, recordedAt: t, mood: 0);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.todayRecords, '09:05|#3DA06C');
    });

    test('복수 기록 — 콤마로 구분, 시간 오름차순', () async {
      final now = DateTime.now();
      final base = DateTime(now.year, now.month, now.day, 8);
      await _insert(db, recordedAt: base, mood: 0);
      await _insert(db, recordedAt: base.add(const Duration(hours: 1)), mood: 1);
      await _insert(db, recordedAt: base.add(const Duration(hours: 2)), mood: 2);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.todayRecords, '08:00|#3DA06C,09:00|#CC7D30,10:00|#C64848');
    });

    test('기분 없는 방문은 #8CA896 도트', () async {
      final now = DateTime.now();
      await _insert(
          db, recordedAt: DateTime(now.year, now.month, now.day, 10), mood: null);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.todayRecords, '10:00|#8CA896');
    });

    test('visited=false는 todayRecords에 포함 안 됨', () async {
      final now = DateTime.now();
      await _insert(
          db, recordedAt: DateTime(now.year, now.month, now.day, 10),
          visited: true, mood: 0);
      await _insert(
          db, recordedAt: DateTime(now.year, now.month, now.day, 11),
          visited: false);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.todayRecords, '10:00|#3DA06C');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // update() — 채널 호출 검증
  // ─────────────────────────────────────────────────────────────────────────

  group('update() — home_widget 채널 호출', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('saveWidgetData 4개 키 모두 호출됨', () async {
      final calls = _mockHomeWidgetChannel();

      await HomeWidgetService.update(db);

      final savedKeys = calls
          .where((c) => c.method == 'saveWidgetData')
          .map((c) => c.arguments['id'] as String)
          .toSet();

      expect(
        savedKeys,
        containsAll([
          'visit_count',
          'last_time',
          'last_mood_color',
          'today_records',
        ]),
      );
    });

    test('updateWidget 3개 receiver 모두 호출됨', () async {
      final calls = _mockHomeWidgetChannel();

      await HomeWidgetService.update(db);

      expect(calls.where((c) => c.method == 'updateWidget').length, 3);
    });

    test('기록 삽입 후 update() — visit_count가 올바른 값으로 저장됨', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: DateTime(now.year, now.month, now.day, 8));
      await _insert(db, recordedAt: DateTime(now.year, now.month, now.day, 9));

      final calls = _mockHomeWidgetChannel();
      await HomeWidgetService.update(db);

      final countCall = calls.firstWhere(
        (c) => c.method == 'saveWidgetData' && c.arguments['id'] == 'visit_count',
      );
      expect(countCall.arguments['data'], '2');
    });
  });
}
