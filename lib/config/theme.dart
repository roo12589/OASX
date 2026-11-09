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

const Color _accent = AppColors.accent;

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

TextTheme _textTheme(Brightness brightness) => _baseTextTheme
    .apply(
      fontFamily: 'LatoLato',
      bodyColor: brightness == Brightness.dark
          ? AppColors.textPrimary
          : const Color(0xFF1D1F24),
      displayColor: brightness == Brightness.dark
          ? AppColors.textPrimary
          : const Color(0xFF1D1F24),
    )
    .useSystemChineseFont(brightness);

ThemeData darkTheme = _build(
  brightness: Brightness.dark,
  scheme: const ColorScheme.dark(
    primary: _accent,
    onPrimary: Color(0xFF06231A),
    primaryContainer: AppColors.accentDark,
    onPrimaryContainer: _accent,
    secondary: Color(0xFF8FA0B8),
    onSecondary: Color(0xFF0B0D10),
    secondaryContainer: AppColors.panelHi,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: Color(0xFFB58CF0),
    surface: AppColors.panel,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.panelHi,
    surfaceContainerHigh: AppColors.panelSoft,
    outline: AppColors.border,
    outlineVariant: AppColors.borderSoft,
    error: AppColors.danger,
    onError: Color(0xFF2A0B0C),
  ),
  scaffold: AppColors.bg,
  titleBar: AppColors.bg,
);

ThemeData lightTheme = _build(
  brightness: Brightness.light,
  scheme: ColorScheme.fromSeed(
    seedColor: ColorSeed.baseColor.color,
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF1E7B52),
    surface: Colors.white,
    outline: const Color(0xFFD8DAE0),
    outlineVariant: const Color(0xFFE9EAF0),
  ),
  scaffold: const Color(0xFFF4F5F8),
  titleBar: const Color(0xFFF4F5F8),
);

ThemeData _build({
  required Brightness brightness,
  required ColorScheme scheme,
  required Color scaffold,
  required Color titleBar,
}) {
  final isDark = brightness == Brightness.dark;
  final textTheme = _textTheme(brightness);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
    canvasColor: scaffold,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: isDark ? AppColors.borderSoft : const Color(0xFFE6E7EC),
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: titleBar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
          size: 17,
          color: isDark ? AppColors.textSecondary : const Color(0xFF4A4E57)),
      titleTextStyle: textTheme.titleMedium,
    ),
    iconTheme: IconThemeData(
      size: 17,
      color: isDark ? AppColors.textSecondary : const Color(0xFF4A4E57),
    ),
    cardTheme: CardThemeData(
      color: isDark ? AppColors.panel : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: BorderSide(
            color: isDark ? AppColors.borderSoft : const Color(0xFFE6E7EC)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: titleBar,
      indicatorColor: isDark ? AppColors.panelHi : const Color(0xFFE7ECF5),
      selectedIconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimary : scheme.primary),
      unselectedIconTheme: const IconThemeData(size: 18),
      labelType: NavigationRailLabelType.all,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDark ? AppColors.panelHi : const Color(0xFF2A2D34),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isDark ? AppColors.borderStrong : Colors.transparent),
      ),
      textStyle: const TextStyle(
          fontSize: 11, height: 1.3, color: AppColors.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: isDark ? AppColors.panelSoft : const Color(0xFFF2F3F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textMuted : const Color(0xFF9AA0AA)),
      labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textSecondary : const Color(0xFF5C6169)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFD8DAE0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFD8DAE0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: isDark ? _accent : scheme.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.textSecondary : scheme.primary,
        textStyle: const TextStyle(fontSize: 12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isDark ? _accent : scheme.primary,
        foregroundColor: const Color(0xFF06231A),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textSecondary : scheme.primary,
        side: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFD8DAE0)),
        textStyle: const TextStyle(fontSize: 11.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? AppColors.panelHi : const Color(0xFF2A2D34),
      contentTextStyle:
          const TextStyle(fontSize: 12, color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
            color: isDark ? AppColors.borderStrong : Colors.transparent),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? AppColors.panel : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFE6E7EC)),
      ),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? AppColors.textSecondary : const Color(0xFF4A4E57)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: isDark ? AppColors.panelHi : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFE6E7EC)),
      ),
      textStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? AppColors.textPrimary : const Color(0xFF1D1F24)),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.all(
          isDark ? const Color(0xFF3A3E48) : const Color(0xFFC6C9D1)),
      crossAxisMargin: 2,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: isDark ? AppColors.panelSoft : const Color(0xFFF7F8FB),
      collapsedBackgroundColor:
          isDark ? AppColors.panelSoft : const Color(0xFFF7F8FB),
      textColor: isDark ? AppColors.textPrimary : const Color(0xFF1D1F24),
      iconColor: isDark ? AppColors.textSecondary : const Color(0xFF5C6169),
      collapsedIconColor:
          isDark ? AppColors.textSecondary : const Color(0xFF5C6169),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  );
}
