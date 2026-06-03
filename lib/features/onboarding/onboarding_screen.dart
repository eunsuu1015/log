// 앱 최초 실행 시 표시되는 온보딩 가이드 화면.
// 3장 슬라이드로 주요 기능(기록·캘린더·통계)을 실제 UI 미리보기 위젯과 함께 소개한다.
// fromSettings=true이면 더보기 화면에서 열린 것으로, X 버튼으로 닫기만 한다.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

import '../shell/app_shell.dart';

/// SharedPreferences 키 — 온보딩 완료 여부
const kOnboardingSeenKey = 'onboarding_seen';

// ---------------------------------------------------------------------------
// 슬라이드 타입 및 데이터
// ---------------------------------------------------------------------------

enum _SlideType { record, calendar, stats }

class _PageData {
  final _SlideType type;
  final String title;
  final String description;

  const _PageData({
    required this.type,
    required this.title,
    required this.description,
  });
}

const _kPages = [
  _PageData(
    type: _SlideType.record,
    title: '간편하게 기록해요',
    description: '화면 하단 + 버튼으로\n방문 여부, 기분, 메모를 남길 수 있어요.',
  ),
  _PageData(
    type: _SlideType.calendar,
    title: '기분 흐름을 한눈에',
    description: '캘린더에서 날짜별 색상 도트로\n기분 패턴을 한눈에 파악할 수 있어요.',
  ),
  _PageData(
    type: _SlideType.stats,
    title: '나만의 패턴을 발견해요',
    description: '주로 몇 시에 방문하는지,\n어떤 기분이 많은지 통계로 확인해요.',
  ),
];

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

/// 온보딩 가이드 화면.
/// [fromSettings]가 true이면 더보기 화면에서 열린 것으로, 완료 시 pop한다.
class OnboardingScreen extends StatefulWidget {
  final bool fromSettings;

