import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:poopoolog/utils/logger.dart';

import 'features/shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: PooPooLogApp()));
}

class PooPooLogApp extends StatelessWidget {
  const PooPooLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // 이게 있어야 쿠퍼티노 위젯이 한글로 나옴
      ],
      supportedLocales: [
        Locale('ko', 'KR'), // 한국어 설정
        Locale('en', 'US'), // 영어
      ],
      title: 'PooPooLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
