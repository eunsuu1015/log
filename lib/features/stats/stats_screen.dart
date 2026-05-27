// 통계 화면 — 기간별 방문 횟수·기분 분포·시간대별 차트를 표시한다.
// 기분 색상·레이블은 MoodLevelX 확장(entry_ext.dart)을 통해 가져온다.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/ads/banner_ad_widget.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/stats/stats_provider.dart';
import 'package:poopoolog/shared/widgets/mood_indicator.dart';
import 'package:poopoolog/features/record/record_provider.dart';
import 'package:poopoolog/features/record/record_screen.dart';

import '../../shared/theme/app_theme.dart';
import '../calendar/calendar_provider.dart';
import '../timeline/timeline_provider.dart';
import 'widgets/stat_heat_map_grid.dart';
import 'widgets/summary_card.dart';

// ---------------------------------------------------------------------------
// Ghost UI용 더미 데이터
// ---------------------------------------------------------------------------

/// 기록이 없는 신규 유저에게 통계 ghost UI를 미리 보여주기 위한 더미 데이터.
const _ghostStats = StatsResult(
  totalVisits: 12,
  moodCounts: {MoodLevel.good: 6, MoodLevel.okay: 4, MoodLevel.bad: 2},
  hourlyCounts: [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    5,
    0,
    0,
    0,
    4,
    0,
    0,
    0,
    0,
    3,
    0,
    0,
    0,
    0,
    0,
  ],
  peakHours: [9],
  totalDays: 30,
  visitedDays: 8,
);

// ---------------------------------------------------------------------------

