/// 调度器任务项：任务名 + 下一次运行时间字符串
class TaskItemModel {
  final String taskName;
  final String nextRun;

  const TaskItemModel(this.taskName, this.nextRun);

  static TaskItemModel empty() => const TaskItemModel('', '');

  bool isAllEmpty() => taskName.isEmpty && nextRun.isEmpty;

  bool get isEmpty => isAllEmpty();

  /// 服务端下发格式为 "YYYY-MM-DD HH:MM:SS"（也可能带时区偏移）
  /// 统一转成本地时间，避免带偏移的字符串被当成 UTC 显示。
  DateTime? get nextRunDateTime {
    final dt = DateTime.tryParse(nextRun);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  /// 只显示 HH:mm
  String get timeLabel {
    final dt = nextRunDateTime;
    if (dt == null) return nextRun.isEmpty ? '--:--' : nextRun;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 该任务是否就在今天（含已过期的情况）
  bool get isToday {
    final dt = nextRunDateTime;
    if (dt == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !dt.isAfter(
        today.add(const Duration(days: 1) - const Duration(milliseconds: 1)));
  }

  /// 非今天的任务额外显示日期，避免"20:44"这类时间被误读为今天。
  ///
  /// 跨年时带上年份——置底（一年后）如果只显示「11-09」，
  /// 会被误读成今年今天。
  String? get dateLabel {
    final dt = nextRunDateTime;
    if (dt == null) return null;
    if (isToday) return null;
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final sameYear = dt.year == DateTime.now().year;
    return sameYear ? '$mm-$dd' : '${dt.year}-$mm-$dd';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItemModel &&
          runtimeType == other.runtimeType &&
          taskName == other.taskName &&
          nextRun == other.nextRun;

  @override
  int get hashCode => Object.hash(taskName, nextRun);

  @override
  String toString() => 'TaskItemModel($taskName, $nextRun)';
}
