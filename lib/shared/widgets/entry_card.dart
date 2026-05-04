// 기록 단일 행 위젯. 캘린더·타임라인 두 화면에서 공통으로 사용한다.
// 기분 동그라미 + 기분 텍스트 (왼쪽), 시간 (오른쪽) 구성.
// 구분선은 각 부모 위젯(ListView.separated / ListView.builder)이 처리한다.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

import '../../core/database/app_database.dart';

/// 기록 단일 행. 캘린더·타임라인 공용 위젯.
class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;

  const EntryCard({super.key, required this.entry, required this.onTap});

  /// 메모가 3줄 이상이면 2줄까지만 보여주고 "..."을 붙인다.
  static String _truncateMemo(String memo) {
    final lines = memo.split('\n');
    if (lines.length > 2) {
      return '${lines.take(2).join('\n')} ...';
    }
    return memo;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = entry.moodColor;
    final isNeutral = color == AppTheme.moodNone;
    final labelColor = isNeutral ? cs.onSurface : color;

    // TODO: InkWell: 터치 이벤트를 감지하고 물결이 퍼지는 느낌으로 애니메이션 효과를 주는 위
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),

            ),
            const SizedBox(width: 8,),
            Container(
              constraints: BoxConstraints(minWidth: 40),
              child: Text(
                entry.moodLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor,
                ),
              ),
            ),
            const SizedBox(width: 8,),
            Expanded(child: entry.memo?.isNotEmpty == true
            ? Text(_truncateMemo(entry.memo!),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12, color: cs.outline
            ),)
            : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8,),
            Text(
              entry.timeStr,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            )
          ],
        ),
      ),
    );
  }
}
