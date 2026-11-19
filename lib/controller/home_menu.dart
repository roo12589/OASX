/// 首页（Home）二级菜单的纯逻辑。
///
/// 背景：重做 UI 时把 `Home / Updater / Tool` 的入口弄丢了 —— 首页只剩
/// README 渲染，更新器和工具页虽然文件还在，但没有任何入口可以到达。
/// 这里把「首页应有哪些二级菜单」抽成纯函数，方便单测覆盖，
/// 也避免菜单项再次散落在各个 widget 里被改丢。
library;

/// 首页二级菜单里固定存在的三个页面。
///
/// 顺序即展示顺序：主页 / 更新器 / 工具。
const List<String> kHomeMenuOrder = <String>['Home', 'Updater', 'Tool'];

/// 兜底文案：服务端没返回 home_menu 时用它。
const Map<String, List<String>> kDefaultHomeMenu = <String, List<String>>{
  'Home': <String>[],
  'Updater': <String>[],
  'Tool': <String>[],
};

/// 计算首页二级菜单的展示列表。
///
/// 规则：
/// - 服务端返回的菜单（[homeMenu]）按「分组名 -> 子项」展开，子项为空时用分组名；
/// - 固定项 [kHomeMenuOrder] 永远排在最前面且不重复（即使服务端删掉了也要能进得去，
///   否则更新器 / 工具页会再次变成「有页面没入口」）；
/// - 其余服务端自定义项保持原有相对顺序追加在后面。
List<String> buildHomeMenus(Map<String, List<String>> homeMenu) {
  final result = <String>[];
  final seen = <String>{};

  void add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!seen.add(trimmed)) return;
    result.add(trimmed);
  }

  for (final name in kHomeMenuOrder) {
    add(name);
  }
  homeMenu.forEach((group, children) {
    if (children.isEmpty) {
      add(group);
      return;
    }
    for (final child in children) {
      add(child);
    }
  });
  return result;
}

/// 是否属于首页固定页面（主页 / 更新器 / 工具）。
bool isHomeMenuPage(String menu) => kHomeMenuOrder.contains(menu);
