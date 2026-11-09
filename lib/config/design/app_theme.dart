import 'package:flutter/material.dart';

/// 一套完整的配色。亮色 / 暗色各一份，界面只通过 [AppColors] 取色。
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.bgDeep,
    required this.panel,
    required this.panelSoft,
    required this.panelHi,
    required this.panelHover,
    required this.border,
    required this.borderSoft,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentDark,
    required this.accentChip,
    required this.accentChipText,
    required this.accentFg,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.info,
    required this.cyan,
    required this.purple,
    required this.assetGold,
    required this.assetJade,
    required this.assetAp,
    required this.assetBlue,
    required this.assetPurple,
    required this.assetRed,
    required this.assetTeal,
    required this.shadow,
  });

  final Brightness brightness;

  // 背景层级（由深到浅或由浅到深，按语义命名）
  final Color bg;
  final Color bgDeep;
  final Color panel;
  final Color panelSoft;
  final Color panelHi;
  final Color panelHover;

  // 描边
  final Color border;
  final Color borderSoft;
  final Color borderStrong;

  // 文本
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // 强调色
  final Color accent;
  final Color accentDark;

  /// 浅色高亮块（如「今天」日期格）
  final Color accentChip;
  final Color accentChipText;

  /// 强调色底上的前景色
  final Color accentFg;

  // 语义色
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color info;
  final Color cyan;
  final Color purple;

  // 资产图标色
  final Color assetGold;
  final Color assetJade;
  final Color assetAp;
  final Color assetBlue;
  final Color assetPurple;
  final Color assetRed;
  final Color assetTeal;

  /// 面板阴影
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  /// 暗色：原来的玻璃质感
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0A0B0D),
    bgDeep: Color(0xFF07080A),
    panel: Color(0xFF121317),
    panelSoft: Color(0xFF17191E),
    panelHi: Color(0xFF1E2027),
    panelHover: Color(0xFF23262E),
    border: Color(0xFF262932),
    borderSoft: Color(0xFF1C1E25),
    borderStrong: Color(0xFF343844),
    textPrimary: Color(0xFFE9EAEE),
    textSecondary: Color(0xFF9BA1AA),
    textMuted: Color(0xFF6A7078),
    accent: Color(0xFF5CE39B),
    accentDark: Color(0xFF0F2A1D),
    accentChip: Color(0xFFCFF6C9),
    accentChipText: Color(0xFF14351C),
    accentFg: Color(0xFF06231A),
    danger: Color(0xFFF2555A),
    dangerSoft: Color(0xFF3A1A1D),
    warning: Color(0xFFE8B65A),
    info: Color(0xFF6FA8D8),
    cyan: Color(0xFF5FD0DC),
    purple: Color(0xFFB58CF0),
    assetGold: Color(0xFFE0A94B),
    assetJade: Color(0xFFE0655A),
    assetAp: Color(0xFFDD8A45),
    assetBlue: Color(0xFF6FA8D8),
    assetPurple: Color(0xFFA97BE8),
    assetRed: Color(0xFFD9605E),
    assetTeal: Color(0xFF57BFA6),
    shadow: Color(0x66000000),
  );

  /// 亮色：白底 + 同色系绿强调
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF4F6F8),
    bgDeep: Color(0xFFEAEDF1),
    panel: Color(0xFFFFFFFF),
    panelSoft: Color(0xFFF6F8FA),
    panelHi: Color(0xFFEDF0F4),
    panelHover: Color(0xFFE4E9EF),
    border: Color(0xFFDCE1E7),
    borderSoft: Color(0xFFE8ECF1),
    borderStrong: Color(0xFFC6CDD6),
    textPrimary: Color(0xFF1B1F24),
    textSecondary: Color(0xFF5A626C),
    textMuted: Color(0xFF8A929C),
    accent: Color(0xFF12A05C),
    accentDark: Color(0xFFDFF5E7),
    accentChip: Color(0xFFD6F5E2),
    accentChipText: Color(0xFF0B4B2B),
    accentFg: Color(0xFFFFFFFF),
    danger: Color(0xFFD92D35),
    dangerSoft: Color(0xFFFDE7E8),
    warning: Color(0xFFB87708),
    info: Color(0xFF2C7BC0),
    cyan: Color(0xFF1189A0),
    purple: Color(0xFF6C3FBF),
    assetGold: Color(0xFFB5791A),
    assetJade: Color(0xFFCF4B3F),
    assetAp: Color(0xFFC06A1E),
    assetBlue: Color(0xFF2C7BC0),
    assetPurple: Color(0xFF7B4FC4),
    assetRed: Color(0xFFC0392F),
    assetTeal: Color(0xFF1E8E78),
    shadow: Color(0x1A101828),
  );
}

