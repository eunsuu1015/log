import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 색상 팔레트 원시 상수
// ---------------------------------------------------------------------------

/// 앱 전역 색상 팔레트. 직접 참조 대신 ColorScheme 또는 AppTheme 상수를 통해 사용.
abstract final class AppColors {
  // ── Light ─────────────────────────────────────────────────────────
  /// 버튼·FAB·링크 등 주요 인터랙션 요소 색상 → ColorScheme.primary
  static const lightPrimary = Color(0xFF2D6A4F);

  /// 다크 ColorScheme의 inversePrimary 전용 (라이트→다크 반전 시 primary 색상)
  static const lightPrimaryDark = Color(0xFF1E4D38);

  /// 보조 강조 색상 → ColorScheme.secondary
  static const lightSecondary = Color(0xFFA85C30);

  /// Scaffold(화면 전체) · AppBar 배경
  static const lightBackground = Color(0xFFFFFFFF);

  /// 카드 · 다이얼로그 · 바텀시트 · NavigationBar 배경 → ColorScheme.surface
  static const lightSurface = Color(0xFFFFFFFF);

  /// 텍스트 필드 테두리 · 드래그 핸들 → ColorScheme.outline
  static const lightOutline = Color(0xFFC8D5CC);

  /// 카드 테두리 · 구분선 (outline보다 연함) → ColorScheme.outlineVariant
  static const lightOutlineVariant = Color(0xFFD8E4DC);

  /// 제목·본문 기본 텍스트 · AppBar 타이틀·아이콘 → ColorScheme.onSurface
  static const lightTextPrimary = Color(0xFF191C1A);

  /// 서브타이틀 · 보조 설명 텍스트 → ColorScheme.onSurfaceVariant
  static const lightTextSecondary = Color(0xFF3D4F47);

  /// 텍스트 입력 필드 배경 → ColorScheme.surfaceContainer
  static const lightSurfaceContainer = Color(0xFFEDF4EF);

  /// 중간 강도 컨테이너 배경 → ColorScheme.surfaceContainerHigh
  static const lightSurfaceContainerHigh = Color(0xFFE7EFE9);

  /// FilterChip 등 칩 컴포넌트 기본 배경 → ColorScheme.surfaceContainerHighest
  static const lightSurfaceContainerHighest = Color(0xFFDFE9E1);

  // ── Dark ──────────────────────────────────────────────────────────
  /// 버튼·FAB·링크 주요 인터랙션 색상 (dark) · 라이트 ColorScheme.inversePrimary
  static const darkPrimary = Color(0xFF74C19A);

  /// 다크 ColorScheme의 inversePrimary 전용
  static const darkPrimaryDark = Color(0xFF52A87E);

  /// 보조 강조 색상 (dark) → ColorScheme.secondary
  static const darkSecondary = Color(0xFFE0966A);

  /// Scaffold · AppBar 배경 (dark)
  static const darkBackground = Color(0xFF0F1410);

  /// 다이얼로그 · 바텀시트 · NavigationBar 배경 (dark) → ColorScheme.surface
  static const darkSurface = Color(0xFF171D18);

  /// 엔트리 카드 배경 (dark) — darkSurface보다 약간 밝아 카드가 배경에서 구분됨
  static const darkCard = Color(0xFF1E271F);

  /// 카드 테두리 · 구분선 (dark) → ColorScheme.outline
  static const darkOutline = Color(0xFF3C5040);

  /// 드래그 핸들 · 더 연한 구분선 (dark) → ColorScheme.outlineVariant
  static const darkOutlineVariant = Color(0xFF283830);

  /// 기본 텍스트 · AppBar 타이틀·아이콘 (dark) → ColorScheme.onSurface
  static const darkTextPrimary = Color(0xFFDDE7DF);

  /// 보조 텍스트 · 서브타이틀 (dark) → ColorScheme.onSurfaceVariant
  static const darkTextSecondary = Color(0xFF9DB5A5);

  /// 텍스트 입력 필드 배경 (dark) → ColorScheme.surfaceContainer
  static const darkSurfaceContainer = Color(0xFF1E271F);

  /// 중간 강도 컨테이너 배경 (dark) → ColorScheme.surfaceContainerHigh
  static const darkSurfaceContainerHigh = Color(0xFF273028);

