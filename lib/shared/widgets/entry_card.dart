// 기록 단일 행 위젯. 캘린더·타임라인 두 화면에서 공통으로 사용한다.
// 기분 표시는 MoodIndicator에 위임하며, dot/face 전환을 자동으로 처리한다.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:poopoolog/shared/widgets/mood_indicator.dart';

import '../../core/database/app_database.dart';

/// 기록 단일 행. 캘린더·타임라인 공용 위젯.
/// [onDelete]가 제공되면 왼쪽 스와이프 시 오른쪽에 삭제 버튼이 나타난다.
class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDelete,
  });

  /// 메모를 최대 2줄로 잘라 반환한다.
  /// 카드 높이를 일정하게 유지하기 위해 2줄 초과 시 "..." 접미어를 붙인다.
  static String _truncateMemo(String memo) {
    final lines = memo.split('\n');
    if (lines.length > 2) return '${lines.take(2).join('\n')} ...';
    return memo;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNotVisited = entry.visited == false;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.7);

    final cardContent = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MoodIndicator.fromEntry(entry: entry, size: 20),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 40),
              child: Text(
                entry.moodLabel,
                style: context.tt.titleSmall?.copyWith(
                  color: isNotVisited
                      ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                      : entry.moodColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: entry.memo?.isNotEmpty == true
                  ? Text(
                      _truncateMemo(entry.memo!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.bodySmall?.copyWith(color: dimColor),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            Text(
              entry.timeStr,
              style: context.tt.titleSmall?.copyWith(
                color: isNotVisited ? dimColor : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    if (onDelete == null) return cardContent;

    return Slidable(
      key: ValueKey('entry_${entry.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete!(),
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            label: '삭제',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
        ],
      ),
      child: cardContent,
    );
  }
}
