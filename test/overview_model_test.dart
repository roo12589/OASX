import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/task_item_model.dart';
import 'package:oasx/views/overview/overview_model.dart';

void main() {
  group('TaskItemModel', () {
    test('解析 OAS 下发的 next_run 格式', () {
      for (final raw in [
        '2026-11-09 20:40:00',
        '2026-11-09 20:40:00.123456',
        '2026-11-09T20:40:00',
        '2026-11-09 20:40:00+08:00',
      ]) {
        final m = TaskItemModel('X', raw);
        expect(m.nextRunDateTime, isNotNull, reason: '解析失败: "$raw"');
        expect(m.timeLabel, '20:40', reason: '时间标签错误: "$raw"');
      }
    });

    test('空模型与非法时间', () {
      expect(TaskItemModel.empty().isAllEmpty(), isTrue);
      final bad = TaskItemModel('X', 'not-a-date');
      expect(bad.nextRunDateTime, isNull);
      expect(bad.timeLabel, 'not-a-date');
    });

    test('今天 / 非今天的日期标签', () {
      final now = DateTime.now();
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} 10:00:00';

      final today = TaskItemModel('A', fmt(now));
      expect(today.isToday, isTrue);
      expect(today.dateLabel, isNull, reason: '今天不需要额外日期标签');

      final future = TaskItemModel('B', fmt(now.add(const Duration(days: 5))));
      expect(future.isToday, isFalse);
      expect(future.dateLabel, isNotNull);
    });

    test('相等性用于 Rx 去抖', () {
      const a = TaskItemModel('A', '2026-01-01 00:00:00');
      const b = TaskItemModel('A', '2026-01-01 00:00:00');
      const c = TaskItemModel('A', '2026-01-02 00:00:00');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('buildDateBuckets', () {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:00:00';

    test('统计 pending 与 waiting', () {
      // 固定基准时间（上午 09:00），避免跨零点时 +2h/+5h 落到不同日期
      final now = DateTime(2026, 11, 9, 9, 0, 0);
      final buckets = buildDateBuckets(
        pending: [
          TaskItemModel('A', fmt(now.add(const Duration(hours: 2)))),
          TaskItemModel('B', fmt(now.add(const Duration(hours: 5)))),
        ],
        waiting: [
          TaskItemModel('C', fmt(now.add(const Duration(days: 1)))),
        ],
        weekdayLabel: weekdayLabelCn,
        todayLabel: '今天',
        now: now,
      );

      expect(buckets.length, 8);
      expect(buckets[0].count, 2, reason: '今天两个任务');
      expect(buckets[1].count, 1, reason: '明天一个任务');
      expect(buckets[0].label, '今天');
      expect(buckets[0].isToday, isTrue);
      expect(buckets[1].isToday, isFalse);
    });

    test('跨零点：+2h 在今天、+20h 在明天', () {
      // 22:00 起算，+2h 是今晚 24:00 前，+5h 已到次日
      final now = DateTime(2026, 11, 9, 22, 0, 0);
      final buckets = buildDateBuckets(
        pending: [
          TaskItemModel('A', fmt(now.add(const Duration(hours: 1)))),
          TaskItemModel('B', fmt(now.add(const Duration(hours: 4)))),
        ],
        waiting: const [],
        weekdayLabel: weekdayLabelCn,
        todayLabel: '今天',
        now: now,
      );

      expect(buckets[0].count, 1, reason: '23:00 属于今天');
      expect(buckets[1].count, 1, reason: '02:00 属于明天');
    });

    test('过期任务计入今天，超出窗口的不计入', () {
      final now = DateTime(2026, 11, 9, 9, 0, 0);
      final buckets = buildDateBuckets(
        pending: [
          // OAS 默认值 2023-01-01，属于「早就该跑但没跑」
          TaskItemModel('Overdue', '2023-01-01 00:00:00'),
        ],
        waiting: [
          TaskItemModel('Future', fmt(now.add(const Duration(days: 30)))),
        ],
        weekdayLabel: weekdayLabelCn,
        todayLabel: '今天',
        now: now,
      );

      expect(buckets[0].count, 1, reason: '过期任务算今天');
      final total = buckets.fold<int>(0, (s, e) => s + e.count);
      expect(total, 1, reason: '30 天后的任务在 8 天窗口外');
    });

    test('无任务时全为 0，但仍生成 8 格', () {
      final buckets = buildDateBuckets(
        pending: const [],
        waiting: const [],
        weekdayLabel: weekdayLabelCn,
        todayLabel: I18n.today,
        now: DateTime(2026, 11, 9, 9, 0, 0),
      );
      expect(buckets.length, 8);
      expect(buckets.every((b) => b.count == 0), isTrue);
    });

    test('upcomingTimes 参与统计', () {
      final now = DateTime(2026, 11, 9, 9, 0, 0);
      final buckets = buildDateBuckets(
        pending: [
          TaskItemModel('A', fmt(now.add(const Duration(hours: 1)))),
        ],
        waiting: const [],
        weekdayLabel: weekdayLabelCn,
        todayLabel: '今天',
        upcomingTimes: [now, now.add(const Duration(days: 2))],
        now: now,
      );
      expect(buckets[0].count, 2);
      expect(buckets[2].count, 1);
    });
  });

  group('weekdayLabelCn', () {
    test('周一到周日', () {
      expect(weekdayLabelCn(1), '周一');
      expect(weekdayLabelCn(7), '周日');
      expect(weekdayLabelCn(0), '');
      expect(weekdayLabelCn(8), '');
    });
  });
}
