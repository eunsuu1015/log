// StatsResult.fromEntries() 단위 테스트
// visited 필터링, 기분 집계, 시간대 집계, 피크 시간, 방문일 중복 제거를 검증한다.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/stats/stats_provider.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _insert(
  AppDatabase db, {
  required DateTime recordedAt,
  bool? visited = true,
  int? mood,
}) async {
  await db.insertEntry(EntriesCompanion(
    recordedAt: Value(recordedAt),
    visited: Value(visited),
    mood: Value(mood),
  ));
}

Future<StatsResult> _buildResult(
  AppDatabase db, {
  int totalDays = 30,
}) async {
  final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
  return StatsResult.fromEntries(entries, totalDays: totalDays);
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // 빈 기록
  // ─────────────────────────────────────────────────────────────────────────

  group('StatsResult.fromEntries() — 기록 없음', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('totalVisits = 0', () async {
      final result = await _buildResult(db);
      expect(result.totalVisits, 0);
    });

    test('moodCounts 비어있음', () async {
      final result = await _buildResult(db);
      expect(result.moodCounts, isEmpty);
    });

    test('hourlyCounts 모두 0 (길이 24)', () async {
      final result = await _buildResult(db);
      expect(result.hourlyCounts.length, 24);
      expect(result.hourlyCounts.every((c) => c == 0), isTrue);
    });

    test('peakHours 비어있음 (방문 없으면 피크 없음)', () async {
      final result = await _buildResult(db);
      expect(result.peakHours, isEmpty);
    });

    test('visitedDays = 0', () async {
      final result = await _buildResult(db);
      expect(result.visitedDays, 0);
    });

    test('totalDays는 생성자에 전달한 값 그대로', () async {
      final result = await _buildResult(db, totalDays: 90);
      expect(result.totalDays, 90);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // visited 필터링
  // ─────────────────────────────────────────────────────────────────────────

  group('StatsResult.fromEntries() — visited 필터', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('visited=false는 totalVisits에 포함 안 됨', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9), visited: true);
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 10), visited: false);
      final result = await _buildResult(db);
      expect(result.totalVisits, 1);
    });

    test('visited=null은 totalVisits에 포함 안 됨', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9), visited: null);
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 10), visited: true);
      final result = await _buildResult(db);
      expect(result.totalVisits, 1);
    });

    test('visited=false는 hourlyCounts에도 포함 안 됨', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9), visited: false);
      final result = await _buildResult(db);
      expect(result.hourlyCounts[9], 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 기분 집계
  // ─────────────────────────────────────────────────────────────────────────

  group('StatsResult.fromEntries() — moodCounts', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('mood=null은 moodCounts에 포함 안 됨', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9), mood: null);
      final result = await _buildResult(db);
      expect(result.moodCounts, isEmpty);
    });

    test('좋음(0) 2회·보통(1) 1회 집계', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 8), mood: 0);
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9), mood: 0);
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 10), mood: 1);
      final result = await _buildResult(db);
      expect(result.moodCounts[MoodLevel.good], 2);
      expect(result.moodCounts[MoodLevel.okay], 1);
      expect(result.moodCounts[MoodLevel.bad], isNull);
    });

    test('나쁨(2) 단독 집계', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 20), mood: 2);
      final result = await _buildResult(db);
      expect(result.moodCounts[MoodLevel.bad], 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 시간대 집계
  // ─────────────────────────────────────────────────────────────────────────

  group('StatsResult.fromEntries() — hourlyCounts', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('9시 방문 2회 → hourlyCounts[9] = 2', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9, 0));
      await _insert(db, recordedAt: DateTime(2026, 5, 2, 9, 30));
      final result = await _buildResult(db);
      expect(result.hourlyCounts[9], 2);
    });

    test('자정(0시) 방문 → hourlyCounts[0] = 1', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 0, 0));
      final result = await _buildResult(db);
      expect(result.hourlyCounts[0], 1);
    });

    test('23시 방문 → hourlyCounts[23] = 1', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 23, 59));
      final result = await _buildResult(db);
      expect(result.hourlyCounts[23], 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 피크 시간
  // ─────────────────────────────────────────────────────────────────────────

  group('StatsResult.fromEntries() — peakHours', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('단일 피크 시간 반환', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 10));
      final result = await _buildResult(db);
      expect(result.peakHours, [9]);
    });

    test('공동 최다 시간대 여러 개 반환', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 8));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 8));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 14));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 14));
      final result = await _buildResult(db);
      expect(result.peakHours, containsAll([8, 14]));
      expect(result.peakHours.length, 2);
    });

    test('방문 없으면 peakHours 빈 리스트', () async {
      final result = await _buildResult(db);
      expect(result.peakHours, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 방문일 중복 제거
  // ─────────────────────────────────────────────────────────────────────────

  group('StatsResult.fromEntries() — visitedDays', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('같은 날 여러 번 방문해도 visitedDays = 1', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 8));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 12));
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 20));
      final result = await _buildResult(db);
      expect(result.visitedDays, 1);
    });

    test('3일 각 1회 방문 → visitedDays = 3', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9));
      await _insert(db, recordedAt: DateTime(2026, 5, 2, 9));
      await _insert(db, recordedAt: DateTime(2026, 5, 3, 9));
      final result = await _buildResult(db);
      expect(result.visitedDays, 3);
    });

    test('visited=false는 visitedDays에 포함 안 됨', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 1, 9), visited: true);
      await _insert(db, recordedAt: DateTime(2026, 5, 2, 9), visited: false);
      final result = await _buildResult(db);
      expect(result.visitedDays, 1);
    });
  });
}
