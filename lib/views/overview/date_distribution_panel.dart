import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/overview/overview_model.dart';

/// 日期分布面板：今天 + 未来 7 天
///
/// 窗口较窄时自动压缩单元格（缩小字号、用单字星期），避免文字被裁掉。
class DateDistributionPanel extends StatelessWidget {
  const DateDistributionPanel({
    super.key,
    required this.buckets,
    required this.totalCount,
    this.farthestLabel,
  });

  final List<DateBucket> buckets;
  final int totalCount;

  /// 窗口外最远任务的日期提示（没有则隐藏）
  final String? farthestLabel;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(I18n.task_date_distribution.tr, style: AppText.sectionTitle),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${I18n.next_7_days.tr}  ${I18n.total.tr} $totalCount ${I18n.items.tr}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
              if (farthestLabel != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '· $farthestLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 5.0;
              final count = buckets.length;
              final cellWidth =
                  (constraints.maxWidth - gap * (count - 1)) / count;
              // 单元格过窄时降到紧凑模式：单字星期 + 更小字号
              final compact = cellWidth < 40;
              return Row(
                children: [
                  for (int i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: _DateCell(
                        bucket: buckets[i],
                        compact: compact,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({required this.bucket, this.compact = false});

  final DateBucket bucket;
  final bool compact;

  /// 紧凑模式下「周二」→「二」，「今天」保留
  String get _label {
    final label = bucket.label;
    if (!compact) return label;
    if (bucket.isToday) return label;
    if (label.isEmpty) return label;
    // 去掉开头的「周」
    return label.length > 1 && label.startsWith('周')
        ? label.substring(1)
        : label;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = bucket.isToday;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: 7),
      decoration: BoxDecoration(
        color: isToday ? AppColors.accentChip : AppColors.panelSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isToday ? AppColors.accentChip : AppColors.borderSoft,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FittedBox 保证再窄也不会裁掉文字
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                height: 1.2,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday
                    ? AppColors.accentChipText
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${bucket.count}',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color:
                    isToday ? AppColors.accentChipText : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
