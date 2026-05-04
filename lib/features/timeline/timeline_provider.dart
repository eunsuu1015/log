// 기록 탭의 상태·데이터 Provider 모음.
// 필터 상태, 날짜별 그룹 모델, 기록 조회·정렬·그룹화 로직을 담당한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';

// ---------------------------------------------------------------------------
// 필터 상태
// ---------------------------------------------------------------------------

/// null = 전체, MoodLover = 해당 기분만, _visitedFalse sentinel = "안 감"만
enum TimelineFilter { all, good, okay, bad, visited, notVisited }

extension TimelineFilterExt on TimelineFilter {
  String label() => switch (this) {
    TimelineFilter.all => '전체',
    TimelineFilter.good => '좋음',
    TimelineFilter.okay => '보통',
    TimelineFilter.bad => '나쁨',
    TimelineFilter.visited => '다녀옴',
    TimelineFilter.notVisited => '안 감',
  };

  String labelEn() => switch (this) {
    TimelineFilter.all => 'All',
    TimelineFilter.good => 'Good',
    TimelineFilter.okay => 'Okay',
    TimelineFilter.bad => 'Bad',
    TimelineFilter.visited => 'Visited',
    TimelineFilter.notVisited => 'Not visited',
  };
}

final timelineFilterProvider = StateProvider<TimelineFilter>(
  (_) => TimelineFilter.all,
);

// ---------------------------------------------------------------------------
// 날짜 그룹 모델
// ---------------------------------------------------------------------------

/// 같은 날짜의 기록을 묶은 그룹 모델. 타임라인 리스트 렌더링에 사용된다.
class DayGroup {
  final DateTime date;
  final List<Entry> entries;
  const DayGroup({required this.date, required this.entries});
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// 전체 기록을 날짜 내림차순(최신 먼저)으로 그룹화
final timelineProvider = FutureProvider<List<DayGroup>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final filter = ref.watch(timelineFilterProvider);

  final List<Entry> all;
  try {
    all = await db.getEntriesInRange(
      DateTime(2026),
      DateTime(DateTime.now().year + 1),
    );
  } catch (e, s) {
    rethrow;
  }

  // 필터 적용
  final filtered = all.where((e) {
    return switch (filter) {
      TimelineFilter.all => true,
      TimelineFilter.good =>
        e.visited == true && e.mood == MoodLevel.good.index,
      TimelineFilter.okay =>
        e.visited == true && e.mood == MoodLevel.okay.index,
      TimelineFilter.bad => e.visited == true && e.mood == MoodLevel.bad.index,
      TimelineFilter.visited => e.visited == true,
      TimelineFilter.notVisited => e.visited != true,
    };
  }).toList();

  // 내림차순 정렬 (최신 먼저)
  filtered.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  // 날짜별 그룹
  final Map<DateTime, List<Entry>> grouped = {};
  for (final e in filtered) {
    final day = DateTime(
      e.recordedAt.year,
      e.recordedAt.month,
      e.recordedAt.day,
    );
    grouped.putIfAbsent(day, () => []).add(e);
  }

  return grouped.entries
      .map((e) => DayGroup(date: e.key, entries: e.value))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// 타임라인에서 특정 기록 수정 후 갱신
final timelineRefreshProvider = StateProvider<int>((_) => 0);
