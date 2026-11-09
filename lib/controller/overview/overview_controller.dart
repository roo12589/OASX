import 'package:get/get.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/model/task_item_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/views/overview/overview_model.dart';

/// 总览控制器：任务列表聚合、搜索、任务操作
class OverviewController extends GetxController with LogMixin {
  String name;
  final scriptService = Get.find<ScriptService>();
  late final scriptModel = scriptService.findScriptModel(name)!;

  /// 是否显示全部任务
  final showAll = false.obs;

  /// 是否处于搜索态
  final searching = false.obs;

  /// 搜索关键字
  final searchKeyword = ''.obs;

  OverviewController({required this.name});

  /// 标题：优先脚本名
  String get displayTitle {
    if (name.isEmpty) return 'OASX';
    return name;
  }

  /// 错误日志计数
  int get errorCount => logs
      .where((e) => e.contains('ERROR') || e.contains('CRITICAL'))
      .length;

  /// 左栏日期分布
  List<DateBucket> get dateBuckets => buildDateBuckets(
        pending: scriptModel.pendingTaskList,
        waiting: scriptModel.waitingTaskList,
        weekdayLabel: weekdayLabelCn,
        todayLabel: I18n.today.tr,
        upcomingTimes: _runningTime != null ? [_runningTime!] : null,
      );

  /// 8 天窗口之外还有任务时，给出一个「更远」的提示，避免用户误以为任务丢了
  String? get farthestTaskLabel {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    DateTime? farthest;
    for (final task in [
      ...scriptModel.pendingTaskList,
      ...scriptModel.waitingTaskList,
    ]) {
      final dt = task.nextRunDateTime;
      if (dt == null) continue;
      if (dt.isBefore(now)) continue;
      if (dt.difference(start).inDays < 8) continue;
      if (farthest == null || dt.isAfter(farthest)) farthest = dt;
    }
    if (farthest == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${farthest.year}-${two(farthest.month)}-${two(farthest.day)}';
  }

  DateTime? get _runningTime => scriptModel.runningTask.value.nextRunDateTime;

  /// 聚合出左栏要展示的任务行
  List<TaskRow> buildRows() {
    final model = scriptModel;
    final rows = <TaskRow>[];
    final running = model.runningTask.value;
    if (!running.isAllEmpty()) {
      rows.add(TaskRow(model: running, state: TaskRowState.running));
    }
    final keyword = searchKeyword.value.trim().toLowerCase();
    bool matches(TaskItemModel item) =>
        keyword.isEmpty || item.taskName.toLowerCase().contains(keyword);

    for (final item in model.pendingTaskList) {
      if (item.isAllEmpty() || !matches(item)) continue;
      rows.add(TaskRow(model: item, state: TaskRowState.pending));
    }
    for (final item in model.waitingTaskList) {
      if (item.isAllEmpty() || !matches(item)) continue;
      rows.add(TaskRow(model: item, state: TaskRowState.waiting));
    }
    rows.sort((a, b) {
      final ta = a.model.nextRunDateTime;
      final tb = b.model.nextRunDateTime;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });
    return rows;
  }

  // ---------------------------- 交互 ----------------------------

  void toggleShowAll() => showAll.value = !showAll.value;

  void toggleSearch() {
    searching.value = !searching.value;
    if (!searching.value) searchKeyword.value = '';
  }

  void setSearchKeyword(String value) => searchKeyword.value = value;

  Future<void> toggleScript() async {
    if (scriptModel.state.value != ScriptState.running) {
      scriptService.startScript(name);
      clearLog();
      Get.snackbar(I18n.tip.tr, '${I18n.running.tr}: $name',
          duration: const Duration(seconds: 2));
    } else {
      scriptService.stopScript(name);
    }
  }

  Future<void> runNow(TaskItemModel model) async {
    if (model.taskName.isEmpty) return;
    await _setNextRun(model.taskName, DateTime.now());
  }

  Future<void> pinTop(TaskItemModel model) async {
    if (model.taskName.isEmpty) return;
    await _setNextRun(model.taskName, DateTime.now());
  }

  Future<void> pinBottom(TaskItemModel model) async {
    if (model.taskName.isEmpty) return;
    final now = DateTime.now();
    await _setNextRun(
        model.taskName, DateTime(now.year + 1, now.month, now.day));
  }

  Future<void> runNextTaskNow() async {
    final rows = buildRows();
    if (rows.isEmpty) return;
    await runNow(rows.first.model);
  }

  Future<void> _setNextRun(String task, DateTime when) async {
    final value = _formatDateTime(when);
    final success = await ApiClient().putScriptArg(
      name,
      task,
      'scheduler',
      'next_run',
      'string',
      value,
    );
    if (success) {
      Get.snackbar(
        I18n.tip.tr,
        '$task ${I18n.task_next_run_updated_to.tr}: $value',
        duration: const Duration(seconds: 1),
      );
      scriptService.wsService.send(name, 'get_schedule');
    } else {
      Get.snackbar(
        I18n.operation_failed.tr,
        I18n.update_task_next_run_failed.tr,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void openTaskSetting(TaskItemModel model) {
    if (model.taskName.isEmpty) return;
    Get.find<NavCtrl>().switchContent(model.taskName);
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