  const OnboardingScreen({super.key, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 온보딩 완료 처리. 최초 실행이면 SharedPreferences에 완료 기록 후 AppShell로 전환.
  Future<void> _complete() async {
    if (widget.fromSettings) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// 다음 페이지로 이동하거나 마지막 페이지에서 완료 처리.
  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final isLast = _currentPage == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단: 건너뛰기 or 닫기 버튼 ──────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                child: widget.fromSettings
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    : TextButton(
                        onPressed: _complete,
                        child: Text(
                          '건너뛰기',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
              ),
            ),

            // ── 슬라이드 영역 ─────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideContent(data: _kPages[i]),
              ),
            ),

            // ── 페이지 인디케이터 ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageCount,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // ── 하단 버튼 ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? '시작하기' : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 슬라이드 콘텐츠 — 타입에 따라 미리보기 위젯을 분기한다
// ---------------------------------------------------------------------------

/// 미리보기 위젯·제목·설명으로 구성된 단일 온보딩 슬라이드.
class _SlideContent extends StatelessWidget {
  final _PageData data;

  const _SlideContent({required this.data});

  Widget _buildPreview() {
    switch (data.type) {
      case _SlideType.record:
        return const _RecordPreview();
      case _SlideType.calendar:
        return const _CalendarPreview();
      case _SlideType.stats:
        return const _StatsPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPreview(),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: context.tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            style: context.tt.bodyMedium?.copyWith(
              color: context.cs.onSurfaceVariant,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 슬라이드 1 — 기록 화면 미리보기
// 실제 RecordScreen의 화장실 스위치·기분 선택·메모 필드 스타일과 동일하게 구성한다.
// ---------------------------------------------------------------------------

/// 실제 기록 입력 화면(화장실 스위치·기분 버튼·메모 필드)을 축소 재현한 미리보기.
class _RecordPreview extends StatelessWidget {
  const _RecordPreview();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 화장실 스위치 (실제: Container + ListTile + Switch) ────────────
        Text('화장실', style: tt.labelMedium),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text('화장실에 다녀왔어요', style: tt.titleSmall),
            trailing: Transform.scale(
              scale: 0.8,
              child: Switch(
                value: true,
                onChanged: null,
                activeColor: cs.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            minVerticalPadding: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── 기분 선택 (실제: 색상 원 + 레이블, borderRadius 12) ────────────
        Text('기분', style: tt.labelMedium),
        const SizedBox(height: 6),
        Row(
          children: MoodLevel.values.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final sel = m == MoodLevel.good;
            final color = m.color;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i < MoodLevel.values.length - 1 ? 8 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? color.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.label,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? color : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── 메모 필드 (실제: filled TextField, borderRadius 12) ─────────────
        Text('메모', style: tt.labelMedium),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '자유롭게 기록하세요',
            style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 슬라이드 2 — 캘린더 미리보기
// 실제 CalendarScreen의 헤더·요일(월~일)·날짜+도트 구조를 재현한다.
// ---------------------------------------------------------------------------

/// 실제 캘린더 화면(헤더·요일 행·날짜+기분 도트)을 축소 재현한 미리보기.
class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview();

  // 날짜 → 기분 색상 샘플 (5월 기준)
  static const Map<int, Color> _dotData = {
    1: AppTheme.moodGood,
    2: AppTheme.moodOkay,
    4: AppTheme.moodGood,
    5: AppTheme.moodGood,
    6: AppTheme.moodBad,
    7: AppTheme.moodNone,
    8: AppTheme.moodGood,
    9: AppTheme.moodGood,
    11: AppTheme.moodOkay,
    12: AppTheme.moodGood,
    13: AppTheme.moodGood,
    14: AppTheme.moodGood,
    15: AppTheme.moodOkay,
  };

  // 온보딩 미리보기 시작 요일: 일요일
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 선택된 날짜 (15일)
  static const _selectedDay = 15;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 헤더: 실제와 동일하게 '2026년 5월 ▾' ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '2026년 5월',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),

          // ── 요일 헤더 (월화수목금토일) ───────────────────────────────────
          Row(
            children: _weekdays.map((d) {
              final isWeekend = d == '토' || d == '일';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: tt.labelSmall?.copyWith(
                      color: isWeekend ? cs.error : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // ── 날짜 + 도트 (3주 표시, rowHeight ≈ 50 축소) ────────────────
          ...List.generate(
            3,
            (week) => SizedBox(
              height: 44,
              child: Row(
                children: List.generate(7, (day) {
                  final date = week * 7 + day + 1;
                  final dotColor = _dotData[date];
                  final isSelected = date == _selectedDay;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 날짜 숫자 (선택된 날은 primary 원)
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '$date',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: isSelected ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 기분 도트
                        if (dotColor != null && !isSelected)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── 색상 범례 ────────────────────────────────────────────────────
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot('좋음', AppTheme.moodGood),
              SizedBox(width: 10),
              _LegendDot('보통', AppTheme.moodOkay),
              SizedBox(width: 10),
              _LegendDot('나쁨', AppTheme.moodBad),
              SizedBox(width: 10),
              _LegendDot('안 감', AppTheme.moodNone),
            ],
          ),
        ],
      ),
    );
  }
}

/// 색상 범례 아이템 (도트 + 레이블).
class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 슬라이드 3 — 통계 미리보기
// 실제 SummaryCard 스타일(그라디언트 배경)과 StatHeatMapGrid(6×4) 구조를 재현한다.
// ---------------------------------------------------------------------------

// 히트맵 단계 색상 (stat_heat_map_grid.dart와 동일)
const _kHeat1 = Color(0xFFD4EDDF);
const _kHeat2 = Color(0xFF7DC4A0);
const _kHeat3 = Color(0xFF3DA06C);
const _kHeat4 = Color(0xFF1B5E3A);

/// 실제 통계 화면(SummaryCard·6×4 히트맵)을 축소 재현한 미리보기.
class _StatsPreview extends StatelessWidget {
  const _StatsPreview();

  // 시간대별 히트맵 샘플 데이터
  static const _hourly = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    5,
    3,
    1,
    1,
    2,
    3,
    1,
    0,
    1,
    2,
    2,
    4,
    5,
    3,
    1,
    0,
  ];

  static Color _heatColor(int count, int maxCount, ColorScheme cs) {
    if (count == 0 || maxCount == 0) return cs.surfaceContainerHighest;
    final ratio = count / maxCount;
    if (ratio <= 0.25) return _kHeat1;
    if (ratio <= 0.50) return _kHeat2;
    if (ratio <= 0.75) return _kHeat3;
    return _kHeat4;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final maxCount = _hourly.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 요약 카드 2개 (실제 SummaryCard: 그라디언트 배경, borderRadius 14) ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.08),
                        cs.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📅', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            '18일',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('30일 중 방문한 날', style: tt.bodySmall),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 18 / 30,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.08),
                        cs.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💩', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            '34회',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('30일 동안 방문 횟수', style: tt.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 기분 분포 (도넛 차트 + 범례) ─────────────────────────────────
        Text(
          '기분 분포',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 12,
                        color: AppTheme.moodGood,
                        title: '55%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        radius: 30,
                      ),
                      PieChartSectionData(
                        value: 7,
                        color: AppTheme.moodOkay,
                        title: '32%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        radius: 30,
                      ),
                      PieChartSectionData(
                        value: 3,
                        color: AppTheme.moodBad,
                        title: '14%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        radius: 30,
                      ),
                    ],
                    centerSpaceRadius: 12,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MoodLegendRow('좋음', AppTheme.moodGood, '12회'),
                  SizedBox(height: 6),
                  _MoodLegendRow('보통', AppTheme.moodOkay, '7회'),
                  SizedBox(height: 6),
                  _MoodLegendRow('나쁨', AppTheme.moodBad, '3회'),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 히트맵 헤더 ──────────────────────────────────────────────────
        Row(
          children: [
            Text(
              '시간대별 방문',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '적음',
              style: TextStyle(
                fontSize: 9,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 2),
            _heatBox(cs.surfaceContainerHighest),
            _heatBox(_kHeat1),
            _heatBox(_kHeat2),
            _heatBox(_kHeat3),
            _heatBox(_kHeat4),
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
        const SizedBox(height: 10),

        // ── 6×4 히트맵 그리드 (실제와 동일한 구조) ──────────────────────
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
            final color = _heatColor(_hourly[h], maxCount, cs);
            return Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
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

  static Widget _heatBox(Color color) => Container(
    width: 10,
    height: 10,
    margin: const EdgeInsets.only(left: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// 기분 분포 범례 한 행 (색상 도트 + 레이블 + 횟수).
class _MoodLegendRow extends StatelessWidget {
  final String label;
  final Color color;
  final String count;

  const _MoodLegendRow(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label  $count',
          style: TextStyle(fontSize: 11, color: context.cs.onSurface),
        ),
      ],
    );
  }
}
