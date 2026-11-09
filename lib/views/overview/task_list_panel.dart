import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/task_item_model.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/overview/overview_model.dart';
import 'package:oasx/views/overview/taskitem_view.dart';

/// 左侧任务列表面板
class TaskListPanel extends StatefulWidget {
  const TaskListPanel({
    super.key,
    required this.rows,
    required this.showAll,
    required this.searching,
    required this.onToggleAll,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onRunNow,
    required this.onPinTop,
    required this.onPinBottom,
    required this.onOpenSetting,
  });

  final List<TaskRow> rows;
  final bool showAll;
  final bool searching;
  final VoidCallback onToggleAll;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TaskItemModel> onRunNow;
  final ValueChanged<TaskItemModel> onPinTop;
  final ValueChanged<TaskItemModel> onPinBottom;
  final ValueChanged<TaskItemModel> onOpenSetting;

  @override
  State<TaskListPanel> createState() => _TaskListPanelState();
}

class _TaskListPanelState extends State<TaskListPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final others = widget.rows.length;
    return AppPanel(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 8, 9),
            child: Row(
              children: [
                Text(I18n.tasks.tr, style: AppText.sectionTitle),
                const SizedBox(width: 8),
                Text(
                  '${I18n.others.tr} $others ${I18n.items.tr}',
                  style: AppText.caption,
                ),
                const Spacer(),
                AppIconButton(
                  icon: Icon(
                    widget.searching
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    size: 14,
                  ),
                  size: 24,
                  tooltip: I18n.search_task.tr,
                  onPressed: widget.onToggleSearch,
                ),
                const SizedBox(width: 2),
                AppIconButton(
                  icon: Icon(
                    widget.showAll
                        ? Icons.view_agenda_rounded
                        : Icons.view_agenda_outlined,
                    size: 14,
                  ),
                  size: 24,
                  tooltip: I18n.overview.tr,
                  onPressed: widget.onToggleAll,
                ),
              ],
            ),
          ),
          if (widget.searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: AppColors.panelSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: widget.onSearchChanged,
                        autofocus: true,
                        style: AppText.body,
                        cursorColor: AppColors.accent,
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'search',
                          hintStyle: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const AppDivider(),
          Expanded(
            child: widget.rows.isEmpty
                ? const _EmptyTasks()
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    itemCount: widget.rows.length,
                    itemBuilder: (context, index) {
                      final row = widget.rows[index];
                      return TaskItemView(
                        key: ValueKey('${row.state.name}-${row.model.taskName}'),
                        model: row.model,
                        state: row.state,
                        onRunNow: () => widget.onRunNow(row.model),
                        onPinTop: () => widget.onPinTop(row.model),
                        onPinBottom: () => widget.onPinBottom(row.model),
                        onOpenSetting: () => widget.onOpenSetting(row.model),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 26, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(I18n.no_task.tr, style: AppText.caption),
        ],
      ),
    );
  }
}
