// timeline_provider.dart 필터·그룹화 로직 순수 단위 테스트.
// buildGroupsForTest()를 통해 DayGroup 빌드, 날짜별 그룹화,
// 필터 조건별 결과(all/good/okay/bad/visited/notVisited)를 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

/// 테스트용 Entry 직접 생성 헬퍼 — DB 없이 순수 로직 테스트에 사용한다.
Entry _makeEntry({
  int id = 1,
  required DateTime recordedAt,
  bool? visited = true,
  int? mood,
  String? memo,
}) => Entry(
  id: id,
  recordedAt: recordedAt,
  visited: visited,
  mood: mood,
  memo: memo,
  createdAt: DateTime(2026, 1, 1),
);

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // DayGroup 빌드·날짜별 그룹화
  // ─────────────────────────────────────────────────────────────────────────

  group('buildGroupsForTest() — DayGroup 빌드·날짜 그룹화', () {
    test('기록 없으면 빈 리스트 반환', () {
      final groups = TimelineNotifier.buildGroupsForTest([], TimelineFilter.all);
      expect(groups, isEmpty);
    });

    test('단일 기록 → DayGroup 1개, entries 1건', () {
      final e = _makeEntry(recordedAt: DateTime(2026, 1, 15, 9));
      final groups = TimelineNotifier.buildGroupsForTest([e], TimelineFilter.all);
      expect(groups.length, 1);
      expect(groups.first.entries.length, 1);
      expect(groups.first.date, DateTime(2026, 1, 15));
    });

    test('같은 날 기록 3건 → DayGroup 1개, entries 3건', () {
      final entries = [
        _makeEntry(id: 1, recordedAt: DateTime(2026, 1, 15, 8)),
        _makeEntry(id: 2, recordedAt: DateTime(2026, 1, 15, 12)),
        _makeEntry(id: 3, recordedAt: DateTime(2026, 1, 15, 20)),
      ];
      final groups = TimelineNotifier.buildGroupsForTest(entries, TimelineFilter.all);
      expect(groups.length, 1);
      expect(groups.first.entries.length, 3);
    });

    test('다른 날짜 3건 → DayGroup 3개', () {
      final entries = [
        _makeEntry(id: 1, recordedAt: DateTime(2026, 1, 13, 9)),
        _makeEntry(id: 2, recordedAt: DateTime(2026, 1, 14, 9)),
        _makeEntry(id: 3, recordedAt: DateTime(2026, 1, 15, 9)),
      ];
      final groups = TimelineNotifier.buildGroupsForTest(entries, TimelineFilter.all);
      expect(groups.length, 3);
    });

    test('그룹 내 entries는 시간 오름차순 정렬', () {
      final entries = [
        _makeEntry(id: 1, recordedAt: DateTime(2026, 1, 15, 20)),
        _makeEntry(id: 2, recordedAt: DateTime(2026, 1, 15, 8)),
        _makeEntry(id: 3, recordedAt: DateTime(2026, 1, 15, 14)),
      ];
      final groups = TimelineNotifier.buildGroupsForTest(entries, TimelineFilter.all);
      final hours = groups.first.entries.map((e) => e.recordedAt.hour).toList();
      expect(hours, [8, 14, 20]);
    });

    test('그룹 목록은 날짜 내림차순 정렬 (최신 우선)', () {
      final entries = [
        _makeEntry(id: 1, recordedAt: DateTime(2026, 1, 13, 9)),
        _makeEntry(id: 2, recordedAt: DateTime(2026, 1, 15, 9)),
        _makeEntry(id: 3, recordedAt: DateTime(2026, 1, 14, 9)),
      ];
      final groups = TimelineNotifier.buildGroupsForTest(entries, TimelineFilter.all);
      expect(groups[0].date, DateTime(2026, 1, 15));
      expect(groups[1].date, DateTime(2026, 1, 14));
      expect(groups[2].date, DateTime(2026, 1, 13));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 필터 조건별 결과
  // ─────────────────────────────────────────────────────────────────────────

  group('buildGroupsForTest() — 필터 조건', () {
    // good(0)·okay(1)·bad(2) visited=true, visited=false, visited=null 각 1건
    late List<Entry> mixedEntries;

    setUp(() {
      mixedEntries = [
        _makeEntry(
          id: 1,
          recordedAt: DateTime(2026, 1, 10, 9),
          visited: true,
          mood: MoodLevel.good.index,
        ),
        _makeEntry(
          id: 2,
          recordedAt: DateTime(2026, 1, 11, 9),
          visited: true,
          mood: MoodLevel.okay.index,
        ),
        _makeEntry(
          id: 3,
          recordedAt: DateTime(2026, 1, 12, 9),
          visited: true,
          mood: MoodLevel.bad.index,
        ),
        _makeEntry(id: 4, recordedAt: DateTime(2026, 1, 13, 9), visited: false),
        _makeEntry(id: 5, recordedAt: DateTime(2026, 1, 14, 9), visited: null),
      ];
    });

    test('all 필터 → 전체 5건 반환', () {
      final groups =
          TimelineNotifier.buildGroupsForTest(mixedEntries, TimelineFilter.all);
      final total = groups.fold(0, (s, g) => s + g.entries.length);
      expect(total, 5);
    });

    test('good 필터 → visited=true && mood=0 인 1건만', () {
      final groups =
          TimelineNotifier.buildGroupsForTest(mixedEntries, TimelineFilter.good);
      final total = groups.fold(0, (s, g) => s + g.entries.length);
      expect(total, 1);
      expect(groups.first.entries.first.mood, MoodLevel.good.index);
    });

    test('okay 필터 → visited=true && mood=1 인 1건만', () {
      final groups =
          TimelineNotifier.buildGroupsForTest(mixedEntries, TimelineFilter.okay);
      final total = groups.fold(0, (s, g) => s + g.entries.length);
      expect(total, 1);
      expect(groups.first.entries.first.mood, MoodLevel.okay.index);
    });

    test('bad 필터 → visited=true && mood=2 인 1건만', () {
      final groups =
          TimelineNotifier.buildGroupsForTest(mixedEntries, TimelineFilter.bad);
      final total = groups.fold(0, (s, g) => s + g.entries.length);
      expect(total, 1);
      expect(groups.first.entries.first.mood, MoodLevel.bad.index);
    });

    test('visited 필터 → visited=true 인 3건', () {
      final groups = TimelineNotifier.buildGroupsForTest(
        mixedEntries,
        TimelineFilter.visited,
      );
      final total = groups.fold(0, (s, g) => s + g.entries.length);
      expect(total, 3);
      for (final g in groups) {
        for (final e in g.entries) {
          expect(e.visited, true);
        }
      }
    });

    test('notVisited 필터 → visited != true (false·null) 인 2건', () {
      final groups = TimelineNotifier.buildGroupsForTest(
        mixedEntries,
        TimelineFilter.notVisited,
      );
      final total = groups.fold(0, (s, g) => s + g.entries.length);
      expect(total, 2);
      for (final g in groups) {
        for (final e in g.entries) {
          expect(e.visited, isNot(true));
        }
      }
    });

    test('필터 결과 없으면 빈 리스트', () {
      final onlyGood = [
        _makeEntry(
          id: 1,
          recordedAt: DateTime(2026, 1, 15, 9),
          visited: true,
          mood: MoodLevel.good.index,
        ),
      ];
      final groups =
          TimelineNotifier.buildGroupsForTest(onlyGood, TimelineFilter.bad);
      expect(groups, isEmpty);
    });
  });
}
