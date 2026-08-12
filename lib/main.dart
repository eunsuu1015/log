// 앱 진입점. Firebase·AdMob·SharedPreferences를 초기화하고 ProviderScope로 초기값을 주입한다.
// 스플래시를 먼저 runApp으로 표시한 뒤, 초기화(최소 1초) 완료 후 실제 앱으로 교체한다.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poopoolog/core/ads/ad_service.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';
import 'package:poopoolog/core/models/mood_display_provider.dart';
import 'package:poopoolog/core/models/theme_accent_provider.dart';
import 'package:poopoolog/core/settings/display_settings.dart';
import 'package:poopoolog/features/onboarding/onboarding_screen.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/more/more_screen.dart';
import 'features/shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 스플래시 즉시 표시
  runApp(const _SplashApp());

  // 초기화와 최소 1초를 동시에 대기
  ThemeMode initialThemeMode = ThemeMode.system;
  ThemeAccent initialThemeAccent = ThemeAccent.green;
  MoodDisplay initialMoodDisplay = MoodDisplay.dot;
  bool initialSunday = true;
  bool initialAdsRemoved = false;
  bool initialOnboardingSeen = false;

  await Future.wait([
    () async {
      await Firebase.initializeApp();
      await MobileAds.instance.initialize();
      AdService().preload();

      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(kThemeModeKey);
      initialThemeMode =
          savedIndex != null ? ThemeMode.values[savedIndex] : ThemeMode.system;
      initialThemeAccent = await loadThemeAccent();
      initialMoodDisplay = await loadMoodDisplay();
      initialSunday = prefs.getBool(kStartWeekdaySundayKey) ?? true;
      initialAdsRemoved = prefs.getBool(kAdsRemovedKey) ?? false;
      initialOnboardingSeen = prefs.getBool(kOnboardingSeenKey) ?? false;
    }(),
    Future.delayed(const Duration(seconds: 1)),
  ]);

  // 실제 앱으로 교체
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((_) => initialThemeMode),
        themeAccentProvider.overrideWith((_) => initialThemeAccent),
        moodDisplayProvider.overrideWith((_) => initialMoodDisplay),
        startWeekdaySundayProvider.overrideWith((_) => initialSunday),
        adsRemovedProvider.overrideWith((_) => initialAdsRemoved),
      ],
      child: PooPooLogApp(showOnboarding: !initialOnboardingSeen),
    ),
  );
}

/// 초기화 중 전체 화면에 스플래시 이미지를 표시하는 앱.
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SizedBox.expand(
          child: Image.asset(
            'assets/splash/splash.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class PooPooLogApp extends ConsumerWidget {
  /// true이면 앱 진입 시 온보딩 화면을 먼저 표시한다.
  final bool showOnboarding;

  const PooPooLogApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeAccent = ref.watch(themeAccentProvider);

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      title: 'PooPooLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: themeAccent),
      darkTheme: AppTheme.dark(accent: themeAccent),
      themeMode: themeMode,
      home: showOnboarding ? const OnboardingScreen() : const AppShell(),
    );
  }
}
