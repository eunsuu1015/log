// 기분 표시 통합 위젯. moodDisplayProvider 설정에 따라 도트 또는 얼굴 아이콘을 렌더링한다.
// 캘린더 도트·타임라인 카드·기록 화면 등 기분을 표시해야 하는 모든 곳에서 사용한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/models/mood_display_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:poopoolog/shared/widgets/mood_face_painter.dart';

/// 기분 표시 통합 위젯.
/// [moodDisplayProvider] 값에 따라 색상 도트 또는 얼굴 아이콘을 렌더링.
///
/// 사용 예:
///   MoodIndicator.fromEntry(entry: e, size: 10)   // 캘린더 도트
///   MoodIndicator.fromEntry(entry: e, size: 20)   // 타임라인 카드
///   MoodIndicator(mood: MoodLevel.good, visited: true, size: 28)
class MoodIndicator extends ConsumerWidget {
  const MoodIndicator({
    super.key,
    required this.mood,
    required this.visited,
    required this.size,
  });

  factory MoodIndicator.fromEntry({
    Key? key,
    required Entry entry,
    required double size,
  }) => MoodIndicator(
    key: key,
    mood: entry.mood != null ? MoodLevel.values[entry.mood!] : null,
    visited: entry.visited,
    size: size,
  );

  final MoodLevel? mood;
  final bool? visited;
  final double size;

  Color get _dotColor {
    if (visited == false) return AppTheme.moodNotVisited;
    if (visited != true) return AppTheme.moodNone;
    return switch (mood) {
      MoodLevel.good => AppTheme.moodGood,
      MoodLevel.okay => AppTheme.moodOkay,
      MoodLevel.bad => AppTheme.moodBad,
      null => AppTheme.moodNone,
    };
  }

  static const _dotDiameter = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(moodDisplayProvider);

    return SizedBox(
      width: size,
      height: size,
      child: display == MoodDisplay.face
          ? CustomPaint(painter: MoodFacePainter(mood: mood, visited: visited))
          : Center(
              child: SizedBox.square(
                dimension: _dotDiameter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
    );
  }
}
