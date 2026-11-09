import 'package:flutter/material.dart';

/// 관리자 대시보드용 토큰 (밝은 회색 캔버스 + 흰 패널 + 파란 포인트)
class AdminTokens {
  const AdminTokens._({
    required this.canvas,
    required this.panel,
    required this.border,
    required this.text,
    required this.textSub,
    required this.textMuted,
    required this.hover,
    required this.series1,
    required this.grid,
  });

  final Color canvas, panel, border, text, textSub, textMuted, hover, series1, grid;

  static const accent = Color(0xFF3E91FF);
  static const good = Color(0xFF1E8E4E);
  static const warning = Color(0xFFB7791F);
  static const critical = Color(0xFFD93A3A);

  static const light = AdminTokens._(
    canvas: Color(0xFFF4F5F7),
    panel: Colors.white,
    border: Color(0xFFE6E8EC),
    text: Color(0xFF1D1D1F),
    textSub: Color(0xFF52514E),
    textMuted: Color(0xFF8A8D93),
    hover: Color(0xFFF1F5FF),
    series1: Color(0xFF2A78D6),
    grid: Color(0xFFECEDEF),
  );

  static const dark = AdminTokens._(
    canvas: Color(0xFF0F1012),
    panel: Color(0xFF1A1B1E),
    border: Color(0xFF2A2C30),
    text: Color(0xFFF0EFEC),
    textSub: Color(0xFFC3C2B7),
    textMuted: Color(0xFF8E9096),
    hover: Color(0xFF22262E),
    series1: Color(0xFF3987E5),
    grid: Color(0xFF26282C),
  );

  static AdminTokens of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildAdminTheme(Brightness b) {
  final t = b == Brightness.dark ? AdminTokens.dark : AdminTokens.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: ColorScheme.fromSeed(seedColor: AdminTokens.accent, brightness: b, primary: AdminTokens.accent, surface: t.panel),
    scaffoldBackgroundColor: t.canvas,
    dividerColor: t.border,
    visualDensity: VisualDensity.standard,
    textTheme: Typography.material2021().black.apply(bodyColor: t.text, displayColor: t.text),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: t.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTokens.accent, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AdminTokens.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AdminTokens.accent : null),
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
    ),
    dialogTheme: DialogThemeData(backgroundColor: t.panel, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    popupMenuTheme: PopupMenuThemeData(color: t.panel, surfaceTintColor: Colors.transparent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: b == Brightness.dark ? const Color(0xFF2E3036) : const Color(0xFF1D1D1F), borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
  );
}
