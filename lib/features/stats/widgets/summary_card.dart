// 통계 화면 상단 요약 지표 카드 위젯.
// 이모지·수치·레이블·선택적 진행 바를 한 카드 안에 표시한다.

import 'package:flutter/material.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

/// 통계 화면 요약 지표 카드.
/// [emoji] 왼쪽 이모지, [value] 지표 숫자/텍스트, [label] 설명,
/// [progress] 0.0~1.0이면 하단 LinearProgressIndicator 표시
class SummaryCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final double? progress;

  const SummaryCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                value,
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
          Text(label, style: context.tt.bodySmall),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ],
        ],
      ),
    );
  }
}
