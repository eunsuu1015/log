// 캘린더 각 날짜 셀 하단에 표시되는 기분 도트 행 위젯.
// 최대 5개 도트를 표시하고 초과분은 "+N" 텍스트로 대체한다.

import 'package:flutter/material.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';

import '../../../core/database/app_database.dart';

/// 하루 기록 목록을 받아 기분 색상 도트를 가로로 나열한다.
/// 5개 초과 시 마지막에 "+N" 텍스트를 표시한다.
class MoodDotRow extends StatelessWidget {
  final List<Entry> entries;

  const MoodDotRow({super.key, required this.entries});

  static const int _maxDots = 5;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final visible = entries.take(_maxDots).toList();
    final overflow = entries.length - _maxDots;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((e) => _Dot(entry: e)),
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

/// 단일 기분 도트, 색상은 EntryX.moodColor에서 가져온다.
class _Dot extends StatelessWidget {
  final Entry entry;

  const _Dot({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: entry.moodColor, shape: BoxShape.circle),
    );
  }
}
