import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/asset_model.dart';

/// AppColors 现在是转发到 AppPalette 的 getter，依赖 Get.isDarkMode，
/// 所以测试里必须先初始化 GetX 并显式指定亮/暗。
void _useTheme({required bool dark}) {
  applyPalette(dark: dark);
}

void main() {
  group('调色板', () {
    test('亮/暗两套都完整定义', () {
      for (final p in [AppPalette.dark, AppPalette.light]) {
        expect(p.bg, isNotNull);
        expect(p.panel, isNotNull);
        expect(p.textPrimary, isNotNull);
        expect(p.accent, isNotNull);
        expect(p.shadow, isNotNull);
      }
      expect(AppPalette.dark.brightness, Brightness.dark);
      expect(AppPalette.light.brightness, Brightness.light);
    });

    test('暗色背景层级逐层变亮', () {
      final p = AppPalette.dark;
      double lum(Color c) =>
          ((c.r * 255) + (c.g * 255) + (c.b * 255)) / 3;
      expect(lum(p.bg), lessThan(lum(p.panel)));
      expect(lum(p.panel), lessThan(lum(p.panelHi)));
      expect(lum(p.bg), lessThan(40), reason: '暗色 bg 必须是深色');
    });

    test('亮色背景确实是亮的，且层级递减', () {
      final p = AppPalette.light;
      double lum(Color c) =>
          ((c.r * 255) + (c.g * 255) + (c.b * 255)) / 3;
      expect(lum(p.bg), greaterThan(200), reason: '亮色 bg 必须是浅色');
      expect(lum(p.panel), greaterThanOrEqualTo(lum(p.bg)),
          reason: '亮色下白面板比灰底更亮');
      expect(lum(p.panelHi), lessThan(lum(p.panel)),
          reason: 'panelHi 是更深一档的填充');
    });

    test('亮色文字是深色，暗色文字是浅色', () {
      double lum(Color c) =>
          ((c.r * 255) + (c.g * 255) + (c.b * 255)) / 3;
      expect(lum(AppPalette.light.textPrimary), lessThan(80));
      expect(lum(AppPalette.dark.textPrimary), greaterThan(200));
    });

    test('强调色前景与背景有足够对比', () {
      for (final p in [AppPalette.dark, AppPalette.light]) {
        double lum(Color c) =>
            ((c.r * 255) + (c.g * 255) + (c.b * 255)) / 3;
        final diff = (lum(p.accent) - lum(p.accentFg)).abs();
        expect(diff, greaterThan(60),
            reason: 'accent 上的文字必须能看清');
      }
    });

    test('圆角与间距为正数', () {
      expect(AppRadius.panel, greaterThan(0));
      expect(AppRadius.card, greaterThan(0));
      expect(AppMetrics.gap, greaterThan(0));
      expect(AppMetrics.pagePadding, greaterThan(0));
    });
  });

  group('AppColors 跟随主题', () {
    test('暗色模式下取暗色调色板', () {
      _useTheme(dark: true);
      expect(AppColors.textPrimary, AppPalette.dark.textPrimary);
      expect(AppColors.accent, AppPalette.dark.accent);
    });

    test('亮色模式下取亮色调色板', () {
      _useTheme(dark: false);
      expect(AppColors.textPrimary, AppPalette.light.textPrimary);
      expect(AppColors.accent, AppPalette.light.accent);
    });

    test('两套调色板取值不同（确认真的切换了）', () {
      _useTheme(dark: true);
      final darkBg = AppColors.bg;
      _useTheme(dark: false);
      final lightBg = AppColors.bg;
      expect(darkBg, isNot(equals(lightBg)));
    });
  });

  group('文本样式', () {
    test('都有明确字号与颜色', () {
      _useTheme(dark: false);
      for (final style in [
        AppText.pageTitle,
        AppText.sectionTitle,
        AppText.body,
        AppText.label,
        AppText.caption,
        AppText.mono,
        AppText.number,
      ]) {
        expect(style.fontSize, isNotNull);
        expect(style.fontSize! > 0, isTrue);
        expect(style.color, isNotNull);
      }
    });

    test('层级字号递减：标题 > 正文 > 说明', () {
      _useTheme(dark: false);
      expect(AppText.pageTitle.fontSize!,
          greaterThan(AppText.body.fontSize!));
      expect(AppText.sectionTitle.fontSize!,
          greaterThan(AppText.label.fontSize!));
      expect(AppText.label.fontSize!, greaterThan(AppText.caption.fontSize!));
    });
  });

  group('资产面板占位数据', () {
    test('数量与唯一性', () {
      _useTheme(dark: false);
      final items = AssetItemModel.placeholders;
      expect(items.length, 18, reason: '与目标图一致：18 项');
      final names = items.map((e) => e.nameKey).toList();
      expect(names.toSet().length, names.length, reason: '名称不应重复');
    });

    test('每项都有值、名称与颜色', () {
      _useTheme(dark: false);
      for (final item in AssetItemModel.placeholders) {
        expect(item.value, isNotEmpty);
        expect(item.nameKey, isNotEmpty);
        expect(item.color, isNotNull);
      }
    });

    test('颜色随主题变化（因为用了 AppColors getter）', () {
      _useTheme(dark: true);
      final darkColor = AssetItemModel.placeholders.first.color;
      _useTheme(dark: false);
      final lightColor = AssetItemModel.placeholders.first.color;
      expect(darkColor, isNot(equals(lightColor)));
    });
  });

  group('i18n 键', () {
    test('新增的 UI 键都有常量定义', () {
      for (final key in [
        I18n.task_date_distribution,
        I18n.today,
        I18n.assets,
        I18n.run_now,
        I18n.wait_now,
        I18n.bury_one_year,
        I18n.adjust_run_time,
        I18n.buried,
        I18n.more_actions,
        I18n.reorder_tabs,
        I18n.hide_tasks,
        I18n.theme_light,
        I18n.theme_dark,
        I18n.show_assets,
      ]) {
        expect(key, isNotEmpty);
      }
    });
  });
}
