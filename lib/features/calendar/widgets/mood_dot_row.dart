// 캘린더 각 날짜 셀 하단에 표시되는 색상 도트 행 위젯.
// 기분 표시 방식 설정과 무관하게 항상 색상 도트로 표시한다.
// 최대 5개를 표시하고 초과분은 "+N" 텍스트로 대체한다.

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/extensions/entry_ext.dart';

/// 캘린더 날짜 셀 하단 기분 도트 행. 최대 5개 표시, 초과분은 "+N" 텍스트로 대체한다.
class MoodDotRow extends StatelessWidget {
  final List<Entry> entries;

  const MoodDotRow({super.key, required this.entries});

  static const int _maxDots = 5;
  static const double _dotSize = 6.0;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final overflow = entries.length - _maxDots;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...entries.take(_maxDots).map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: SizedBox.square(
              dimension: _dotSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: e.moodColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        if (overflow > 0) ...[
          const SizedBox(width: 1),
          Text(
            '+$overflow',
            style: TextStyle(
              fontSize: 7,
              color: Theme.of(context).colorScheme.outline,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}
