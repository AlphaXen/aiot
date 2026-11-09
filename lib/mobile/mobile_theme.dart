import 'package:flutter/material.dart';

/// One UI 느낌의 모바일 테마 (밝은 회색 배경 + 크게 둥근 흰 카드 + 파란 포인트)
class MobileColors {
  static const accent = Color(0xFF3E91FF);
  static const lightBg = Color(0xFFF2F2F7);
  static const lightCard = Colors.white;
  static const darkBg = Color(0xFF000000);
  static const darkCard = Color(0xFF1C1C1E);
  static const offline = Color(0xFFE5484D);
}

ThemeData buildMobileTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: MobileColors.accent,
    brightness: b,
    primary: MobileColors.accent,
    surface: dark ? MobileColors.darkCard : MobileColors.lightCard,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? MobileColors.darkBg : MobileColors.lightBg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? MobileColors.darkBg : MobileColors.lightBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: dark ? Colors.white : Colors.black,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: dark ? Colors.white : Colors.black),
    ),
    cardTheme: CardThemeData(
      color: dark ? MobileColors.darkCard : MobileColors.lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 28,
      activeTrackColor: MobileColors.accent,
      inactiveTrackColor: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      thumbColor: Colors.white,
      overlayShape: SliderComponentShape.noOverlay,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 2),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? MobileColors.accent : null),
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? MobileColors.darkCard : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    ),
  );
}

extension MobileCtx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardColor => isDark ? MobileColors.darkCard : MobileColors.lightCard;
  Color get subtle => isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
  Color get inactiveFill => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F3);
}
