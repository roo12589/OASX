import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/asset_model.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 右侧资产面板（占位数据，暂不接入资源检测）
class AssetPanel extends StatelessWidget {
  const AssetPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const items = AssetItemModel.placeholders;
    return AppPanel(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 9),
            child: Row(
              children: [
                Text(I18n.assets.tr, style: AppText.sectionTitle),
                const SizedBox(width: 8),
                AppChip(label: '11-09', textStyle: AppText.caption),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '11-08 23:55 → 11-09 00:27',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ),
                const Spacer(),
                const AppIconButton(
                  icon: Icon(Icons.show_chart_rounded, size: 14),
                  size: 24,
                  tooltip: 'Trend',
                ),
                const AppIconButton(
                  icon: Icon(Icons.refresh_rounded, size: 14),
                  size: 24,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const AppDivider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 56,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _AssetCell(item: items[index]),
            ),
          ),
          const AppDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '18 ${I18n.items.tr} · ${I18n.daily.tr} 23:55 ${I18n.auto_read.tr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: I18n.assets_placeholder_tip.tr,
                  child: const Icon(Icons.info_outline_rounded,
                      size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetCell extends StatefulWidget {
  const _AssetCell({required this.item});
  final AssetItemModel item;

  @override
  State<_AssetCell> createState() => _AssetCellState();
}

class _AssetCellState extends State<_AssetCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: _hover ? AppColors.panelHover : AppColors.panelSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.color.withValues(alpha: 0.25)),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nameKey.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(fontSize: 10.5),
                        ),
                      ),
                      if (item.delta != null)
                        Text(
                          item.delta!,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.1,
                            color: item.deltaPositive
                                ? AppColors.accent
                                : AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
