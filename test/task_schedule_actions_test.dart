import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/views/overview/task_schedule_actions.dart';

void main() {
  group('runNowTarget', () {
    test('早于当前时间，确保服务端判定为已到期', () {
      final now = DateTime(2026, 11, 9, 23, 0, 0);
      final target = runNowTarget(now);
      expect(target.isBefore(now), isTrue,
          reason: '立即运行必须早于 now，否则会进 waiting 队列');
    });

    test('不早太多，避免时间标签显示成前一天', () {
      final now = DateTime(2026, 11, 9, 23, 0, 0);
      final target = runNowTarget(now);
      expect(now.difference(target).inMinutes, lessThan(5));
    });
  });

  group('waitNowTarget', () {
    test('晚于当前时间', () {
      final now = DateTime(2026, 11, 9, 23, 0, 0);
      expect(waitNowTarget(now).isAfter(now), isTrue);
    });

    test('至少推后 2 分钟，避开服务端 nearest_future 的 120 秒吸并窗口', () {
      final now = DateTime(2026, 11, 9, 23, 0, 0);
      final target = waitNowTarget(now);
      expect(target.difference(now).inSeconds, greaterThanOrEqualTo(120),
          reason: 'nearest_future 会把 120 秒内的多个候选合并，推得太近会失效');
    });
  });

  group('buryTarget', () {
    test('正好一年后，且保留时分秒', () {
      final now = DateTime(2026, 11, 9, 13, 45, 30);
      final target = buryTarget(now);
      expect(target.year, 2027);
      expect(target.month, 11);
      expect(target.day, 9);
      expect(target.hour, 13);
      expect(target.minute, 45);
      expect(target.second, 30);
    });

    test('闰日不会被崩掉（2/29 → 次年 2/28 或 3/1）', () {
      final leap = DateTime(2028, 2, 29, 12, 0, 0);
      final target = buryTarget(leap);
      // DateTime 会自动归一化非法日期，不应抛异常
      expect(target.year, 2029);
      expect(target.isAfter(leap), isTrue);
    });
  });

  group('isBuriedRunTime', () {
    test('一年后视为置底', () {
      final now = DateTime(2026, 11, 9, 12, 0, 0);
      expect(isBuriedRunTime(DateTime(2027, 11, 9, 12, 0, 0), now), isTrue);
    });

    test('几天后不算置底', () {
      final now = DateTime(2026, 11, 9, 12, 0, 0);
      expect(isBuriedRunTime(now.add(const Duration(days: 3)), now), isFalse);
    });

    test('过去时间不算置底', () {
      final now = DateTime(2026, 11, 9, 12, 0, 0);
      expect(isBuriedRunTime(DateTime(2023, 1, 1), now), isFalse);
    });

    test('null 安全', () {
      expect(isBuriedRunTime(null), isFalse);
    });

    test('边界：180 天整不算置底（用 isAfter）', () {
      final now = DateTime(2026, 11, 9, 12, 0, 0);
      expect(isBuriedRunTime(now.add(const Duration(days: 180)), now), isFalse);
      expect(isBuriedRunTime(now.add(const Duration(days: 181)), now), isTrue);
    });
  });

  group('formatNextRun', () {
    test('输出服务端要求的 YYYY-MM-DD HH:MM:SS', () {
      expect(
        formatNextRun(DateTime(2026, 1, 2, 3, 4, 5)),
        '2026-01-02 03:04:05',
      );
    });

    test('个位数补零', () {
      expect(
        formatNextRun(DateTime(2027, 9, 8, 7, 6, 5)),
        '2027-09-08 07:06:05',
      );
    });

    test('可被 DateTime.parse 反向解析回来（服务端就是这么解析的）', () {
      final dt = DateTime(2027, 3, 4, 5, 6, 7);
      expect(DateTime.parse(formatNextRun(dt)), dt);
    });
  });
}
