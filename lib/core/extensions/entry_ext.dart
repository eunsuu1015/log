// 앱 전역에서 반복되는 MoodLevel·Entry 변환 로직을 모아둔 확장 파일.
// 색상·레이블·시간 포맷이 필요한 모든 위젯은 이 파일 하나만 import한다.

import 'dart:ui';

import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

import '../database/app_database.dart';

/// MoodLevel enum 확장 — 기분별 색상·레이블 단일 정의.
/// 여러 화면에서 switch 분기를 각자 작성하던 중복을 제거한다.
extension MoodLevelX on MoodLevel {
  /// 기분에 대응하는 AppTheme 색상
  Color get color => switch (this) {
    MoodLevel.good => AppTheme.moodGood,
    MoodLevel.okay => AppTheme.moodOkay,
    MoodLevel.bad => AppTheme.moodBad,
  };

  /// 기분 한국어 레이블
  String get label => switch (this) {
    MoodLevel.good => '좋음',
    MoodLevel.okay => '보통',
    MoodLevel.bad => '나쁨',
  };

  /// 기분 이모지
  String get emoji => switch (this) {
    MoodLevel.good => '😊',
    MoodLevel.okay => '😐',
    MoodLevel.bad => '😞',
  };
}

/// Entry (Drift 생성 행) 확장 - UI 렌더링에 필요한 헬퍼 모음
/// visited·mood 조합 판단과 시간 포맷팅을 한 곳에서 관리한다.
extension EntryX on Entry {
  /// 방문 여부·기분을 고려한 표시 색상
  /// 미방문·기분 없음은 AppTheme.moodNone(회색) 반환
  Color get moodColor {
    if (visited != true || mood == null) return AppTheme.moodNone;
    return MoodLevel.values[mood!].color;
  }

  /// 방문 여부·기분을 고려한 표시 레이블
  String get moodLabel {
    if (visited == null) return '-';
    if (visited == false) return '안 감';
    if (mood == null) return '다녀옴';
    return MoodLevel.values[mood!].label;
  }

  /// visited·mood 조합에 대응하는 이모지
  String get moodEmoji {
    if (visited == null) return '-';
    if (visited == false) return '🚫';
    if (mood == null) return '💩';
    return MoodLevel.values[mood!].emoji;
  }

  /// recordedAt을 "오전/오후 H:mm" 형식 문자열로 반환
  String get timeStr {
    final hour = recordedAt.hour;
    final minute = recordedAt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $h:$minute';
  }
}
