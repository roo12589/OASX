import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/controller/args/args_controller.dart';
import 'package:oasx/controller/overview/overview_controller.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';

/// 顶层导航控制器：脚本标签页 + 二级菜单
class NavCtrl extends GetxController {
  /// 第一个固定为 Home，其余是 OAS 的配置文件（脚本实例）
  final navNameList = <String>['Home'].obs;

  final selectedIndex = 0.obs;

  /// 当前选中的脚本，'Home' 表示首页
  final selectedScript = 'Home'.obs;

  /// 当前选中的二级菜单，'Overview' 表示总览
  final selectedMenu = 'Overview'.obs;

  /// 首页菜单
  var homeMenuJson = <String, List<String>>{
    'Home': [],
    'Updater': [],
    'Tool': [],
  }.obs;

  /// 脚本菜单
  var scriptMenuJson = <String, List<String>>{}.obs;

  bool get isHomeScript => selectedScript.value == 'Home';

  bool get isOverview => selectedMenu.value == 'Overview';

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
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    useablemenus;
    super.onReady();
  }

  Future<void> switchScript(int idx) async {
    if (idx < 0 || idx >= navNameList.length) return;
    if (idx == selectedIndex.value &&
        navNameList[idx] == selectedScript.value) {
      return;
    }
    final name = navNameList[idx];
    selectedIndex.value = idx;
    // ignore: invalid_use_of_protected_member
    selectedScript.value = name;
    selectedMenu.value = 'Overview';

    if (idx != 0) {
      ensureOverviewController(name);
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
  List<String> get currentTaskMenus {
    if (isHomeScript) {
      final result = <String>[];
      homeMenuJson.forEach((key, value) {
        result.addAll(value.isNotEmpty ? value : [key]);
      });
      return result;
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

  void switchContent(String menu) {
    if (!useablemenus.contains(menu)) {
      if (kDebugMode) printInfo(info: 'menu not in useablemenus: $menu');
      return;
    }
    selectedMenu.value = menu;

    if (['Home', 'Overview', 'Updater', 'Tool'].contains(menu)) return;
    if (isHomeScript) return;

    final argsController = Get.find<ArgsController>();
    argsController.loadGroups(config: selectedScript.value, task: menu);
  }

  Future<void> addConfig(String newName, String templateName) async {
    navNameList.value = await ApiClient().configCopy(newName, templateName);
    Get.find<ScriptService>().addScriptModel(newName);
  }

  Future<void> deleteConfig(String name) async {
    final int idx = navNameList.indexOf(name);
    if (idx == -1) return;
    if (!await ApiClient().deleteConfig(name)) return;

    if (Get.isRegistered<OverviewController>(tag: name)) {
      try {
        Get.delete<OverviewController>(tag: name, force: true);
      } catch (_) {
        // ignore
      }
    }

    navNameList.removeAt(idx);
    Get.find<ScriptService>().deleteScriptModel(name);

    if (idx < selectedIndex.value) {
      selectedIndex.value -= 1;
    } else if (idx == selectedIndex.value) {
      if (idx < navNameList.length) {
        switchScript(idx);
      } else {
        switchScript(idx - 1);
      }
    }
  }

  Future<void> renameConfig(String oldName, String newName) async {
    final int idx = navNameList.indexOf(oldName);
    if (idx == -1) return;
    if (!await ApiClient().renameConfig(oldName, newName)) return;

    navNameList[idx] = newName;
    try {
      Get.delete<OverviewController>(tag: oldName, force: true);
      Get.find<ScriptService>().deleteScriptModel(oldName);
    } catch (_) {}
    if (idx == selectedIndex.value) {
      switchScript(idx);
      return;
    }
    ensureOverviewController(newName);
    Get.find<ScriptService>().addScriptModel(newName);
  }
}
