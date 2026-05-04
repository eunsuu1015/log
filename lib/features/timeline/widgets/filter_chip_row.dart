// 타임라인 화면 상단의 기분 필터 칩 행 위젯.
// 전체·좋음·보통·나쁨·다녀옴·안 감 6개 필터를 제공한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:toilet_tracker/core/extensions/entry_ext.dart';
import 'package:toilet_tracker/core/models/record_model.dart';
import 'package:toilet_tracker/features/timeline/timeline_provider.dart';
import 'package:toilet_tracker/shared/theme/app_theme.dart';

/// timelineFilterProvider를 읽고 쓰는 필터 칩 행.
/// 기분 색상은 MoodLevelX.color 확장을 통해 일관되게 가져온다.
class FilterChipRow extends ConsumerWidget{
  const FilterChipRow({super.key});

  /// TimelineFilter -> 기분 색상. 전체 안 감은 null(테마 primary 사용)
  Color? _chipColor(TimelineFilter f) => switch (f) {
    TimelineFilter.good     => MoodLevel.good.color,
    TimelineFilter.okay     => MoodLevel.okay.color,
    TimelineFilter.bad      => MoodLevel.bad.color,
    TimelineFilter.visited  => AppTheme.moodNone,
    _                       => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(timelineFilterProvider);

    final filters = TimelineFilter.values;
    return Row(
      children: List.generate(filters.length, (i) {
        final f = filters[i];
        final isSelected = current == f;
        final dotColor = _chipColor(f);
        final activeColor = dotColor ?? context.cs.primary;
        final labelColor = isSelected ? activeColor : context.cs.onSurfaceVariant;

        return Expanded(child: Padding(padding: EdgeInsets.only(left: i == 0 ? 10 : 5,
        right: i == filters.length - 1 ? 10 : 5),
          child: InkWell(
            onTap: () =>
            ref.read(timelineFilterProvider.notifier).state = f,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? activeColor : context.cs.outlineVariant,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (dotColor != null) ... [
                    Container(
                      width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? dotColor
                              : dotColor.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                    ),
                    const SizedBox(width: 5,),
                  ],
                  Text(
                    f.label(),
                    style: TextStyle(
                      fontSize: 12,
                      color: labelColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        );
      }).toList(),
    );
  }

}

