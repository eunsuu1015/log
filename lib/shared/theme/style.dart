// 앱 전역 공통 스타일 상수·헬퍼 모음.
// BorderRadius(AppRadius), 버튼 스타일(AppButtonStyle), 카드 데코레이션(AppCard),
// 구분선 위젯(AppDivider)을 정의한다. 컴포넌트 간 스타일 일관성을 위해 사용한다.

import 'package:flutter/material.dart';
import 'app_theme.dart';

// ---------------------------------------------------------------------------
// 모양 상수
// ---------------------------------------------------------------------------

/// 앱 전역 BorderRadius 상수 (pill → rounded → gentle 순).
abstract final class AppRadius {
  static const double sm  = 10;
  static const double md  = 14;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double pill = 100;

  static const BorderRadius smAll   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(24));
}

// ---------------------------------------------------------------------------
// 버튼 스타일
// ---------------------------------------------------------------------------

/// ThemeData에 등록된 기본 스타일 외에 특수 용도 버튼이 필요한 경우 사용.
abstract final class AppButtonStyle {
  /// 위험 동작(삭제 등)에 사용하는 빨간 FilledButton.
  static ButtonStyle destructive(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: context.cs.error,
        foregroundColor: context.cs.onError,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      );

  /// Tonal (primaryContainer 배경) FilledButton.
  static ButtonStyle tonal(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: context.cs.primaryContainer,
        foregroundColor: context.cs.onPrimaryContainer,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      );

  /// 작은 인라인 액션 버튼 (태그, 뱃지 등).
  static ButtonStyle small(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: context.cs.surfaceContainerHighest,
        foregroundColor: context.cs.onSurfaceVariant,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

// ---------------------------------------------------------------------------
// 카드 데코레이션
// ---------------------------------------------------------------------------

/// Card 위젯 대신 Container를 직접 꾸밀 때 사용.
abstract final class AppCard {
  /// border 기반 기본 카드 박스 데코레이션.
  static BoxDecoration decoration(BuildContext context) => BoxDecoration(
        color: context.isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: context.isDark
              ? AppColors.darkOutline
              : AppColors.lightOutline,
        ),
      );

  /// 배경색만 살짝 올린 강조 카드 (통계 섹션 등).
  static BoxDecoration elevatedDecoration(BuildContext context) =>
      BoxDecoration(
        color: context.isDark
            ? AppColors.darkSurfaceContainerHigh
            : AppColors.lightSurfaceContainerHigh,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: context.isDark
              ? AppColors.darkOutline
              : AppColors.lightOutlineVariant,
        ),
      );
}

// ---------------------------------------------------------------------------
// 구분선
// ---------------------------------------------------------------------------

/// 컨텍스트 없이 사용 가능한 얇은 구분선 위젯.
class AppDivider extends StatelessWidget {
  final double indent;
  const AppDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: indent,
        color: context.isDark
            ? AppColors.darkOutline
            : AppColors.lightOutline,
      );
}
