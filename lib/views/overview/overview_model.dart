
import 'package:oasx/model/task_item_model.dart';

/// 日期分布格：某一天的任务数量
class DateBucket {
  const DateBucket({
    required this.label,
    required this.count,
    required this.isToday,
    required this.date,
  });

  final String label;
  final int count;
  final bool isToday;
  final DateTime date;
}

/// 任务列表里的展示行
class TaskRow {
  const TaskRow({required this.model, required this.state});

  final TaskItemModel model;
  final TaskRowState state;
}

enum TaskRowState { running, pending, waiting }

String weekdayLabelCn(int weekday) {
  return switch (weekday) {
    1 => '周一',
    2 => '周二',
    3 => '周三',
    4 => '周四',
    5 => '周五',
    6 => '周六',
    7 => '周日',
    _ => '',
  };
}

String weekdayLabelEn(int weekday) {
  return switch (weekday) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    7 => 'Sun',
    _ => '',
  };
}

/// 从调度器任务列表推导出「未来 N 天」的日期分布。
///
/// 只做展示层聚合：读取每个任务的 next_run 时间并计数。
///
/// [now] 仅用于测试注入固定的「当前时间」；生产代码不传，取系统时间。
/// 不注入的话，跨零点前后跑的测试结果会漂移。
List<DateBucket> buildDateBuckets({
  required List<TaskItemModel> pending,
  required List<TaskItemModel> waiting,
  required String Function(int weekday) weekdayLabel,
  required String todayLabel,
  List<DateTime>? upcomingTimes,
  int days = 8,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final start = DateTime(current.year, current.month, current.day);
  final counts = List<int>.filled(days, 0);

  void addTime(DateTime dt) {
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(start).inDays;
    // 已过期的任务（next_run 在过去）算作今天就该跑，计入第 0 格
    if (diff < 0) {
      counts[0] += 1;
      return;
    }
    if (diff >= days) return;
    counts[diff] += 1;
  }

  for (final task in [...pending, ...waiting]) {
    final dt = task.nextRunDateTime;
    if (dt != null) addTime(dt);
  }
  if (upcomingTimes != null) {
    for (final dt in upcomingTimes) {
      addTime(dt);
    }
  }

  return List<DateBucket>.generate(days, (i) {
    final date = start.add(Duration(days: i));
    return DateBucket(
      label: i == 0 ? todayLabel : weekdayLabel(date.weekday),
      count: counts[i],
      isToday: i == 0,
      date: date,
    );
  });
}
