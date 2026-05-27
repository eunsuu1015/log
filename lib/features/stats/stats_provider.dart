// 통계 탭의 데이터 계산 Provider.
// 기간 범위(StatsRange)를 기반으로 방문 횟수·기분 분포·시간대 분포를 집계한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';

/// 통계 조회 기간 종류
enum StatsPeriod { thisMonth, last30, last90, custom }

/// 통계 조회 기간 설정값. period에 따라 from/to 날짜를 계산한다.
class StatsRange {
  final StatsPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;

  StatsRange({required this.period, this.customFrom, this.customTo});

  /// period에 따라 조회 시작(from)-종료(to) DateTIme을 계산해 반환한다.
  ({DateTime from, DateTime to}) get dateRange {
    final now = DateTime.now();
    return switch (period) {
      StatsPeriod.thisMonth => (
        from: DateTime(now.year, now.month),
        to: DateTime(now.year, now.month, now.day + 1), // 오늘까지만
      ),
      StatsPeriod.last30 => (
        from: DateTime(now.year, now.month, now.day - 29), // 오늘 포함 30일
        to: DateTime(now.year, now.month, now.day + 1), // exclusive
      ),
      StatsPeriod.last90 => (
        from: DateTime(now.year, now.month, now.day - 89), // 오늘 포함 90일
        to: DateTime(now.year, now.month, now.day + 1), // exclusive
      ),
      StatsPeriod.custom => (
        from: customFrom ?? DateTime(now.year, now.month),
        to: customTo ?? now,
      ),
    };
  }
}

/// 통계 계산 결과 값 객체. fromEntries 팩토리로Entry 목록에서 집계한다.
class StatsResult {
  final int totalVisits;
  final Map<MoodLevel, int> moodCounts;
  final List<int> hourlyCounts; // 0~23
  final List<int> peakHours; // 공동 최대 시간대 목록
  final int totalDays; // 조회 기간 일수
  final int visitedDays; // 하루 1회 이상 방문한 날 수

  const StatsResult({
    required this.totalVisits,
    required this.moodCounts,
    required this.hourlyCounts,
    required this.peakHours,
    required this.totalDays,
    required this.visitedDays,
  });

  /// Entry 목록에서 방문 횟수, 기분 분포, 시간대 분포, 피크 시간을 집계한다.
  /// visited == true인 항목만 통계에 포함된다.
  factory StatsResult.fromEntries(
    List<Entry> entries, {
    required int totalDays,
  }) {
    final visited = entries.where((e) => e.visited == true).toList();
    final moodCounts = <MoodLevel, int>{};
    final hourlyCounts = List<int>.filled(24, 0);

    for (final e in visited) {
      hourlyCounts[e.recordedAt.hour]++;
      if (e.mood != null) {
        final m = MoodLevel.values[e.mood!];
        moodCounts[m] = (moodCounts[m] ?? 0) + 1;
      }
    }

    final peakCount = hourlyCounts.reduce((a, b) => a > b ? a : b);
    final peakHours = peakCount > 0
        ? [for (int h = 0; h < 24; h++) if (hourlyCounts[h] == peakCount) h]
        : <int>[];

    final visitedDays = visited
        .map(
          (e) =>
              DateTime(e.recordedAt.year, e.recordedAt.month, e.recordedAt.day),
        )
        .toSet()
        .length;

    return StatsResult(
      totalVisits: visited.length,
      moodCounts: moodCounts,
      hourlyCounts: hourlyCounts,
      peakHours: peakHours,
      totalDays: totalDays,
      visitedDays: visitedDays,
    );
  }
}

final statsRangeProvider = StateProvider<StatsRange>(
  (_) => StatsRange(period: StatsPeriod.thisMonth),
);

/// 선택된 기간(statsRangeProvider)의 기록을 집계해 StatsResult를 반환한다.
/// statsRangeProvider가 변경되면 자동으로 재계산된다.
final statsResultProvider = FutureProvider<StatsResult>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final range = ref.watch(statsRangeProvider);
  final dr = range.dateRange;
  final totalDays = dr.to.difference(dr.from).inDays;

  final entries = await db.getEntriesInRange(dr.from, dr.to);
  return StatsResult.fromEntries(entries, totalDays: totalDays);
});