/// 통계 탭 루트 화면. 기간 선택 칩과 통계 본문으로 구성된다.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsResultProvider);
    final range = ref.watch(statsRangeProvider);
    final earliestAsync = ref.watch(earliestEntryDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: Column(
        children: [
          _PeriodChips(current: range),
          _DateRangeLabel(range: range),
          const Divider(height: 1),
          Expanded(
            child: statsAsync.when(
              data: (result) {
                if (result.totalVisits == 0) {
                  return earliestAsync.when(
                    data: (earliest) => earliest == null
                        ? _StatsGhostEmptyState(
                            onPressed: () {
                              ref.invalidate(recordFormProvider(null));
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecordScreen(),
                                  fullscreenDialog: true,
                                ),
                              ).then((_) {
                                ref.invalidate(statsResultProvider);
                                ref.invalidate(earliestEntryDateProvider);
                                ref.invalidate(monthlyEntriesProvider);
                                ref.invalidate(timelineProvider);
                              });
                            },
                          )
                        : const _StatsEmptyState(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const _StatsEmptyState(),
                  );
                }
                return _StatsBody(result: result);
              },
              error: (e, _) => Center(child: Text('오류: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 기간 선택 칩
// ---------------------------------------------------------------------------

/// 기간 선택 칩 행 (이번 달 / 최근 30일 / 최근 3개월 / 직접 지정)
class _PeriodChips extends ConsumerWidget {
  final StatsRange current;

  const _PeriodChips({required this.current});

  static const _labels = {
    StatsPeriod.thisMonth: '이번 달',
    StatsPeriod.last30: '최근 30일',
    StatsPeriod.last90: '최근 90일',
    StatsPeriod.custom: '직접 지정',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeColor = context.cs.primary;
    const periods = StatsPeriod.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SizedBox(
        height: 40,
        child: Row(
          children: periods.asMap().entries.map((entry) {
            final i = entry.key;
            final period = entry.value;
            final isSelected = current.period == period;
            final labelColor = isSelected
                ? activeColor
                : context.cs.onSurfaceVariant;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0.0 : 2.5,
                  right: i == periods.length - 1 ? 0.0 : 2.5,
                ),
                child: InkWell(
                  onTap: () async {
                    if (period == StatsPeriod.custom) {
                      await _pickCustomRange(context, ref);
                    } else {
                      ref.read(statsRangeProvider.notifier).state = StatsRange(
                        period: period,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? activeColor
                            : context.cs.outlineVariant,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 12, color: activeColor),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          _labels[period]!,
                          style: context.tt.bodySmall?.copyWith(
                            color: labelColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 날짜 범위 피커를 열고 선택된 범위를 statsRangeProvider에 반영한다.
  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final isCustom = current.period == StatsPeriod.custom;
    final initialRange =
        isCustom && current.customFrom != null && current.customTo != null
        ? DateTimeRange(
            start: current.customFrom!,
            end: current.customTo!.subtract(const Duration(days: 1)),
          )
        : DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024), // 2026 하드코딩 제거 — 테스트 데이터(2025-10~)도 포함 가능하게
      lastDate: now,
      initialDateRange: initialRange,
    );
    if (picked != null) {
      ref.read(statsRangeProvider.notifier).state = StatsRange(
        period: StatsPeriod.custom,
        customFrom: picked.start,
        customTo: picked.end.add(const Duration(days: 1)),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// 날짜 범위 레이블
// ---------------------------------------------------------------------------

class _DateRangeLabel extends StatelessWidget {
  final StatsRange range;
  const _DateRangeLabel({required this.range});

  static String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dr = range.dateRange;
    final displayEnd = dr.to.subtract(const Duration(days: 1));
    final dayCount = displayEnd.difference(dr.from).inDays + 1;
    final label = '${_fmt(dr.from)} ~ ${_fmt(displayEnd)} ($dayCount일)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.tt.bodySmall,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 통계 본문
// ---------------------------------------------------------------------------

/// 통계 데이터가 있을 때 표시되는 본문 (요약 카드 + 차트)
class _StatsBody extends StatelessWidget {
  final StatsResult result;

  const _StatsBody({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SummaryCard(
                  emoji: '📅',
                  value: '${result.visitedDays}일',
                  label: '${result.totalDays}일 중 방문한 날',
                  progress: result.totalDays > 0
                      ? result.visitedDays / result.totalDays
                      : 0.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  emoji: '💩',
                  value: '${result.totalVisits}회',
                  label: '${result.totalDays}일 동안 방문 횟수',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (result.moodCounts.isNotEmpty) ...[
          Text(
            '기분 분포',
            style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _MoodDonutChart(moodCounts: result.moodCounts),
          const SizedBox(height: 20),
        ],
        StatHeatMapGrid(hourlyCounts: result.hourlyCounts),
        const SizedBox(height: 16),
      ],
    );
  }
}


class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            '이 기간에 기록이 없어요',
            style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '다른 기간을 선택하거나 기록을 추가해보세요',
            style: context.tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 기분별 방문 횟수 도넛 차트.
class _MoodDonutChart extends StatelessWidget {
  final Map<MoodLevel, int> moodCounts;
  const _MoodDonutChart({required this.moodCounts});

  @override
  Widget build(BuildContext context) {
    final total = moodCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = MoodLevel.values
        .where((m) => (moodCounts[m] ?? 0) > 0)
        .map((m) {
          final count = moodCounts[m]!;
          final pct = count / total * 100;
          return PieChartSectionData(
            value: count.toDouble(),
            color: m.color,
            title: '${pct.toStringAsFixed(0)}%',
            titleStyle: context.tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            radius: 36,
          );
        })
        .toList();

    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 14,
                sectionsSpace: 2,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: MoodLevel.values.map((m) {
              final count = moodCounts[m] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    MoodIndicator(mood: m, visited: true, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${m.label}  $count회',
                      style: context.tt.bodySmall?.copyWith(
                        color: context.cs.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ghost 빈 상태 (기록 0건인 신규 유저)
// ---------------------------------------------------------------------------

/// 기록이 없는 신규 유저에게 통계 화면을 ghost UI로 미리 보여주는 위젯.
/// 실제 통계 본문(_StatsBody)을 더미 데이터로 렌더링해 흐릿하게 표시하고,
/// 중앙에 잠금 배지와 CTA 버튼을 오버레이한다.
class _StatsGhostEmptyState extends StatelessWidget {
  final VoidCallback onPressed;
  const _StatsGhostEmptyState({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Stack(
      alignment: Alignment.center,
      children: [
        // 레이어 1: 더미 통계 (흐릿하게, 터치 차단)
        const IgnorePointer(
          child: Opacity(opacity: 0.22, child: _StatsBody(result: _ghostStats)),
        ),
        // 레이어 2: 잠금 배지 + CTA 오버레이
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '기록하면 통계가 열려요',
                    style: context.tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('첫 기록 남기기'),
            ),
          ],
        ),
      ],
    );
  }
}