/// 当前生效的调色板。
///
/// 由 [ThemeService] 在切换主题时写入；[AppColors] 转发到它。
/// 用普通全局变量而不是直接读 `Get.isDarkMode`，是为了让纯 Dart 单测
/// 也能直接切主题，不依赖 GetX 的 binding。
AppPalette currentPalette = AppPalette.light;

/// 按亮/暗设置当前调色板，返回是否发生变化
bool applyPalette({required bool dark}) {
  final next = dark ? AppPalette.dark : AppPalette.light;
  final changed = !identical(currentPalette, next);
  currentPalette = next;
  return changed;
}

/// 当前主题对应的颜色。
///
/// 这类静态 getter 会跟随 [currentPalette]，因此所有 widget 里
/// 直接用 `AppColors.xxx` 即可自动适配亮/暗，无需改调用点。
abstract final class AppColors {
  static AppPalette get _p => currentPalette;

  static Color get bg => _p.bg;
  static Color get bgDeep => _p.bgDeep;
  static Color get panel => _p.panel;
  static Color get panelSoft => _p.panelSoft;
  static Color get panelHi => _p.panelHi;
  static Color get panelHover => _p.panelHover;

  static Color get border => _p.border;
  static Color get borderSoft => _p.borderSoft;
  static Color get borderStrong => _p.borderStrong;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

  static Color get accent => _p.accent;
  static Color get accentDark => _p.accentDark;
  static Color get accentChip => _p.accentChip;
  static Color get accentChipText => _p.accentChipText;
  static Color get accentFg => _p.accentFg;

  static Color get danger => _p.danger;
  static Color get dangerSoft => _p.dangerSoft;
  static Color get warning => _p.warning;
  static Color get info => _p.info;
  static Color get cyan => _p.cyan;
  static Color get purple => _p.purple;

  static Color get assetGold => _p.assetGold;
  static Color get assetJade => _p.assetJade;
  static Color get assetAp => _p.assetAp;
  static Color get assetBlue => _p.assetBlue;
  static Color get assetPurple => _p.assetPurple;
  static Color get assetRed => _p.assetRed;
  static Color get assetTeal => _p.assetTeal;

  static Color get shadow => _p.shadow;

  /// 按 context 的主题取调色板（构建 ThemeData 等无 currentPalette 场景）
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;
}

abstract final class AppRadius {
  static const double panel = 16;
  static const double card = 12;
  static const double chip = 10;
  static const double button = 10;

  static const BorderRadius panelR = BorderRadius.all(Radius.circular(panel));
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius chipR = BorderRadius.all(Radius.circular(chip));
}

abstract final class AppMetrics {
  static const double titleBarHeight = 52;
  static const double gap = 12;
  static const double gapSmall = 8;
  static const double pagePadding = 12;
  static const double panelPadding = 14;
}

abstract final class AppDecorations {
  static BoxDecoration panel({
    Color? color,
    Color? borderColor,
    double radius = AppRadius.panel,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.borderSoft),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration softCard({Color? color, double radius = AppRadius.card}) {
    return BoxDecoration(
      color: color ?? AppColors.panelSoft,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderSoft),
    );
  }

  static BoxDecoration get hairline => BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      );
}

/// 文本样式快捷入口
abstract final class AppText {
  static TextStyle get pageTitle => TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontSize: 13.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  static TextStyle get label => TextStyle(
        fontSize: 11.5,
        height: 1.3,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 10.5,
        height: 1.25,
        color: AppColors.textMuted,
      );

  static TextStyle get mono => TextStyle(
        fontSize: 11.5,
        height: 1.45,
        color: AppColors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get number => TextStyle(
        fontSize: 15,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
