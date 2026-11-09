import 'package:flutter/material.dart';

/// 全局设计令牌：暗色玻璃面板风格
/// 所有页面/组件都应从这里取色，不要再硬编码颜色。
abstract final class AppColors {
  // 背景层级
  static const Color bg = Color(0xFF0A0B0D);
  static const Color bgDeep = Color(0xFF07080A);
  static const Color panel = Color(0xFF121317);
  static const Color panelSoft = Color(0xFF17191E);
  static const Color panelHi = Color(0xFF1E2027);
  static const Color panelHover = Color(0xFF23262E);

  // 描边
  static const Color border = Color(0xFF262932);
  static const Color borderSoft = Color(0xFF1C1E25);
  static const Color borderStrong = Color(0xFF343844);

  // 文本
  static const Color textPrimary = Color(0xFFE9EAEE);
  static const Color textSecondary = Color(0xFF9BA1AA);
  static const Color textMuted = Color(0xFF6A7078);

  // 强调色
  static const Color accent = Color(0xFF5CE39B);
  static const Color accentDark = Color(0xFF0F2A1D);
  static const Color accentChip = Color(0xFFCFF6C9);
  static const Color accentChipText = Color(0xFF14351C);

  // 语义色
  static const Color danger = Color(0xFFF2555A);
  static const Color dangerSoft = Color(0xFF3A1A1D);
  static const Color warning = Color(0xFFE8B65A);
  static const Color info = Color(0xFF6FA8D8);
  static const Color cyan = Color(0xFF5FD0DC);
  static const Color purple = Color(0xFFB58CF0);

  // 资产图标色
  static const Color assetGold = Color(0xFFE0A94B);
  static const Color assetJade = Color(0xFFE0655A);
  static const Color assetAp = Color(0xFFDD8A45);
  static const Color assetBlue = Color(0xFF6FA8D8);
  static const Color assetPurple = Color(0xFFA97BE8);
  static const Color assetRed = Color(0xFFD9605E);
  static const Color assetTeal = Color(0xFF57BFA6);
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
          ? const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 6),
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

  static const BoxDecoration hairline = BoxDecoration(
    border: Border(bottom: BorderSide(color: AppColors.borderSoft, width: 1)),
  );
}

/// 文本样式快捷入口
abstract final class AppText {
  static TextStyle get pageTitle => const TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 13.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  static TextStyle get label => const TextStyle(
        fontSize: 11.5,
        height: 1.3,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 10.5,
        height: 1.25,
        color: AppColors.textMuted,
      );

  static TextStyle get mono => const TextStyle(
        fontSize: 11.5,
        height: 1.45,
        color: AppColors.textSecondary,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  static TextStyle get number => const TextStyle(
        fontSize: 15,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      );
}
