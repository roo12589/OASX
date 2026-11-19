import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/controller/args/args_controller.dart';
import 'package:oasx/controller/home_menu.dart';
import 'package:oasx/controller/nav_tab_order.dart';
import 'package:oasx/controller/overview/overview_controller.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';

/// 顶层导航控制器：脚本标签页 + 二级菜单
class NavCtrl extends GetxController {
  final _storage = GetStorage();

  /// 服务端返回的配置列表（含 'Home'，代表全部配置）
  final navNameList = <String>['Home'].obs;

  /// 当前选中的脚本，'Home' 表示首页
  final selectedScript = 'Home'.obs;

  /// 当前选中的二级菜单，'Overview' 表示总览
  final selectedMenu = 'Overview'.obs;

  /// 配置标签的显示顺序（不含 'Home'）
  final tabOrder = <String>[].obs;

  /// 被用户隐藏的配置标签
  final hiddenTabs = <String>{}.obs;

  /// 首页菜单
  var homeMenuJson = Map<String, List<String>>.from(kDefaultHomeMenu).obs;

  /// 脚本菜单
  var scriptMenuJson = <String, List<String>>{}.obs;

  bool get isHomeScript => selectedScript.value == 'Home';

  bool get isOverview => selectedMenu.value == 'Overview';

  /// 除 'Home' 之外的全部配置名（服务端顺序）
  List<String> get configNames =>
      navNameList.where((e) => e != 'Home').toList(growable: false);

  /// 当前可见的配置标签（已按自定义顺序排列、去掉隐藏项）
  List<String> get visibleConfigTabs =>
      visibleTabs(order: tabOrder, hidden: hiddenTabs);

  /// 是否有被隐藏的标签（用于显示「显示全部」入口）
  bool get hasHiddenTabs => hiddenTabs.isNotEmpty;

  @override
  Future<void> onInit() async {
    await ApiClient().putChineseTranslate();
    final additionalTranslate = await ApiClient().getAdditionalTranslate();
    if (additionalTranslate.isNotEmpty) {
      Get.find<LocaleService>().saveAdditionalTranslate(additionalTranslate);
    }

    navNameList.value = await ApiClient().getConfigList();
    homeMenuJson.value = await ApiClient().getHomeMenu();
    scriptMenuJson.value = await ApiClient().getScriptMenu();

    _loadTabPreferences();
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    useablemenus;
    super.onReady();
  }

  // ----------------------------- 标签顺序 / 显隐 -----------------------------

  void _loadTabPreferences() {
    final savedOrder =
        _storage.read<List>(StorageKey.tabOrder.name) ?? const [];
    final savedHidden =
        _storage.read<List>(StorageKey.hiddenTabs.name) ?? const [];

    tabOrder.value = resolveTabOrder(
      existing: configNames,
      saved: savedOrder.map((e) => '$e').toList(),
    );
    hiddenTabs.assignAll(savedHidden.map((e) => '$e').toSet());
    // 服务端删掉的配置不应继续占用「已隐藏」状态
    hiddenTabs.removeWhere((e) => !configNames.contains(e));
    _persistTabPreferences();
  }

  void _persistTabPreferences() {
    _storage.write(StorageKey.tabOrder.name, tabOrder.toList());
    _storage.write(StorageKey.hiddenTabs.name, hiddenTabs.toList());
  }

  /// 服务器配置列表变化后，重新对齐顺序（新增的追加到末尾，删除的移除）
  void syncTabOrder() {
    tabOrder.value = resolveTabOrder(
      existing: configNames,
      saved: tabOrder.toList(),
    );
    hiddenTabs.removeWhere((e) => !configNames.contains(e));
    _persistTabPreferences();
  }

  void hideTab(String name) {
    if (name == 'Home') return;
    hiddenTabs.add(name);
    _persistTabPreferences();
    // 隐藏的正好是当前选中项时，切到第一个可见标签
    if (selectedScript.value == name) {
      final visible = visibleConfigTabs;
      if (visible.isNotEmpty) {
        selectScript(visible.first);
      } else {
        selectScript('Home');
      }
    }
  }

  void showTab(String name) {
    if (!hiddenTabs.remove(name)) return;
    _persistTabPreferences();
  }

  void showAllTabs() {
    hiddenTabs.clear();
    _persistTabPreferences();
  }

