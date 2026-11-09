import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/task_item_model.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/overview/overview_model.dart';
import 'package:oasx/views/overview/task_schedule_actions.dart';
import 'package:oasx/views/overview/task_time_quick_editor.dart';

/// 单条任务行：左侧时间 + 名称，右侧操作按钮
///
/// 交互：
/// - 点击行 → 打开任务详情
/// - 点击时间徽章 → 快捷调整运行时间
/// - 行内按钮：立即运行 / 立即等待
/// - 右键 → 置底（一年后）
class TaskItemView extends StatelessWidget {
  const TaskItemView({
    super.key,
    required this.model,
    required this.state,
    this.onRunNow,
    this.onWaitNow,
    this.onBury,
    this.onSetNextRun,
    this.onOpenSetting,
  });

  final TaskItemModel model;
  final TaskRowState state;
  final VoidCallback? onRunNow;
  final VoidCallback? onWaitNow;
  final VoidCallback? onBury;

  /// 用户在快捷面板里选定了具体时间
  final void Function(DateTime target)? onSetNextRun;
  final VoidCallback? onOpenSetting;

  @override
  Widget build(BuildContext context) {
    if (model.isAllEmpty()) return const SizedBox.shrink();
    return _TaskRowBody(
      model: model,
      state: state,
      onRunNow: onRunNow,
      onWaitNow: onWaitNow,
      onBury: onBury,
      onSetNextRun: onSetNextRun,
      onOpenSetting: onOpenSetting,
    );
  }
}

class _TaskRowBody extends StatefulWidget {
  const _TaskRowBody({
    required this.model,
    required this.state,
    this.onRunNow,
    this.onWaitNow,
    this.onBury,
    this.onSetNextRun,
    this.onOpenSetting,
  });

  final TaskItemModel model;
  final TaskRowState state;
  final VoidCallback? onRunNow;
  final VoidCallback? onWaitNow;
  final VoidCallback? onBury;
  final void Function(DateTime target)? onSetNextRun;
  final VoidCallback? onOpenSetting;

  @override
  State<_TaskRowBody> createState() => _TaskRowBodyState();
}

class _TaskRowBodyState extends State<_TaskRowBody> {
  bool _hover = false;
  bool _menuOpen = false;

  bool get _isOverdue {
    final dt = widget.model.nextRunDateTime;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  bool get _isBuried => isBuriedRunTime(widget.model.nextRunDateTime);

  @override
  Widget build(BuildContext context) {
    final running = widget.state == TaskRowState.running;
    final buried = _isBuried;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpenSetting,
        onSecondaryTapDown: (details) =>
            _showContextMenu(context, details.globalPosition),
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
              // 时间徽章可点：打开快捷调整
              _TimeBadge(
                time: widget.model.timeLabel,
                date: widget.model.dateLabel,
                running: running,
                overdue: !running && !buried && _isOverdue,
                buried: buried && !running,
                onTap: widget.onSetNextRun == null
                    ? null
                    : () => _openTimeEditor(context),
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
                        // 置底的任务整行文字变灰
                        color: buried
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (running) ...[
                      const SizedBox(height: 2),
                      Text(
                        'RUNNING',
                        style: TextStyle(
                          fontSize: 8.5,
                          height: 1.1,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ] else if (buried) ...[
                      const SizedBox(height: 2),
                      Text(
                        I18n.buried.tr,
                        style: TextStyle(
                          fontSize: 8.5,
                          height: 1.1,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _RowActions(
                highlighted: _hover || running || _menuOpen,
                onRunNow: widget.onRunNow,
                onWaitNow: widget.onWaitNow,
                onOpenSetting: widget.onOpenSetting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTimeEditor(BuildContext context) async {
    final setter = widget.onSetNextRun;
    if (setter == null) return;
    await TaskTimeQuickEditor.show(
      context: context,
      taskName: widget.model.taskName,
      currentNextRun: widget.model.nextRunDateTime,
      onApply: setter,
    );
  }

  Future<void> _showContextMenu(
      BuildContext context, Offset position) async {
    setState(() => _menuOpen = true);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 4, position.dy + 4),
      color: AppColors.panelHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'run',
          height: 34,
          child: _menuRow(Icons.bolt_rounded, I18n.run_now.tr),
        ),
        PopupMenuItem<String>(
          value: 'wait',
          height: 34,
          child: _menuRow(
              Icons.pause_circle_outline_rounded, I18n.wait_now.tr),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'bury',
          height: 34,
          child: _menuRow(
              Icons.vertical_align_bottom_rounded, I18n.bury_one_year.tr),
        ),
        PopupMenuItem<String>(
          value: 'time',
          height: 34,
          child: _menuRow(Icons.schedule_rounded, I18n.adjust_run_time.tr),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'detail',
          height: 34,
          child: _menuRow(Icons.tune_rounded, I18n.task_setting.tr),
        ),
      ],
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    switch (result) {
      case 'run':
        widget.onRunNow?.call();
      case 'wait':
        widget.onWaitNow?.call();
      case 'bury':
        widget.onBury?.call();
      case 'time':
        if (context.mounted) await _openTimeEditor(context);
      case 'detail':
        widget.onOpenSetting?.call();
    }
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: AppText.body),
      ],
    );
  }
}

class _TimeBadge extends StatefulWidget {
  const _TimeBadge({
    required this.time,
    required this.running,
    this.date,
    this.overdue = false,
    this.buried = false,
    this.onTap,
  });

  final String time;
  final String? date;
  final bool running;
  final bool overdue;
  final bool buried;
  final VoidCallback? onTap;

  @override
  State<_TimeBadge> createState() => _TimeBadgeState();
}

class _TimeBadgeState extends State<_TimeBadge> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color borderColor;
    if (widget.running) {
      fg = const Color(0xFF06231A);
      bg = AppColors.accent;
      borderColor = AppColors.accent;
    } else if (widget.buried) {
      // 置底：灰色
      fg = AppColors.textMuted;
      bg = AppColors.panelSoft;
      borderColor = AppColors.borderSoft;
    } else if (widget.overdue) {
      fg = AppColors.danger;
      bg = AppColors.dangerSoft;
      borderColor = AppColors.danger.withValues(alpha: 0.4);
    } else {
      fg = AppColors.textSecondary;
      bg = AppColors.panelHi;
      borderColor = AppColors.border;
    }

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _hover && widget.onTap != null ? AppColors.panelHover : bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: _hover && widget.onTap != null
              ? AppColors.accent
              : borderColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.time,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (widget.date != null) ...[
            const SizedBox(height: 1),
            Text(
              widget.date!,
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

    if (widget.onTap == null) return badge;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        // 只响应时间徽章自身，不触发整行的“打开详情”
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: I18n.adjust_run_time.tr,
          child: badge,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.highlighted,
    this.onRunNow,
    this.onWaitNow,
    this.onOpenSetting,
  });

  /// 鼠标悬停或任务正在运行时高亮；否则低透明度但仍可点
  final bool highlighted;
  final VoidCallback? onRunNow;
  final VoidCallback? onWaitNow;
  final VoidCallback? onOpenSetting;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 130),
      opacity: highlighted ? 1 : 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 立即运行
          AppIconButton(
            icon: const Icon(Icons.bolt_rounded, size: 14),
            size: 23,
            tooltip: I18n.run_now.tr,
            onPressed: onRunNow,
          ),
          const SizedBox(width: 1),
          // 立即等待
          AppIconButton(
            icon: const Icon(Icons.pause_circle_outline_rounded, size: 13),
            size: 23,
            tooltip: I18n.wait_now.tr,
            onPressed: onWaitNow,
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
