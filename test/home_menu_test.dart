import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/controller/home_menu.dart';

/// 首页二级菜单的纯逻辑测试。
///
/// 背景：重做 UI 时 `Updater` / `Tool` 的入口被弄丢，页面还在但没有入口。
/// 这组测试锁定「首页三件套必须始终可用」，防止回归。
void main() {
  group('buildHomeMenus', () {
    test('服务端返回空菜单时仍然给出主页/更新器/工具', () {
      final menus = buildHomeMenus({});
      expect(menus, ['Home', 'Updater', 'Tool']);
    });

    test('固定项排在最前且不重复', () {
      final menus = buildHomeMenus({
        'Tool': <String>[],
        'Home': <String>[],
        'Custom': <String>[],
      });
      expect(menus.take(3).toList(), ['Home', 'Updater', 'Tool']);
      expect(menus.where((e) => e == 'Tool').length, 1);
      expect(menus.contains('Custom'), isTrue);
    });

    test('服务端把某项放进分组子项也不会重复追加', () {
      // 分组有子项时只展开子项，分组名本身不作为菜单项（与旧逻辑一致）
      final menus = buildHomeMenus({
        'Group': ['Tool', 'Extra'],
      });
      expect(menus, ['Home', 'Updater', 'Tool', 'Extra']);
    });

    test('空字符串与空白项被忽略', () {
      final menus = buildHomeMenus({
        '  ': <String>[],
        'Group': ['', '  ', 'Real'],
      });
      expect(menus, ['Home', 'Updater', 'Tool', 'Real']);
    });

    test('顺序稳定：固定项之后按服务端插入顺序', () {
      final menus = buildHomeMenus({
        'A': <String>[],
        'B': <String>[],
      });
      expect(menus, ['Home', 'Updater', 'Tool', 'A', 'B']);
    });
  });

  group('isHomeMenuPage', () {
    test('只认三个固定页', () {
      expect(isHomeMenuPage('Home'), isTrue);
      expect(isHomeMenuPage('Updater'), isTrue);
      expect(isHomeMenuPage('Tool'), isTrue);
      expect(isHomeMenuPage('Overview'), isFalse);
    });
  });

  test('默认菜单兜底与固定顺序一致', () {
    expect(kDefaultHomeMenu.keys.toList(), kHomeMenuOrder);
  });
}
