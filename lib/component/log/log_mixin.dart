import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:oasx/component/log/log_store.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/utils/error_reporter.dart';

/// 日志滚动回调。
///
/// 注意：日志面板有多个 Tab（日志/运行日志/错误日志），每个 Tab 都有自己的
/// 滚动列表。早期实现用单个 `scrollLogs` 字段，谁最后 initState 谁覆盖，
/// 结果只有其中一个列表会滚动 —— 这是「日志不自动滚动」的根因。
/// 现改为注册表：每个列表注册自己的回调，广播给全部。
typedef LogScrollCallback = void Function({
  bool isJump,
  bool force,
  int scrollOffset,
});

mixin LogMixin on GetxController {
  /// max lines to store in log
  int get maxLines => 2000;

  /// max logs+pending
  int get maxBuffer => 5000;

  /// max burst line when refreshing
  int get maxBurst => 50;

  /// min burst line when refreshing
  int get minBurst => 1;

  /// 持久化存储（子类可覆盖以按脚本名分目录）
  late final LogStore logStore = LogStore(scriptName: logStoreName);

  /// 日志存储的子目录名，默认按控制器类型区分
  String get logStoreName => runtimeType.toString();

  /// ui log
  final logs = <String>[].obs;

  /// auto scroll to bottom
  final autoScroll = true.obs;

  /// collapse log content
  final collapseLog = false.obs;

  /// 是否开启持久化（写盘）。历史页面只读，不应写盘。
  bool get enablePersistence => true;

  /// logs buffer, used to limit speeded log refresh
  final _pendingLogs = <String>[];

  /// refresh timer for log
  Timer? _refreshTimer;

  double _savedScrollOffset = 0.0;

  /// 所有已挂载日志列表的滚动回调
  final Set<LogScrollCallback> _scrollCallbacks = {};

  /// 兼容旧 API：设置单个回调
  @Deprecated('用 registerScrollCallback / unregisterScrollCallback')
  set scrollLogs(LogScrollCallback? cb) {
    _scrollCallbacks.clear();
    if (cb != null) _scrollCallbacks.add(cb);
  }

  void registerScrollCallback(LogScrollCallback cb) {
    _scrollCallbacks.add(cb);
  }

  void unregisterScrollCallback(LogScrollCallback cb) {
    _scrollCallbacks.remove(cb);
  }

  /// 广播滚动（只有可见的那个列表会真正执行 jump）
  void requestScroll({bool isJump = false, bool force = false, int scrollOffset = -1}) {
    for (final cb in List<LogScrollCallback>.from(_scrollCallbacks)) {
      cb(isJump: isJump, force: force, scrollOffset: scrollOffset);
    }
  }

  @override
  void onInit() {
    _refreshTimer ??= Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_pendingLogs.isEmpty) return;
      final hadNew = _updateUILogs();
      _clearOverflowLogs();
      _removeUIOldLogs();
      // 只有真的追加了新行才滚动，避免空转
      if (hadNew) {
        requestScroll();
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _scrollCallbacks.clear();
    super.onClose();
  }

  void _removeUIOldLogs() {
    // UI 限制：只保留最新 maxLines 行
    // 注意：以前这里在 !autoScroll 时直接 return，导致用户往上翻之后
    // 内存里的 logs 无限增长（pending 也在长），最终卡死。
    if (logs.length > maxLines) {
      logs.removeRange(0, logs.length - maxLines);
    }
  }

  /// 把缓冲区的行搬进 UI 列表，返回是否新增了内容
  bool _updateUILogs() {
    final int backlog = _pendingLogs.length;
    if (backlog == 0) return false;
    final int burst = backlog.clamp(minBurst, maxBurst);
    final take = min(burst, _pendingLogs.length);
    if (take <= 0) return false;
    final batch = _pendingLogs.sublist(0, take);
    _pendingLogs.removeRange(0, take);
    logs.addAll(batch);
    return true;
  }

  void _clearOverflowLogs() {
    // 计算总大小
    int totalSize = logs.length + _pendingLogs.length;
    if (totalSize > maxBuffer) {
      int overflow = totalSize - maxBuffer;
      // 优先删除 logs 里最老的
      if (overflow > 0) {
        int removeFromLogs = min(overflow, logs.length);
        if (removeFromLogs > 0) {
          logs.removeRange(0, removeFromLogs);
          overflow -= removeFromLogs;
        }
      }
      // 如果还不够，就从 pending 里删除最老的
      if (overflow > 0 && _pendingLogs.isNotEmpty) {
        int removeFromPending = min(overflow, _pendingLogs.length);
        _pendingLogs.removeRange(0, removeFromPending);
      }
    }
  }

  void addLog(String log) {
    _pendingLogs.add(log);
    if (enablePersistence) {
      logStore.append(log);
    }
    // 脚本往日志里打 ERROR / CRITICAL 时，按需弹系统通知
    // （开关在工具页，默认关闭；内部有节流，不会刷屏）
    if (_looksLikeError(log)) {
      ErrorReporter.report(
        log,
        source: logStoreName,
        notify: true,
      );
    }
  }

  /// 粗略判断一行日志是否是错误日志
  bool _looksLikeError(String log) {
    return log.contains('ERROR') || log.contains('CRITICAL');
  }

  void clearLog() {
    logs.clear();
    _pendingLogs.clear();
  }

  /// 清空（含磁盘）
  Future<void> clearLogAndStore() async {
    clearLog();
    await logStore.clearAll();
  }

  void copyLogs() {
    final allLogs = logs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    Get.snackbar(I18n.tip.tr, I18n.copy_success.tr,
        duration: const Duration(seconds: 1));
  }

  void toggleAutoScroll() {
    autoScroll.value = !autoScroll.value;
    if (autoScroll.value) {
      requestScroll(force: true, scrollOffset: -1);
    }
  }

  void toggleCollapse() => collapseLog.value = !collapseLog.value;

  double get savedScrollOffsetVal => _savedScrollOffset;
  void saveScrollOffset(double offset) {
    _savedScrollOffset = offset;
  }
}
