// 시간대별 방문 히트맵 그리드 + 상세 바텀시트
// 격자(6×4)와 DraggableScrollableSheet 바 차트에서 동일한 heatColor 함수를 공유한다.

import 'package:flutter/material.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

// ── 히트맵 단계별 색상 (비율 기준, 초록 계열) ────────────────────────────────
const _kHeat1 = Color(0xFFD4EDDF); //  1 ~ 25%  (연한 민트 그린)
const _kHeat2 = Color(0xFF7DC4A0); // 26 ~ 50%  (라이트 그린)
const _kHeat3 = Color(0xFF3DA06C); // 51 ~ 75%  (AppTheme.moodGood)
const _kHeat4 = Color(0xFF1B5E3A); // 76 ~100%  (다크 포레스트 그린)

// ── 시간대 그룹 (상세 바텀시트용) ────────────────────────────────────────────
const _kGroups = <(String, List<int>)>[
  ('새벽', [0, 1, 2, 3, 4, 5]),
  ('아침', [6, 7, 8, 9, 10, 11]),
  ('오후', [12, 13, 14, 15, 16, 17]),
  ('저녁', [18, 19, 20, 21, 22, 23]),
];

// ── 범례 색상 순서 ─────────────────────────────────────────────────────────
// surfaceContainerHighest는 런타임에 결정되므로 직접 BuildContext에서 가져온다.
const _kLegendColors = [_kHeat1, _kHeat2, _kHeat3, _kHeat4];

// ---------------------------------------------------------------------------
// 메인 위젯
// ---------------------------------------------------------------------------

/// 시간대별 방문 횟수 히트맵 그리드 (6열 × 4행, 총 24칸).
///
/// [hourlyCounts] index = 시(0~23), value = 방문 횟수.
/// 최다 방문 시간대 셀에 primary 테두리를 강조하고,
/// 헤더에 타이틀·범례·"자세히 보기" 버튼을 함께 표시한다.
class StatHeatMapGrid extends StatelessWidget {
  final List<int> hourlyCounts;

  const StatHeatMapGrid({super.key, required this.hourlyCounts});

  /// hourlyCounts 비율 기반 히트맵 색상.
  /// 격자(기본 화면)와 바 차트(상세 시트)에서 공통으로 사용한다.
  static Color heatColor(int count, int maxCount, ColorScheme cs) {
    if (count == 0 || maxCount == 0) return cs.surfaceContainerHighest;
    final ratio = count / maxCount;
    if (ratio <= 0.25) return _kHeat1;
    if (ratio <= 0.50) return _kHeat2;
    if (ratio <= 0.75) return _kHeat3;
    return _kHeat4;
  }

