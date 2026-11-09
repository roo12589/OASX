import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/controller/nav_tab_order.dart';

void main() {
  group('resolveTabOrder', () {
    test('首次启动（无保存顺序）时保持服务端顺序', () {
      final result = resolveTabOrder(
        existing: ['A', 'B', 'C'],
        saved: const [],
      );
      expect(result, ['A', 'B', 'C']);
    });

    test('已保存顺序优先，新增项追加到末尾', () {
      final result = resolveTabOrder(
        existing: ['A', 'B', 'C', 'D'],
        saved: ['C', 'A'],
      );
      expect(result, ['C', 'A', 'B', 'D']);
    });

    test('已保存但服务端已删除的项被丢弃', () {
      final result = resolveTabOrder(
        existing: ['A', 'C'],
        saved: ['C', 'B', 'A'],
      );
      expect(result, ['C', 'A']);
      expect(result, isNot(contains('B')));
    });

    test('保存顺序里出现重复项时不重复输出', () {
      final result = resolveTabOrder(
        existing: ['A', 'B'],
        saved: ['B', 'B', 'A'],
      );
      expect(result, ['B', 'A']);
    });

    test('空服务端列表返回空', () {
      expect(
        resolveTabOrder(existing: const [], saved: ['A']),
        isEmpty,
      );
    });
  });

  group('visibleTabs', () {
    test('排除隐藏项且保持顺序', () {
      expect(
        visibleTabs(order: ['A', 'B', 'C'], hidden: {'B'}),
        ['A', 'C'],
      );
    });

    test('全部隐藏时返回空', () {
      expect(
        visibleTabs(order: ['A', 'B'], hidden: {'A', 'B'}),
        isEmpty,
      );
    });
  });

  group('reorderVisibleTabs', () {
    test('向后拖拽：A 移到 C 之后', () {
      // 可见 [A,B,C]；把 index0 拖到 index3（C 之后）
      final result = reorderVisibleTabs(
        order: ['A', 'B', 'C'],
        hidden: const {},
        oldIndex: 0,
        newIndex: 3,
      );
      expect(result, ['B', 'C', 'A']);
    });

    test('向前拖拽：C 移到 A 之前', () {
      final result = reorderVisibleTabs(
        order: ['A', 'B', 'C'],
        hidden: const {},
        oldIndex: 2,
        newIndex: 0,
      );
      expect(result, ['C', 'A', 'B']);
    });

    test('隐藏项排到末尾且保持相对顺序', () {
      final result = reorderVisibleTabs(
        order: ['A', 'H1', 'B', 'H2', 'C'],
        hidden: {'H1', 'H2'},
        oldIndex: 0,
        newIndex: 3,
      );
      // 可见 [A,B,C] -> [B,C,A]，隐藏项 H1,H2 追加到尾部
      expect(result, ['B', 'C', 'A', 'H1', 'H2']);
    });

    test('越界索引原样返回', () {
      final order = ['A', 'B'];
      expect(
        reorderVisibleTabs(
            order: order, hidden: const {}, oldIndex: 5, newIndex: 0),
        order,
      );
    });

    test('没有可见项时原样返回', () {
      final order = ['H1'];
      expect(
        reorderVisibleTabs(
            order: order, hidden: {'H1'}, oldIndex: 0, newIndex: 0),
        order,
      );
    });

    test('同位置拖拽不改变顺序', () {
      final result = reorderVisibleTabs(
        order: ['A', 'B', 'C'],
        hidden: const {},
        oldIndex: 1,
        newIndex: 1,
      );
      expect(result, ['A', 'B', 'C']);
    });
  });

  group('moveVisibleTab', () {
    test('左移一格', () {
      expect(
        moveVisibleTab(
            order: ['A', 'B', 'C'], hidden: const {}, name: 'B', delta: -1),
        ['B', 'A', 'C'],
      );
    });

    test('右移一格', () {
      expect(
        moveVisibleTab(
            order: ['A', 'B', 'C'], hidden: const {}, name: 'B', delta: 1),
        ['A', 'C', 'B'],
      );
    });

    test('已在最左再左移时不变', () {
      expect(
        moveVisibleTab(
            order: ['A', 'B'], hidden: const {}, name: 'A', delta: -1),
        ['A', 'B'],
      );
    });

    test('已在最右再右移时不变', () {
      expect(
        moveVisibleTab(
            order: ['A', 'B'], hidden: const {}, name: 'B', delta: 1),
        ['A', 'B'],
      );
    });

    test('隐藏项不参与可见移动，仍留在末尾', () {
      expect(
        moveVisibleTab(
          order: ['A', 'B', 'H'],
          hidden: {'H'},
          name: 'B',
          delta: -1,
        ),
        ['B', 'A', 'H'],
      );
    });

    test('对隐藏项调用移动时不变', () {
      final order = ['A', 'H'];
      expect(
        moveVisibleTab(order: order, hidden: {'H'}, name: 'H', delta: -1),
        order,
      );
    });

    test('名字不存在时不变', () {
      final order = ['A'];
      expect(
        moveVisibleTab(order: order, hidden: const {}, name: 'X', delta: 1),
        order,
      );
    });
  });
}
