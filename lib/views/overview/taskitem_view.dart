import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/task_item_model.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/overview/overview_model.dart';

/// 单条任务行：左侧时间 + 名称，右侧操作按钮
class TaskItemView extends StatelessWidget {
  const TaskItemView({
    super.key,
    required this.model,
    required this.state,
    this.onRunNow,
    this.onPinTop,
    this.onPinBottom,
    this.onOpenSetting,
  });

  final TaskItemModel model;
  final TaskRowState state;
  final VoidCallback? onRunNow;
  final VoidCallback? onPinTop;
  final VoidCallback? onPinBottom;
  final VoidCallback? onOpenSetting;

  @override
  Widget build(BuildContext context) {
    if (model.isAllEmpty()) return const SizedBox.shrink();
    return _TaskRowBody(
      model: model,
      state: state,
      onRunNow: onRunNow,
      onPinTop: onPinTop,
      onPinBottom: onPinBottom,
      onOpenSetting: onOpenSetting,
    );
  }
}

class _TaskRowBody extends StatefulWidget {
  const _TaskRowBody({
    required this.model,
    required this.state,
    this.onRunNow,
    this.onPinTop,
    this.onPinBottom,
    this.onOpenSetting,
  });

  final TaskItemModel model;
  final TaskRowState state;
  final VoidCallback? onRunNow;
  final VoidCallback? onPinTop;
  final VoidCallback? onPinBottom;
  final VoidCallback? onOpenSetting;

  @override
  State<_TaskRowBody> createState() => _TaskRowBodyState();
}

class _TaskRowBodyState extends State<_TaskRowBody> {
  bool _hover = false;

  bool get _isOverdue {
    final dt = widget.model.nextRunDateTime;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.state == TaskRowState.running;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpenSetting,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: running
                ? AppColors.accentDark.withValues(alpha: 0.45)
                : (_hover ? AppColors.panelHover : AppColors.panelSoft),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: running
                  ? AppColors.accent.withValues(alpha: 0.38)
                  : (_hover ? AppColors.borderStrong : AppColors.borderSoft),
            ),
          ),
          child: Row(
            children: [
              _TimeBadge(
                time: widget.model.timeLabel,
                date: widget.model.dateLabel,
                running: running,
                overdue: !running && _isOverdue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.model.taskName.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight:
                            running ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (running) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'RUNNING',
                        style: TextStyle(
                          fontSize: 8.5,
                          height: 1.1,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _RowActions(
                highlighted: _hover || running,
                onRunNow: widget.onRunNow,
                onPinTop: widget.onPinTop,
                onPinBottom: widget.onPinBottom,
                onOpenSetting: widget.onOpenSetting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({
    required this.time,
    required this.running,
    this.date,
    this.overdue = false,
  });

  final String time;
  final String? date;
  final bool running;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color borderColor;
    if (running) {
      fg = const Color(0xFF06231A);
      bg = AppColors.accent;
      borderColor = AppColors.accent;
    } else if (overdue) {
      fg = AppColors.danger;
      bg = AppColors.dangerSoft;
      borderColor = AppColors.danger.withValues(alpha: 0.4);
    } else {
      fg = AppColors.textSecondary;
      bg = AppColors.panelHi;
      borderColor = AppColors.border;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 1),
            Text(
              date!,
              style: TextStyle(
                fontSize: 8.5,
                height: 1.1,
                color: fg.withValues(alpha: 0.75),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.highlighted,
    this.onRunNow,
    this.onPinTop,
    this.onPinBottom,
    this.onOpenSetting,
  });

  /// 鼠标悬停或任务正在运行时高亮；否则保持低透明度但仍然可点（对齐目标图常驻按钮）
  final bool highlighted;
  final VoidCallback? onRunNow;
  final VoidCallback? onPinTop;
  final VoidCallback? onPinBottom;
  final VoidCallback? onOpenSetting;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 130),
      opacity: highlighted ? 1 : 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: const Icon(Icons.bolt_rounded, size: 14),
            size: 23,
            tooltip: I18n.run_now.tr,
            onPressed: onRunNow,
          ),
          const SizedBox(width: 1),
          AppIconButton(
            icon: const Icon(Icons.vertical_align_top_rounded, size: 13),
            size: 23,
            tooltip: I18n.task_pin_top.tr,
            onPressed: onPinTop,
          ),
          const SizedBox(width: 1),
          AppIconButton(
            icon: const Icon(Icons.vertical_align_bottom_rounded, size: 13),
            size: 23,
            tooltip: I18n.task_pin_bottom.tr,
            onPressed: onPinBottom,
          ),
          const SizedBox(width: 1),
          AppIconButton(
            icon: const Icon(Icons.tune_rounded, size: 13),
            size: 23,
            tooltip: I18n.task_setting.tr,
            onPressed: onOpenSetting,
          ),
        ],
      ),
    );
  }
}