  /// FilterChip 등 칩 컴포넌트 기본 배경 (dark) → ColorScheme.surfaceContainerHighest
  static const darkSurfaceContainerHighest = Color(0xFF313C32);
}

// ---------------------------------------------------------------------------
// ColorScheme
// ---------------------------------------------------------------------------

const _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  // Primary — deep forest green
  primary: AppColors.lightPrimary,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFCCEBDA),
  onPrimaryContainer: Color(0xFF072316),
  // Secondary — warm terracotta
  secondary: AppColors.lightSecondary,
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFDDC8),
  onSecondaryContainer: Color(0xFF3A1400),
  // Tertiary — calm info blue
  tertiary: Color(0xFF4D6E9A),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFD4E3F5),
  onTertiaryContainer: Color(0xFF0E2642),
  // Error
  error: Color(0xFFCC3333),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFDE8E8),
  onErrorContainer: Color(0xFF5C0A0A),
  // Surface
  surface: AppColors.lightSurface,
  onSurface: AppColors.lightTextPrimary,
  onSurfaceVariant: AppColors.lightTextSecondary,
  surfaceTint: AppColors.lightPrimary,
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF3F8F4),
  surfaceContainer: AppColors.lightSurfaceContainer,
  surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
  surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
  // Outline
  outline: AppColors.lightOutline,
  outlineVariant: AppColors.lightOutlineVariant,
  // Inverse
  inverseSurface: Color(0xFF2A332C),
  onInverseSurface: Color(0xFFDDE7DF),
  inversePrimary: AppColors.darkPrimary,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

const _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  // Primary — light mint
  primary: AppColors.darkPrimary,
  onPrimary: Color(0xFF07301C),
  primaryContainer: Color(0xFF0D3D25),
  onPrimaryContainer: Color(0xFFA8DCBF),
  // Secondary — warm amber
  secondary: AppColors.darkSecondary,
  onSecondary: Color(0xFF3A2010),
  secondaryContainer: Color(0xFF5A3018),
  onSecondaryContainer: Color(0xFFF0C8A8),
  // Tertiary — muted blue
  tertiary: Color(0xFF84AADA),
  onTertiary: Color(0xFF0E2A46),
  tertiaryContainer: Color(0xFF183A58),
  onTertiaryContainer: Color(0xFFBDD5F0),
  // Error
  error: Color(0xFFE07070),
  onError: Color(0xFF5C1A1A),
  errorContainer: Color(0xFF7A2424),
  onErrorContainer: Color(0xFFF5C8C8),
  // Surface
  surface: AppColors.darkSurface,
  onSurface: AppColors.darkTextPrimary,
  onSurfaceVariant: AppColors.darkTextSecondary,
  surfaceTint: AppColors.darkPrimary,
  surfaceContainerLowest: Color(0xFF0A0F0B),
  surfaceContainerLow: Color(0xFF141A15),
  surfaceContainer: AppColors.darkSurfaceContainer,
  surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
  surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
  // Outline
  outline: AppColors.darkOutline,
  outlineVariant: AppColors.darkOutlineVariant,
  // Inverse
  inverseSurface: Color(0xFFF3F8F4),
  onInverseSurface: Color(0xFF2A332C),
  inversePrimary: AppColors.lightPrimaryDark,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

// ---------------------------------------------------------------------------
// AppTheme
// ---------------------------------------------------------------------------

/// 앱 전역 테마 팩토리 및 공유 의미론적 색상 상수 (인스턴스화 불가).
class AppTheme {
  AppTheme._();

  // ── 기분 컬러 (캘린더 dot · 통계 차트 · 카드 공용) ────────────────
  /// 좋음 — 맑은 숲 초록 (primary보다 채도 높게)
  static const Color moodGood = Color(0xFF3DA06C);

  /// 보통 — 따뜻한 앰버 (소화·안정 연상)
  static const Color moodOkay = Color(0xFFCC7D30);

  /// 나쁨 — 차분한 로즈 레드
  static const Color moodBad = Color(0xFFC64848);

  /// 기분 미입력 (다녀옴) — 그레이 그린 뉴트럴
  static const Color moodNone = Color(0xFF8CA896);

