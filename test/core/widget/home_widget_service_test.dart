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
/// 반환값이 필요한 경우 [returnValue]를 지정한다.
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
      expect(data.lastMoodLabel, '');
      expect(data.lastMoodColor, '');
      expect(data.todayDots, '');
    });

    test('dateLabel은 "월/일" 형식', () {
      final data = HomeWidgetService.buildData([], DateTime(2026, 5, 21));
      expect(data.dateLabel, '5/21');
    });

    test('dateLabel — 한 자리 월/일 그대로 표시', () {
      final data = HomeWidgetService.buildData([], DateTime(2026, 1, 3));
      expect(data.dateLabel, '1/3');
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
      // DateTime.now() 사용 시 23시 이후 테스트에서 +1시간이 다음 날이 될 수 있으므로 고정 시각 사용
      const t1 = Duration(hours: 9);
      const t2 = Duration(hours: 10);
      final base = DateTime(2026, 5, 1);
      await _insert(db, recordedAt: base.add(t1));
      await _insert(db, recordedAt: base.add(t2));
      final entries = await db.getEntriesInRange(base, base.add(const Duration(days: 1)));
      final data = HomeWidgetService.buildData(entries, base.add(t1));
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

    test('lastTime은 마지막 방문 기록의 HH:mm (24시간)', () async {
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

    test('lastTime — 자정(0시 0분) 포맷 "00:00"', () async {
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

    test('기분 없는 방문 — lastMoodLabel "다녀옴", lastMoodColor 회색(#8CA896)', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: null);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodLabel, '다녀옴');
      expect(data.lastMoodColor, '#8CA896');
    });

    test('기분=좋음 — lastMoodColor #3DA06C, label "좋음"', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: 0);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodLabel, '좋음');
      expect(data.lastMoodColor, '#3DA06C');
    });

    test('기분=보통 — lastMoodColor #CC7D30, label "보통"', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: 1);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodLabel, '보통');
      expect(data.lastMoodColor, '#CC7D30');
    });

    test('기분=나쁨 — lastMoodColor #C64848, label "나쁨"', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: now, visited: true, mood: 2);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.lastMoodLabel, '나쁨');
      expect(data.lastMoodColor, '#C64848');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // todayDots
  // ─────────────────────────────────────────────────────────────────────────

  group('buildData() — todayDots', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('방문 기록 없으면 빈 문자열', () async {
      final data = HomeWidgetService.buildData([], DateTime.now());
      expect(data.todayDots, '');
    });

    test('좋음·보통·나쁨 순서대로 콤마 구분', () async {
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
      expect(data.todayDots, '#3DA06C,#CC7D30,#C64848');
    });

    test('기분 없는 방문은 회색 #8CA896 도트', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: DateTime(now.year, now.month, now.day, 10), mood: null);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.todayDots, '#8CA896');
    });

    test('visited=false는 도트에 포함 안 됨', () async {
      final now = DateTime.now();
      await _insert(db, recordedAt: DateTime(now.year, now.month, now.day, 10), visited: true, mood: 0);
      await _insert(db, recordedAt: DateTime(now.year, now.month, now.day, 11), visited: false);
      final entries = await db.getEntriesInRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      final data = HomeWidgetService.buildData(entries, now);
      expect(data.todayDots, '#3DA06C');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // update() — 채널 호출 검증
  // ─────────────────────────────────────────────────────────────────────────

  group('update() — home_widget 채널 호출', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('saveWidgetData 6개 키 모두 호출됨', () async {
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
          'last_mood_label',
          'last_mood_color',
          'today_dots',
          'date_label',
        ]),
      );
    });

    test('updateWidget 1회 호출됨', () async {
      final calls = _mockHomeWidgetChannel();

      await HomeWidgetService.update(db);

      expect(calls.where((c) => c.method == 'updateWidget').length, 1);
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