  /// 범례에 사용되는 10×10 색상 박스 위젯을 반환한다.
  static Widget _legendBox(Color color) => Container(
    width: 10,
    height: 10,
    margin: const EdgeInsets.only(left: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  /// 데이터가 있는 그룹·바 수를 기반으로 시트 높이 비율을 계산한다.
  /// min/max/initial을 동일한 값으로 설정해 시트 크기를 고정한다.
  double _calcFixedSize(BuildContext context) {
    var groupCount = 0;
    var barCount = 0;
    for (final (_, hours) in _kGroups) {
      final active = hours.where((h) => hourlyCounts[h] > 0).length;
      if (active > 0) {
        groupCount++;
        barCount += active;
      }
    }

    // useSafeArea: true 로 인해 DraggableScrollableSheet 비율은
    // (화면 높이 - 하단 OS 영역) 기준으로 계산해야 한다.
    final screenH = MediaQuery.sizeOf(context).height;
    final topPad = MediaQuery.viewPaddingOf(context).top;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final availableH = screenH - topPad - bottomPad;

    // 구성 요소별 높이 추정 (축소된 레이아웃 기준)
    const headerH = 56.0; // 헤더 Row + 패딩
    const dividerH = 1.0;
    const listTopH = 8.0;
    const groupLabelH = 29.0; // padding top 10 + text 16 + padding bottom 3
    const barH = 24.0; // height 16 + padding bottom 4
    const listBottomH = 16.0; // ListView bottom padding (SafeArea 가 OS 영역 처리)
    const listPadding = 32.0;

    const bufferH = 32.0; // 추정 오차 보정 여유분

    final contentH =
        headerH +
        dividerH +
        listTopH +
        (groupCount * groupLabelH) +
        (barCount * barH) +
        listBottomH +
        listPadding +
        bufferH;

    return (contentH / availableH).clamp(0.40, 1.0);
  }

  /// 고정 높이 바텀시트로 시간대 상세 차트를 표시한다.
  void _showDetailSheet(BuildContext context) {
    final size = _calcFixedSize(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: size,
        minChildSize: size,
        maxChildSize: size,
        expand: false,
        builder: (_, ctrl) => _HourDetailSheet(
          hourlyCounts: hourlyCounts,
          scrollController: ctrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final maxCount = hourlyCounts.reduce((a, b) => a > b ? a : b);
    final hasData = maxCount > 0;
    final peakHours = hasData
        ? [
            for (int h = 0; h < 24; h++)
              if (hourlyCounts[h] == maxCount) h,
          ]
        : <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 헤더: 타이틀(좌) + 범례 + 자세히 보기 버튼(우) ──────────────
        Row(
          children: [
            Text(
              '시간대별 방문',
              style: context.tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // 범례: 적음 ■□□□□ 많음
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '적음',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 2),
                _legendBox(cs.surfaceContainerHighest),
                for (final c in _kLegendColors) _legendBox(c),
                const SizedBox(width: 2),
                Text(
                  '많음',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: hasData ? () => _showDetailSheet(context) : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '자세히 보기 ↑',
                style: context.tt.labelMedium?.copyWith(
                  color: hasData ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── 피크 시간 요약 ────────────────────────────────────────────────
        if (hasData) ...[
          _PeakTimeSummary(peakHours: peakHours, maxCount: maxCount),
          const SizedBox(height: 10),
        ],
        // ── 6×4 히트맵 격자 ──────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.6,
          ),
          itemCount: 24,
          itemBuilder: (_, h) {
            final count = hourlyCounts[h];
            final color = heatColor(count, maxCount, cs);
            final isPeak = hasData && peakHours.contains(h);
            return Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                      border: isPeak
                          ? Border.all(color: cs.primary, width: 1.5)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$h',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 피크 시간 요약
// ---------------------------------------------------------------------------

const _kChipBg = Color(0xFFE6F1FB);

/// 히트맵 헤더 아래에 표시되는 피크 시간대 요약 카드.
/// 단일 피크·2개 동률·3개 이상 동률 케이스를 구분해 렌더링한다.
class _PeakTimeSummary extends StatelessWidget {
  final List<int> peakHours;
  final int maxCount;

  const _PeakTimeSummary({required this.peakHours, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final n = peakHours.length;

    final subLabel = n == 1
        ? '이 시간에 $maxCount회 방문'
        : n == 2
        ? '각 $maxCount회로 동률'
        : '$n개 시간대 동률';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (n == 1)
            _SinglePeak(hour: peakHours[0], cs: cs)
          else
            _MultiPeak(peakHours: peakHours, cs: cs),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '가장 많이 방문한 시간',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: TextStyle(fontSize: 10, color: cs.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 단일 피크: 큰 숫자(28sp bold primary) + "시"(14sp)
class _SinglePeak extends StatelessWidget {
  final int hour;
  final ColorScheme cs;

  const _SinglePeak({required this.hour, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$hour',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: cs.primary,
            height: 1,
          ),
        ),
        const SizedBox(width: 1),
        Text('시', style: TextStyle(fontSize: 14, color: cs.primary)),
      ],
    );
  }
}

/// 다중 피크: 앞 2개 칩 + (3개 이상이면 "+N" 뱃지), "·" 구분자
class _MultiPeak extends StatelessWidget {
  final List<int> peakHours;
  final ColorScheme cs;

  const _MultiPeak({required this.peakHours, required this.cs});

  Widget _chip(int hour) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _kChipBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$hour',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.primary,
            height: 1,
          ),
        ),
        Text('시', style: TextStyle(fontSize: 11, color: cs.primary)),
      ],
    ),
  );

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      '·',
      style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final extra = peakHours.length - 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(peakHours[0]),
        _dot(),
        _chip(peakHours[1]),
        if (extra > 0) ...[
          _dot(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kChipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$extra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary,
                height: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 시간대 상세 바텀시트
// ---------------------------------------------------------------------------

/// DraggableScrollableSheet 내부에 표시되는 시간대별 방문 수평 바 차트.
/// 기록 있는 시간대만 그룹(새벽/아침/오후/저녁)별로 나열하며,
/// 최다 방문 시간대에 "최다" 뱃지를 표시한다.
class _HourDetailSheet extends StatelessWidget {
  final List<int> hourlyCounts;
  final ScrollController scrollController;

  const _HourDetailSheet({
    required this.hourlyCounts,
    required this.scrollController,
  });

  String _hourLabel(int h) => '$h시';

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final maxCount = hourlyCounts.reduce((a, b) => a > b ? a : b);
    final peakHours = maxCount > 0
        ? [
            for (int h = 0; h < 24; h++)
              if (hourlyCounts[h] == maxCount) h,
          ]
        : <int>[];
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 4, 8),
              child: Row(
                children: [
                  Text(
                    '시간대별 방문',
                    style: context.tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 그룹별 바 차트 목록
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: _buildBars(context, cs, maxCount, peakHours),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 그룹(오전/오후/저녁/밤)별로 묶인 수평 바 차트 위젯 목록을 반환한다.
  List<Widget> _buildBars(
    BuildContext context,
    ColorScheme cs,
    int maxCount,
    List<int> peakHours,
  ) {
    final items = <Widget>[];

    for (final (groupLabel, hours) in _kGroups) {
      final activeHours = hours.where((h) => hourlyCounts[h] > 0).toList();
      if (activeHours.isEmpty) continue;

      // 그룹 레이블
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 3),
          child: Text(
            groupLabel,
            style: context.tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      );

      // 시간대별 바
      for (final h in activeHours) {
        final count = hourlyCounts[h];
        final barColor = StatHeatMapGrid.heatColor(count, maxCount, cs);
        final isPeak = peakHours.contains(h);
        final ratio = maxCount > 0 ? count / maxCount : 0.0;

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // 시간 레이블 (고정폭)
                SizedBox(
                  width: 32,
                  child: Text(
                    _hourLabel(h),
                    style: TextStyle(fontSize: 11, color: cs.onSurface),
                  ),
                ),
                const SizedBox(width: 6),
                // 수평 바
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, box) => SizedBox(
                      height: 16,
                      child: Stack(
                        children: [
                          // 배경
                          Container(
                            width: box.maxWidth,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // 색상 바
                          Container(
                            width: box.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 횟수
                SizedBox(
                  width: 26,
                  child: Text(
                    '$count회',
                    style: TextStyle(fontSize: 11, color: cs.onSurface),
                    textAlign: TextAlign.right,
                  ),
                ),
                // "최다" 뱃지 (없으면 동일 폭의 빈 공간으로 레이아웃 안정화)
                const SizedBox(width: 4),
                if (isPeak)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kHeat1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '최다',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kHeat4,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 34),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }
}
