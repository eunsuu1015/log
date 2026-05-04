import 'package:flutter/material.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;
  final int count;

  DateHeader({super.key, required this.date, required this.count});

  /// 날짜를 사람이 읽기 쉬운 문자열로 변환한다.
  String _format(bool isToday, bool isYesterday) {
    if (isToday) return '오늘';
    if (isYesterday) return '어제';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($wd)';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    // DateTime.now()를 한 번만 계산해 getter 중복 호출 방지
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;
    final isYesterday =
        !isToday && date == today.subtract(const Duration(days: 1));
    final isSpecial = isToday || isYesterday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Row(
        children: [
          if (isSpecial)
            Container(
              width: 3, height: 14,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isToday ? cs.primary : cs.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Text(
            _format(isToday, isYesterday),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isToday
                ? cs.primary
                  : isYesterday
                ? cs.secondary
                  : cs.onSurface,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 8,),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isSpecial
                ? (isToday ? cs.primaryContainer : cs.secondaryContainer)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count건',
            style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSpecial
            ? (isToday ? cs.onPrimaryContainer
            : cs.onSecondaryContainer)
            : cs.onSurfaceVariant,
          ),
    ),
          ),
        ],
      ),
    );
  }
}