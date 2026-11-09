import 'package:flutter/material.dart';
import 'package:chinese_font_library/chinese_font_library.dart';

import 'package:oasx/config/design/app_theme.dart';

/// 主题种子色，用于设置页切换（保留原有 API）
enum ColorSeed {
  baseColor('M3 Baseline', Color(0xff6750a4)),
  indigo('Indigo', Colors.indigo),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink);

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}

const Map<String, Color> colorSeedMap = {
  'M3 Baseline': Color(0xff6750a4),
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'Deep Orange': Colors.deepOrange,
  'Pink': Colors.pink
};

const TextTheme _baseTextTheme = TextTheme(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  displaySmall: TextStyle(),
  headlineLarge: TextStyle(),
  headlineMedium: TextStyle(),
  headlineSmall: TextStyle(),
  titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  titleMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
  titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  bodyLarge: TextStyle(fontSize: 13),
  bodyMedium: TextStyle(fontSize: 12.5),
  bodySmall: TextStyle(fontSize: 11.5),
  labelLarge: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
  labelMedium: TextStyle(fontSize: 11.5),
  labelSmall: TextStyle(fontSize: 10.5),
);

TextTheme _textTheme(AppPalette p) {
  final base = _baseTextTheme.apply(
    fontFamily: 'LatoLato',
    bodyColor: p.textPrimary,
    displayColor: p.textPrimary,
  );
  return base.useSystemChineseFont(p.brightness);
}

ColorScheme _scheme(AppPalette p) {
  final isDark = p.isDark;
  return ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.accentFg,
    primaryContainer: p.accentDark,
    onPrimaryContainer: isDark ? p.accent : p.accentChipText,
    secondary: isDark ? const Color(0xFF8FA0B8) : const Color(0xFF4E6478),
    onSecondary: isDark ? const Color(0xFF0B0D10) : Colors.white,
    secondaryContainer: p.panelHi,
    onSecondaryContainer: p.textPrimary,
    tertiary: p.purple,
    onTertiary: isDark ? const Color(0xFF0B0D10) : Colors.white,
    error: p.danger,
    onError: isDark ? const Color(0xFF2A0B0C) : Colors.white,
    surface: p.panel,
    onSurface: p.textPrimary,
    surfaceContainerHighest: p.panelHi,
    surfaceContainerHigh: p.panelSoft,
    onSurfaceVariant: p.textSecondary,
    outline: p.border,
    outlineVariant: p.borderSoft,
    shadow: p.shadow,
    scrim: isDark ? Colors.black : const Color(0x66101828),
    inverseSurface: p.textPrimary,
    onInverseSurface: p.panel,
    inversePrimary: isDark ? p.accentDark : p.accent,
  );
}

ThemeData _build(AppPalette p) {
  final scheme = _scheme(p);
  final textTheme = _textTheme(p);
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: p.borderSoft,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(size: 17, color: p.textSecondary),
      titleTextStyle: textTheme.titleMedium,
    ),
    iconTheme: IconThemeData(size: 17, color: p.textSecondary),
    cardTheme: CardThemeData(
      color: p.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: BorderSide(color: p.borderSoft),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.bg,
      indicatorColor: p.panelHi,
      selectedIconTheme: IconThemeData(color: p.textPrimary),
      unselectedIconTheme: const IconThemeData(size: 18),
      labelType: NavigationRailLabelType.all,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: p.isDark ? p.panelHi : const Color(0xFF2A2D34),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: p.isDark ? p.borderStrong : Colors.transparent),
      ),
      textStyle: TextStyle(
        fontSize: 11,
        height: 1.3,
        color: p.isDark ? p.textPrimary : Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: p.panelSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: TextStyle(fontSize: 12, color: p.textMuted),
      labelStyle: TextStyle(fontSize: 12, color: p.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: p.accent),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.textSecondary,
        textStyle: const TextStyle(fontSize: 12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: p.accent,
        foregroundColor: p.accentFg,
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textSecondary,
        side: BorderSide(color: p.border),
        textStyle: const TextStyle(fontSize: 11.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.isDark ? p.panelHi : const Color(0xFF2A2D34),
      contentTextStyle: TextStyle(
        fontSize: 12,
        color: p.isDark ? p.textPrimary : Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
            color: p.isDark ? p.borderStrong : Colors.transparent),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: BorderSide(color: p.border),
      ),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: TextStyle(fontSize: 12.5, color: p.textSecondary),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.isDark ? p.panelHi : p.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: p.border),
      ),
      textStyle: TextStyle(fontSize: 12.5, color: p.textPrimary),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.all(
        p.isDark ? const Color(0xFF3A3E48) : const Color(0xFFC0C6CF),
      ),
      crossAxisMargin: 2,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: p.panelSoft,
      collapsedBackgroundColor: p.panelSoft,
      textColor: p.textPrimary,
      iconColor: p.textSecondary,
      collapsedIconColor: p.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  );
}

ThemeData get darkTheme => _build(AppPalette.dark);

ThemeData get lightTheme => _build(AppPalette.light);
