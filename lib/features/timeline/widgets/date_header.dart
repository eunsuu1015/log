// 타임라인 날짜 그룹 헤더 위젯. 날짜 레이블과 기록 건수 뱃지를 표시한다.
// 오늘 날짜이면 primary 색상 강조 + 왼쪽 수직 선으로 구분한다.

import 'package:flutter/material.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;
  final int count;

  const DateHeader({super.key, required this.date, required this.count});

  String get _label {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($wd)';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Row(
        children: [
          if (isToday)
            Container(
              width: 3, height: 14,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Text(
            _label,
            style: context.tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isToday ? cs.primary : cs.onSurface,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isToday ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count건',
              style: context.tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isToday ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}