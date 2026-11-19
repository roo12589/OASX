import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/overview/task_schedule_actions.dart';

/// 点击任务时间后弹出的快捷调整面板。
///
/// 不进入任务详情页就能改 next_run。
class TaskTimeQuickEditor extends StatefulWidget {
  const TaskTimeQuickEditor({
    super.key,
    required this.taskName,
    required this.currentNextRun,
    required this.onApply,
  });

  final String taskName;

  /// 当前 next_run（可能为 null / 非法）
  final DateTime? currentNextRun;

  /// 应用新的时间
  final void Function(DateTime target) onApply;

  /// 以底部弹层形式打开
  static Future<void> show({
    required BuildContext context,
    required String taskName,
    required DateTime? currentNextRun,
    required void Function(DateTime target) onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => TaskTimeQuickEditor(
        taskName: taskName,
        currentNextRun: currentNextRun,
        onApply: onApply,
      ),
    );
  }

  @override
  State<TaskTimeQuickEditor> createState() => _TaskTimeQuickEditorState();
}

class _TaskTimeQuickEditorState extends State<TaskTimeQuickEditor> {
  late DateTime _target;

  @override
  void initState() {
    super.initState();
    final base = widget.currentNextRun;
    final now = DateTime.now();
    _target = (base == null || base.isBefore(now))
        ? now.add(const Duration(minutes: 5))
        : base;
    // 秒对齐到 0，界面更好读
    _target = DateTime(_target.year, _target.month, _target.day, _target.hour,
        _target.minute, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: AppPanel(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${I18n.adjust_run_time.tr} · ${widget.taskName.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sectionTitle,
                    ),
                  ),
                  AppIconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    size: 26,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const AppDivider(),

            // 快捷动作
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    label: I18n.run_now.tr,
                    icon: Icons.bolt_rounded,
                    accent: true,
                    onTap: () => _apply(runNowTarget()),
                  ),
                  _QuickChip(
                    label: I18n.wait_now.tr,
                    icon: Icons.pause_circle_outline_rounded,
                    onTap: () => _apply(waitNowTarget()),
                  ),
                  _QuickChip(
                    label: I18n.bury_one_year.tr,
                    icon: Icons.vertical_align_bottom_rounded,
                    onTap: () => _apply(buryTarget()),
                  ),
                ],
              ),
            ),

            // 具体时间
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Text(I18n.custom_time.tr, style: AppText.label),
                  const Spacer(),
                  Text(
                    formatNextRun(_target),
                    style: AppText.mono.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StepButton(
                    label: '+1h',
                    onTap: () => _shift(const Duration(hours: 1)),
                  ),
                  _StepButton(
                    label: '+1d',
                    onTap: () => _shift(const Duration(days: 1)),
                  ),
                  _StepButton(
                    label: '-1d',
                    onTap: () => _shift(const Duration(days: -1)),
                  ),
                  _StepButton(
                    label: '+7d',
                    onTap: () => _shift(const Duration(days: 7)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const AppDivider(),

            // 确定 / 取消
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(I18n.cancel.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _apply(_target),
                    child: Text(I18n.confirm.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shift(Duration d) {
    setState(() => _target = _target.add(d));
  }

  void _apply(DateTime target) {
    widget.onApply(target);
    Navigator.of(context).maybePop();
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppColors.accentDark : AppColors.panelSoft,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: accent ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: accent ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 11.5,
                  fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
                  color: accent ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panelHi,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Text(
            label,
            style: AppText.mono.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
