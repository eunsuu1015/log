// 기록 탭의 상태·데이터 Provider 모음.
// 필터 상태, 날짜별 그룹 모델, 기록 조회·정렬·그룹화 로직을 담당한다.
// 초기 로드: 최근 3개월 / 더 불러오기: 3개월씩 확장

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';

import '../../utils/logger.dart';

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
// 타임라인 상태 모델
// ---------------------------------------------------------------------------

class TimelineState {
  final List<DayGroup> groups;

  /// 현재까지 로드된 범위의 시작 날짜
  final DateTime rangeStart;

  /// 앱 시작일(2026-01-01) 이전 데이터가 남아있는지 여부
  final bool hasMore;

  /// loadMore() 진행 중 여부
  final bool isLoadingMore;

  const TimelineState({
    required this.groups,
    required this.rangeStart,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  TimelineState copyWith({
    List<DayGroup>? groups,
    DateTime? rangeStart,
    bool? hasMore,
    bool? isLoadingMore,
  }) => TimelineState(
    groups: groups ?? this.groups,
    rangeStart: rangeStart ?? this.rangeStart,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

// ---------------------------------------------------------------------------
// AsyncNotifier
// ---------------------------------------------------------------------------

class TimelineNotifier extends AsyncNotifier<TimelineState> {
  static const _chunkMonths = 6;
  static final _appStart = DateTime(2026, 5);

  @override
  Future<TimelineState> build() async {
    final db = ref.watch(appDatabaseProvider);
    final filter = ref.watch(timelineFilterProvider);
    final now = DateTime.now();

    // 이번 달 포함 최근 6개월
    final rangeStart = DateTime(now.year, now.month - (_chunkMonths - 1));
    final rangeEnd = DateTime(now.year, now.month, now.day + 1);

    final entries = await db.getEntriesInRange(rangeStart, rangeEnd);
    final groups = _toGroups(entries, filter);

    return TimelineState(
      groups: groups,
      rangeStart: rangeStart,
      hasMore: rangeStart.isAfter(_appStart),
    );
  }

  /// 6개월씩 이전 데이터를 추가 로드한다.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final db = ref.read(appDatabaseProvider);
    final filter = ref.read(timelineFilterProvider);

    final newStart = DateTime(
      current.rangeStart.year,
      current.rangeStart.month - _chunkMonths,
    );
    final clampedStart = newStart.isBefore(_appStart) ? _appStart : newStart;

    logger.d('[Timeline] loadMore $clampedStart ~ ${current.rangeStart}');

    final entries = await db.getEntriesInRange(
      clampedStart,
      current.rangeStart,
    );
    final newGroups = _toGroups(entries, filter);

    final merged = [...current.groups, ...newGroups]
      ..sort((a, b) => b.date.compareTo(a.date));

    state = AsyncData(
      current.copyWith(
        groups: merged,
        rangeStart: clampedStart,
        hasMore: clampedStart.isAfter(_appStart),
        isLoadingMore: false,
      ),
    );
  }

  /// 필터를 적용한 뒤 Entry 목록을 날짜별 DayGroup 리스트로 변환한다.
  /// 그룹 내 entries는 시간 오름차순, 반환 목록은 날짜 내림차순(최신 우선)으로 정렬된다.
  List<DayGroup> _toGroups(List<Entry> entries, TimelineFilter filter) {
    final filtered =
        entries
            .where(
              (e) => switch (filter) {
                TimelineFilter.all => true,
                TimelineFilter.good =>
                  e.visited == true && e.mood == MoodLevel.good.index,
                TimelineFilter.okay =>
                  e.visited == true && e.mood == MoodLevel.okay.index,
                TimelineFilter.bad =>
                  e.visited == true && e.mood == MoodLevel.bad.index,
                TimelineFilter.visited => e.visited == true,
                TimelineFilter.notVisited => e.visited != true,
              },
            )
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

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
  }
}

final timelineProvider = AsyncNotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);