  /// 안 감 — 옅고 차가운 회색 (moodNone보다 밝고 채도 낮음)
  static const Color moodNotVisited = Color(0xFFC4CCCA);

  /// Material 3 라이트 테마.
  static ThemeData light() => _buildTheme(
    cs: _lightColorScheme,
    scaffoldBg: AppColors.lightBackground,
    appBarBg: AppColors.lightBackground,
    appBarTextColor: AppColors.lightTextPrimary,
    navBarBg: AppColors.lightSurface,
    cardColor: AppColors.lightSurface,
    cardBorderColor: AppColors.lightOutlineVariant,
    dialogBg: AppColors.lightSurface,
    sheetBg: AppColors.lightSurface,
    chipBg: AppColors.lightSurfaceContainerHighest,
    inputFillColor: AppColors.lightSurfaceContainer,
    dividerColor: AppColors.lightOutlineVariant,
    dragHandleColor: AppColors.lightOutline,
  );

  /// Material 3 다크 테마.
  static ThemeData dark() => _buildTheme(
    cs: _darkColorScheme,
    scaffoldBg: AppColors.darkBackground,
    appBarBg: AppColors.darkBackground,
    appBarTextColor: AppColors.darkTextPrimary,
    navBarBg: AppColors.darkSurface,
    cardColor: AppColors.darkCard,
    cardBorderColor: AppColors.darkOutline,
    dialogBg: AppColors.darkSurface,
    sheetBg: AppColors.darkSurface,
    chipBg: AppColors.darkSurfaceContainerHighest,
    inputFillColor: AppColors.darkSurfaceContainer,
    dividerColor: AppColors.darkOutline,
    dragHandleColor: AppColors.darkOutlineVariant,
  );
}

// ---------------------------------------------------------------------------
// 내부 팩토리
// ---------------------------------------------------------------------------

/// 라이트·다크 공통 ThemeData 빌더. 색상 인자만 다르고 구조는 동일하다.
ThemeData _buildTheme({
  required ColorScheme cs,
  required Color scaffoldBg,
  required Color appBarBg,
  required Color appBarTextColor,
  required Color navBarBg,
  required Color cardColor,
  required Color cardBorderColor,
  required Color dialogBg,
  required Color sheetBg,
  required Color chipBg,
  required Color inputFillColor,
  required Color dividerColor,
  required Color dragHandleColor,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: TextTheme(
      displayLarge: TextStyle(color: cs.onSurface),
      displayMedium: TextStyle(color: cs.onSurface),
      displaySmall: TextStyle(color: cs.onSurface),
      headlineLarge: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: cs.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: cs.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: cs.onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: cs.onSurface),
      bodySmall: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: cs.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
      ),
    ),
    scaffoldBackgroundColor: scaffoldBg,

    // ── AppBar ────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: appBarTextColor,
      ),
      iconTheme: IconThemeData(color: appBarTextColor),
    ),

    // ── NavigationBar ─────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: navBarBg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: cs.primary.withValues(alpha: 0.14),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: cs.primary);
        }
        return IconThemeData(color: cs.onSurfaceVariant.withValues(alpha: 0.6));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          );
        }
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        );
      }),
    ),

    // ── FAB ───────────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ── Card ──────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorderColor),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Dialog ────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: cs.onSurfaceVariant,
        height: 1.5,
      ),
    ),

    // ── BottomSheet ───────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: sheetBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      dragHandleColor: dragHandleColor,
      dragHandleSize: const Size(36, 4),
    ),

    // ── Chip ──────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: chipBg,
      selectedColor: cs.primary.withValues(alpha: 0.16),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: cs.onSurfaceVariant,
      ),
    ),

    // ── FilledButton ──────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // ── OutlinedButton ────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.outline),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),

    // ── TextButton ────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // ── Input ─────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(
        fontSize: 14,
        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    ),

    // ── ListTile ──────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minVerticalPadding: 14,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: cs.onSurface,
      ),
      subtitleTextStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
    ),

    // ── Divider ───────────────────────────────────────────────────
    dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 1),
  );
}

// ---------------------------------------------------------------------------
// BuildContext 확장
// ---------------------------------------------------------------------------

extension ThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
