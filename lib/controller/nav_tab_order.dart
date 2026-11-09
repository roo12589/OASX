/// 配置选项卡的纯排序/过滤逻辑。
///
/// 抽成纯函数（不依赖 GetX / 网络），方便单测覆盖。
library;

/// 合并「已保存的顺序」与「服务端当前返回的配置列表」。
///
/// - 已保存顺序中仍存在的配置，保持原相对顺序
/// - 服务端新出现、尚未保存过顺序的配置，按服务端顺序追加到末尾
/// - 已保存但服务端已删除的配置，丢弃
///
/// [existing] 不含 'Home'；返回的列表也不含 'Home'。
List<String> resolveTabOrder({
  required List<String> existing,
  required List<String> saved,
}) {
  final existingSet = existing.toSet();
  final result = <String>[];
  for (final name in saved) {
    if (existingSet.contains(name) && !result.contains(name)) {
      result.add(name);
    }
  }
  for (final name in existing) {
    if (!result.contains(name)) result.add(name);
  }
  return result;
}

/// 从完整顺序中取出可见标签（排除隐藏项）。
List<String> visibleTabs({
  required List<String> order,
  required Set<String> hidden,
}) {
  return order.where((e) => !hidden.contains(e)).toList();
}

/// 在「可见标签」上做拖拽重排，返回重排后的**完整顺序**。
///
/// 隐藏项不参与重排，统一排到末尾并保持它们之间的相对顺序。
List<String> reorderVisibleTabs({
  required List<String> order,
  required Set<String> hidden,
  required int oldIndex,
  required int newIndex,
}) {
  final visible = visibleTabs(order: order, hidden: hidden);
  if (visible.isEmpty) return order;
  if (oldIndex < 0 || oldIndex >= visible.length) return order;

  // ReorderableListView 的 newIndex 语义：指「插入到该位置之前」
  var target = newIndex;
  if (target > oldIndex) target -= 1;
  target = target.clamp(0, visible.length - 1);

  final moved = visible.removeAt(oldIndex);
  visible.insert(target, moved);

  final hiddenItems = order.where(hidden.contains).toList();
  return [...visible, ...hiddenItems];
}

/// 可见标签内左右移动一格，返回完整顺序。移不动时原样返回。
List<String> moveVisibleTab({
  required List<String> order,
  required Set<String> hidden,
  required String name,
  required int delta,
}) {
  final visible = visibleTabs(order: order, hidden: hidden);
  final from = visible.indexOf(name);
  if (from == -1) return order;
  final to = from + delta;
  if (to < 0 || to >= visible.length) return order;

  final moved = visible.removeAt(from);
  visible.insert(to, moved);

  final hiddenItems = order.where(hidden.contains).toList();
  return [...visible, ...hiddenItems];
}
