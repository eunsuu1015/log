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
/// [onSlideChanged]가 제공되면 슬라이드 열림/닫힘 시 컨트롤러를 전달한다(null = 닫힘).
class EntryCard extends StatefulWidget {
  final Entry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final ValueChanged<SlidableController?>? onSlideChanged;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDelete,
    this.onSlideChanged,
  });

  @override
  State<EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<EntryCard> {
  SlidableController? _controller;

  /// 메모를 최대 2줄로 잘라 반환한다.
  /// 카드 높이를 일정하게 유지하기 위해 2줄 초과 시 "..." 접미어를 붙인다.
  static String _truncateMemo(String memo) {
    final lines = memo.split('\n');
    if (lines.length > 2) return '${lines.take(2).join('\n')} ...';
    return memo;
  }

  /// 슬라이드 애니메이션 상태 변화를 감지해 [onSlideChanged]를 호출한다.
  void _onAnimStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.dismissed) {
      widget.onSlideChanged?.call(null);
    } else {
      widget.onSlideChanged?.call(_controller);
    }
  }

  @override
  void dispose() {
    _controller?.animation.removeStatusListener(_onAnimStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNotVisited = widget.entry.visited == false;
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.7);

    final cardContent = InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MoodIndicator.fromEntry(entry: widget.entry, size: 20),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 40),
              child: Text(
                widget.entry.moodLabel,
                style: context.tt.titleSmall?.copyWith(
                  color: isNotVisited
                      ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                      : widget.entry.moodColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: widget.entry.memo?.isNotEmpty == true
                  ? Text(
                      _truncateMemo(widget.entry.memo!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.bodySmall?.copyWith(color: dimColor),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            Text(
              widget.entry.timeStr,
              style: context.tt.titleSmall?.copyWith(
                color: isNotVisited ? dimColor : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onDelete == null) return cardContent;

    return Slidable(
      key: ValueKey('entry_${widget.entry.id}'),
      // 같은 groupTag 내에서 하나만 열리도록 제어 (SlidableAutoCloseBehavior와 함께 동작)
      groupTag: 'entry_list',
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (_) => widget.onDelete!(),
            backgroundColor: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 6, 8, 6),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '삭제',
                style: TextStyle(
                  color: cs.onError,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      // Builder로 Slidable 스코프 내에서 컨트롤러를 얻어 애니메이션 리스너를 한 번만 등록한다.
      child: Builder(
        builder: (innerContext) {
          final ctrl = Slidable.of(innerContext);
          if (ctrl != null && ctrl != _controller) {
            _controller?.animation.removeStatusListener(_onAnimStatus);
            _controller = ctrl;
            ctrl.animation.addStatusListener(_onAnimStatus);
          }
          return cardContent;
        },
      ),
    );
  }
}
