// 기록이 0건인 신규 유저에게 표시하는 빈 상태 위젯.
// 타임라인(안내 문구만)과 통계(안내 문구 + 기록하러 가기 버튼) 두 스타일을 지원한다.

import 'package:flutter/material.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

/// 완전 신규 유저 (DB 기록 = 0) 빈 상태 위젯.
///
/// [onActionPressed]가 null이면 타임라인 스타일(안내 문구만),
/// non-null이면 통계 스타일(안내 문구 + [기록하러 가기] 버튼).
class NewUserEmptyState extends StatelessWidget {
  const NewUserEmptyState({super.key, this.onActionPressed});

  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final isStats = onActionPressed != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStats ? Icons.bar_chart_outlined : Icons.edit_note_outlined,
              size: 48,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isStats ? '기록이 쌓이면 통계를 분석해 드릴게요!' : '아직 기록이 없어요',
              style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isStats ? '첫 기록을 작성하러 가볼까요?' : '하단 + 버튼으로 첫 기록을 남겨보세요',
              style: context.tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isStats) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('기록하러 가기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
