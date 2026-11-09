import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/asset_model.dart';

void main() {
  group('设计令牌', () {
    test('背景层级是暗色且逐层变亮', () {
      // 用亮度粗校验：bg 应比 panel 暗，panel 比 panelHi 暗
      double lum(int c) => ((c >> 16 & 0xff) + (c >> 8 & 0xff) + (c & 0xff)) / 3;

      expect(lum(AppColors.bg.value), lessThan(lum(AppColors.panel.value)));
      expect(
          lum(AppColors.panel.value), lessThan(lum(AppColors.panelHi.value)));
      expect(lum(AppColors.bg.value), lessThan(40), reason: 'bg 必须是深色');
    });

    test('圆角与间距为正数', () {
      expect(AppRadius.panel, greaterThan(0));
      expect(AppRadius.card, greaterThan(0));
      expect(AppMetrics.gap, greaterThan(0));
      expect(AppMetrics.pagePadding, greaterThan(0));
    });

    test('文本样式都有明确字号与颜色', () {
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

    test('文本层级字号递减：标题 > 正文 > 说明', () {
      expect(AppText.pageTitle.fontSize!,
          greaterThan(AppText.body.fontSize!));
      expect(AppText.sectionTitle.fontSize!,
          greaterThan(AppText.label.fontSize!));
      expect(AppText.label.fontSize!, greaterThan(AppText.caption.fontSize!));
    });
  });

  group('资产面板占位数据', () {
    test('数量与唯一性', () {
      final items = AssetItemModel.placeholders;
      expect(items.length, 18, reason: '与目标图一致：18 项');
      final names = items.map((e) => e.nameKey).toList();
      expect(names.toSet().length, names.length, reason: '名称不应重复');
    });

    test('每项都有图标与颜色', () {
      for (final item in AssetItemModel.placeholders) {
        expect(item.value, isNotEmpty);
        expect(item.nameKey, isNotEmpty);
        expect(item.color, isNotNull);
      }
    });
  });

  group('i18n 键', () {
    test('新增的 UI 键都有常量定义', () {
      for (final key in [
        I18n.task_date_distribution,
        I18n.next_7_days,
        I18n.today,
        I18n.items,
        I18n.tasks,
        I18n.others,
        I18n.runtime_log,
        I18n.error_log,
        I18n.task_stats,
        I18n.assets,
        I18n.daily,
        I18n.auto_read,
        I18n.no_task,
        I18n.search_task,
        I18n.run_now,
        I18n.back_to_overview,
        I18n.total,
        I18n.assets_placeholder_tip,
      ]) {
        expect(key, isNotEmpty);
      }
    });
  });
}