  /// 拖拽重排（索引基于「可见标签」）
  void reorderTabs(int oldIndex, int newIndex) {
    tabOrder.value = reorderVisibleTabs(
      order: tabOrder.toList(),
      hidden: hiddenTabs,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    _persistTabPreferences();
  }

  /// 拖拽重排（索引基于**全部标签**，含隐藏项）
  ///
  /// 与 [reorderTabs] 的区别：排序面板列出全部配置，行索引直接对应
  /// [tabOrder]，隐藏项也参与拖拽，因此走 [reorderAllTabOrder]。
  void reorderAllTabs(int oldIndex, int newIndex) {
    final next = reorderAllTabOrder(
      order: tabOrder.toList(),
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (listEquals(next, tabOrder.toList())) return;
    tabOrder.value = next;
    _persistTabPreferences();
  }

  /// 左右移动一格
  void moveTab(String name, int delta) {
    tabOrder.value = moveVisibleTab(
      order: tabOrder.toList(),
      hidden: hiddenTabs,
      name: name,
      delta: delta,
    );
    _persistTabPreferences();
  }

  // ----------------------------- 脚本 / 菜单切换 -----------------------------

  /// 按名字切换脚本（标签栏、抽屉都用它，避免索引错位）
  Future<void> selectScript(String name) async {
    if (name == selectedScript.value) return;
    if (name != 'Home' && !navNameList.contains(name)) return;

    selectedScript.value = name;
    // 脚本默认落在总览；首页默认落在「主页」，否则二级菜单一个都不高亮
    selectedMenu.value = name == 'Home' ? 'Home' : 'Overview';

    if (name != 'Home') {
      ensureOverviewController(name);
      await _syncScriptState(name);
    }
  }

  /// 兼容旧调用：按 navNameList 的下标切换
  Future<void> switchScript(int idx) async {
    if (idx < 0 || idx >= navNameList.length) return;
    await selectScript(navNameList[idx]);
  }

  /// 切到某个脚本时主动拉一次状态，避免界面停留在旧数据
  Future<void> _syncScriptState(String name) async {
    try {
      final scriptService = Get.find<ScriptService>();
      await scriptService.connectScript(name);
      await scriptService.wsService.send(name, 'get_state');
      await scriptService.wsService.send(name, 'get_schedule');
    } catch (e) {
      if (kDebugMode) printInfo(info: 'sync script[$name] state failed: $e');
    }
  }

  void ensureOverviewController(String name) {
    if (Get.isRegistered<OverviewController>(tag: name)) return;
    Get.put<OverviewController>(
      OverviewController(name: name),
      tag: name,
      permanent: true,
    );
  }

  /// 当前脚本的二级菜单（任务名）
  ///
  /// 首页固定有「主页 / 更新器 / 工具」三个页面（见 [buildHomeMenus]），
  /// 即便服务端下发的 home_menu 少了一项，入口也不会再丢。
  List<String> get currentTaskMenus {
    if (isHomeScript) {
      return buildHomeMenus(homeMenuJson);
    }
    final result = <String>['Overview'];
    scriptMenuJson.forEach((key, value) {
      if (value.isEmpty) return;
      result.addAll(value);
    });
    return result;
  }

  List<String> get useablemenus => currentTaskMenus;

  /// 回到总览
  void backToOverview() => switchContent('Overview');

  /// 跳到首页的固定子页（主页 / 更新器 / 工具）
  ///
  /// 顶栏的「更新器 / 工具」入口走这里：先切到 Home 脚本，再切子页。
  Future<void> openHomePage(String menu) async {
    if (!kHomeMenuOrder.contains(menu)) return;
    if (selectedScript.value != 'Home') {
      await selectScript('Home');
    }
    switchContent(menu);
  }

  void switchContent(String menu) {
    if (!useablemenus.contains(menu)) {
      if (kDebugMode) printInfo(info: 'menu not in useablemenus: $menu');
      return;
    }
    selectedMenu.value = menu;

    // 首页三个固定页面与总览都没有参数页，直接返回
    if (['Home', 'Overview', 'Updater', 'Tool'].contains(menu)) return;
    if (isHomeScript) return;

    final argsController = Get.find<ArgsController>();
    argsController.loadGroups(config: selectedScript.value, task: menu);
  }

  // ----------------------------- 配置增删改 -----------------------------

  Future<void> addConfig(String newName, String templateName) async {
    navNameList.value = await ApiClient().configCopy(newName, templateName);
    Get.find<ScriptService>().addScriptModel(newName);
    syncTabOrder();
    // 新建的配置默认可见并切过去
    showTab(newName);
    await selectScript(newName);
  }

  Future<void> deleteConfig(String name) async {
    if (name == 'Home') return;
    if (!await ApiClient().deleteConfig(name)) return;

    if (Get.isRegistered<OverviewController>(tag: name)) {
      try {
        Get.delete<OverviewController>(tag: name, force: true);
      } catch (_) {
        // ignore
      }
    }

    scriptMenuJson.remove(name);
    Get.find<ScriptService>().deleteScriptModel(name);

    final wasSelected = selectedScript.value == name;
    navNameList.removeWhere((e) => e == name);
    syncTabOrder();

    if (wasSelected) {
      final visible = visibleConfigTabs;
      await selectScript(visible.isNotEmpty ? visible.first : 'Home');
    }
  }

  Future<void> renameConfig(String oldName, String newName) async {
    final int idx = navNameList.indexOf(oldName);
    if (idx == -1) return;
    if (!await ApiClient().renameConfig(oldName, newName)) return;

    navNameList[idx] = newName;
    // 顺序与隐藏状态跟着改名
    tabOrder.value = tabOrder.map((e) => e == oldName ? newName : e).toList();
    if (hiddenTabs.remove(oldName)) hiddenTabs.add(newName);
    _persistTabPreferences();

    try {
      Get.delete<OverviewController>(tag: oldName, force: true);
      Get.find<ScriptService>().deleteScriptModel(oldName);
    } catch (_) {}
    Get.find<ScriptService>().addScriptModel(newName);

    if (selectedScript.value == oldName) {
      selectedScript.value = newName;
      ensureOverviewController(newName);
      await _syncScriptState(newName);
    } else {
      ensureOverviewController(newName);
    }
  }
}
