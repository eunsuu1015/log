import 'dart:ui';

import 'package:flutter/material.dart';

/// 앱 전역 테마 및 공유 색상 상수 모음 (인스턴스화 불가)
class AppTheme {
  AppTheme._();

  // 기분 컬러 (캘린더 dot + 통계 차트 공용)
  static const Color moodGood = Color(0xFF639922);
  static const Color moodOkay = Color(0xFFBA7517);
  static const Color moodBad = Color(0xFFE24B4A);
  static const Color moodNone = Color(0xFFB4B2A9); // 기분 미입력

  static const Color primaryBlue = Color(0xFF185FA5);

  /// Material 3 라이트 테마를 반환한다. primaryBlue를 seed 색상으로 사용한다.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18.0, // 모든 앱바의 폰트 크기를 18로 고정
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: const Color(0xFFE6F1FB),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// Material 3 다크 테마를 반환한다.
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18.0, // 모든 앱바의 폰트 크기를 18로 고정
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
