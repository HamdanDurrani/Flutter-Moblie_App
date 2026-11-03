import 'package:flutter/material.dart';

/// Paramount Club Ops — luxury brand tokens (ported from RN theme.ts).
class AppColors {
  AppColors._();

  static const champagne = Color(0xFFC4A35A);
  static const lightGold = Color(0xFFD4B96A);
  static const deepBlack = Color(0xFF0C0C0C);
  static const ink = Color(0xFF161412);
  static const porcelain = Color(0xFFF7F3EC);
  static const pearl = Color(0xFFFCFAF6);
  static const success = Color(0xFF3E8F62);
  static const danger = Color(0xFFB54A4A);
  static const info = Color(0xFF5C7A96);

  static ThemeColors dark = const ThemeColors(
    champagne: champagne,
    lightGold: lightGold,
    success: success,
    danger: danger,
    info: info,
    background: Color(0xFF0C0C0C),
    backgroundElevated: Color(0xFF141210),
    surface: Color(0xFF1C1A17),
    surfaceMuted: Color(0xFF161412),
    border: Color(0x38C4A35A),
    borderStrong: Color(0x80C4A35A),
    text: Color(0xFFF7F3EC),
    textSecondary: Color(0xFFA39E94),
    textMuted: Color(0xFF6F6A62),
    textOnAccent: Color(0xFF0C0C0C),
    successSoft: Color(0x293E8F62),
    warningSoft: Color(0x29C4A35A),
    dangerSoft: Color(0x29B54A4A),
    mutedSoft: Color(0x1FA39E94),
    overlay: Color(0xB80C0C0C),
    accentSoft: Color(0x2EC4A35A),
    gradientTop: Color(0xFF1A1610),
    gradientBottom: Color(0xFF0C0C0C),
    tabBar: Color(0xFF141210),
    cardShadow: Color(0x59000000),
    isDark: true,
  );

  static ThemeColors light = const ThemeColors(
    champagne: champagne,
    lightGold: lightGold,
    success: success,
    danger: danger,
    info: info,
    background: porcelain,
    backgroundElevated: pearl,
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFE9DF),
    border: Color(0x14161412),
    borderStrong: Color(0x8CC4A35A),
    text: ink,
    textSecondary: Color(0xFF5A554C),
    textMuted: Color(0xFF8A847A),
    textOnAccent: Color(0xFF0C0C0C),
    successSoft: Color(0x1F3E8F62),
    warningSoft: Color(0x24C4A35A),
    dangerSoft: Color(0x1AB54A4A),
    mutedSoft: Color(0x0D161412),
    overlay: Color(0x66161412),
    accentSoft: Color(0x2EC4A35A),
    gradientTop: pearl,
    gradientBottom: porcelain,
    tabBar: pearl,
    cardShadow: Color(0x0F161412),
    isDark: false,
  );
}

class ThemeColors {
  const ThemeColors({
    required this.champagne,
    required this.lightGold,
    required this.success,
    required this.danger,
    required this.info,
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.successSoft,
    required this.warningSoft,
    required this.dangerSoft,
    required this.mutedSoft,
    required this.overlay,
    required this.accentSoft,
    required this.gradientTop,
    required this.gradientBottom,
    required this.tabBar,
    required this.cardShadow,
    required this.isDark,
  });

  final Color champagne;
  final Color lightGold;
  final Color success;
  final Color danger;
  final Color info;
  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;
  final Color successSoft;
  final Color warningSoft;
  final Color dangerSoft;
  final Color mutedSoft;
  final Color overlay;
  final Color accentSoft;
  final Color gradientTop;
  final Color gradientBottom;
  final Color tabBar;
  final Color cardShadow;
  final bool isDark;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}
