/// 任务下一次运行时间的快捷调整逻辑。
///
/// 纯函数，不依赖 GetX / 网络，便于单测。
///
/// 注意服务端的语义（module/config/config.py）：
/// - `next_run` 早于当前时间 → 进入 pending（马上跑）
/// - `next_run` 晚于当前时间 → 进入 waiting，按时间升序排队
///
/// 因此这里的「立即运行」= 把时间设成当前时间（略提前，避免边界竞争），
/// 「立即等待」= 把时间设成稍后，让它退出待跑队列；
/// 「置底」= 推到一年后。
library;

/// 置底时的偏移：一年
Duration get buryDuration => const Duration(days: 365);

/// 「立即运行」的目标时间：略微早于当前，确保服务端判定为已到期。
DateTime runNowTarget([DateTime? now]) {
  final base = now ?? DateTime.now();
  return base.subtract(const Duration(seconds: 5));
}

/// 「立即等待」的目标时间：稍后。
///
/// 服务端 `nearest_future` 的吸并窗口是 120 秒，
/// 所以这里至少推后 2 分钟，否则可能被吸并回「马上到期」。
DateTime waitNowTarget([DateTime? now]) {
  final base = now ?? DateTime.now();
  return base.add(const Duration(minutes: 3));
}

/// 「置底」的目标时间：一年后（保留原来的时分秒）
DateTime buryTarget([DateTime? now]) {
  final base = now ?? DateTime.now();
  return DateTime(
    base.year + 1,
    base.month,
    base.day,
    base.hour,
    base.minute,
    base.second,
  );
}

/// 判断某个 next_run 是否已被「置底」：晚于「现在 + 180 天」即视为置底。
///
/// 用于界面上把它显示成灰色。
bool isBuriedRunTime(DateTime? nextRun, [DateTime? now]) {
  if (nextRun == null) return false;
  final base = now ?? DateTime.now();
  return nextRun.isAfter(base.add(const Duration(days: 180)));
}

/// 把时间格式化成服务端要求的 `YYYY-MM-DD HH:MM:SS`
String formatNextRun(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}
