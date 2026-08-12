// 테마 강조 색상(브랜드 메인 컬러) Provider.
// SharedPreferences에 저장하고 앱 시작 시 main.dart에서 초기값을 주입한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeAccentKey = 'theme_accent';

/// 앱 전역 강조 색상(테마 메인 컬러). green이 기본값이며 기존 디자인과 동일하다.
enum ThemeAccent {
  red,
  orange,
  yellow,
  green,
  sky,
  blue,
  navy,
  purple,
  gray,
  black,
}

/// 테마 강조 색상 Provider. main.dart에서 초기값을 SharedPreferences로 주입한다.
final themeAccentProvider = StateProvider<ThemeAccent>((_) => ThemeAccent.green);

/// SharedPreferences에서 저장된 강조 색상을 읽어온다.
Future<ThemeAccent> loadThemeAccent() async {
  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt(_kThemeAccentKey);
  if (index == null || index >= ThemeAccent.values.length) {
    return ThemeAccent.green;
  }
  return ThemeAccent.values[index];
}

/// SharedPreferences에 강조 색상을 저장한다.
Future<void> saveThemeAccent(ThemeAccent accent) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kThemeAccentKey, accent.index);
}

extension ThemeAccentX on ThemeAccent {
  /// 설정 화면에 표시할 한글 라벨.
  String get label => switch (this) {
    ThemeAccent.red => '빨강',
    ThemeAccent.orange => '주황',
    ThemeAccent.yellow => '노랑',
    ThemeAccent.green => '초록',
    ThemeAccent.sky => '하늘',
    ThemeAccent.blue => '파랑',
    ThemeAccent.navy => '남색',
    ThemeAccent.purple => '보라',
    ThemeAccent.gray => '회색',
    ThemeAccent.black => '검정',
  };

  /// 라이트 모드 primary 색상 (설정 화면 스와치로도 사용).
  /// 기존 초록 테마의 톤(채도·명도)에 맞춰 나머지 색상을 골랐다.
  Color get lightPrimary => switch (this) {
    ThemeAccent.red => const Color(0xFFA33B34),
    ThemeAccent.orange => const Color(0xFFB4652A),
    ThemeAccent.yellow => const Color(0xFF9C7F1F),
    ThemeAccent.green => const Color(0xFF2D6A4F),
    ThemeAccent.sky => const Color(0xFF2D7A8C),
    ThemeAccent.blue => const Color(0xFF2A5C99),
    ThemeAccent.navy => const Color(0xFF2B3B66),
    ThemeAccent.purple => const Color(0xFF6A3C82),
    ThemeAccent.gray => const Color(0xFF707070),
    ThemeAccent.black => const Color(0xFF262626),
  };

  /// 설정 화면 스와치 표시 전용 색상. black은 대비 확보를 위해 조정된
  /// [lightPrimary](진회색) 대신 라벨 그대로의 순흑을 보여준다.
  Color get swatchColor => switch (this) {
    ThemeAccent.black => Colors.black,
    _ => lightPrimary,
  };

  /// 다크 모드 primary 색상.
  Color get darkPrimary => switch (this) {
    ThemeAccent.red => const Color(0xFFE0938C),
    ThemeAccent.orange => const Color(0xFFE3AD79),
    ThemeAccent.yellow => const Color(0xFFD9C36B),
    ThemeAccent.green => const Color(0xFF74C19A),
    ThemeAccent.sky => const Color(0xFF7FCCDB),
    ThemeAccent.blue => const Color(0xFF8AB6E8),
    ThemeAccent.navy => const Color(0xFF8393C4),
    ThemeAccent.purple => const Color(0xFFC79FDA),
    ThemeAccent.gray => const Color(0xFFE6E6E6),
    ThemeAccent.black => const Color(0xFF6B6B6B),
  };
}
