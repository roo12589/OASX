import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/controller/ctrl_nav.dart';

/// 首页入口的导航行为测试。
///
/// 背景：重做 UI 后首页只剩 README，更新器 / 工具页变成「有页面没入口」。
/// 这组测试锁定从任意脚本页回到首页三个子页的导航行为，
/// 不依赖网络（直接构造 NavCtrl，不注册、不调 onInit）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NavCtrl nav;

  setUpAll(() async {
    // NavCtrl 构造时就会 new GetStorage()；单测环境没有 path_provider
    // 平台通道，这里把它 mock 到临时目录，避免 MissingPluginException。
    final tempDir = Directory.systemTemp.createTempSync('oasx_nav_test');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'getApplicationDocumentsDirectory' ||
          call.method == 'getApplicationSupportDirectory') {
        return tempDir.path;
      }
      return tempDir.path;
    });
    await GetStorage.init();
  });

  setUp(() {
    GetStorage().erase();
    nav = NavCtrl();
    // 默认停在首页「主页」，与「切到首页时的默认子页」保持一致
    nav.selectedScript.value = 'Home';
    nav.selectedMenu.value = 'Home';
  });

  tearDownAll(() async {
    await GetStorage().erase();
  });

  tearDown(Get.reset);

  group('首页二级菜单', () {
    test('首页菜单始终包含主页 / 更新器 / 工具', () {
      expect(nav.currentTaskMenus, containsAll(['Home', 'Updater', 'Tool']));
    });

    test('切换到首页时默认停在「主页」，不是「总览」', () async {
      nav.selectedScript.value = 'oas1';
      nav.selectedMenu.value = 'Overview';
      await nav.selectScript('Home');
      expect(nav.selectedMenu.value, 'Home');
    });

    test('switchContent 能切到更新器与工具', () {
      nav.switchContent('Updater');
      expect(nav.selectedMenu.value, 'Updater');
      nav.switchContent('Tool');
      expect(nav.selectedMenu.value, 'Tool');
      nav.switchContent('Home');
      expect(nav.selectedMenu.value, 'Home');
    });

    test('switchContent 拒绝不存在的菜单', () {
      nav.switchContent('NotAMenu');
      expect(nav.selectedMenu.value, 'Home');
    });
  });

  group('openHomePage', () {
    test('从脚本页跳到首页的更新器', () async {
      nav.selectedScript.value = 'oas1';
      nav.selectedMenu.value = 'Overview';

      await nav.openHomePage('Updater');

      expect(nav.selectedScript.value, 'Home');
      expect(nav.selectedMenu.value, 'Updater');
    });

    test('已经在首页时只切子页，不重建脚本状态', () async {
      await nav.openHomePage('Tool');
      expect(nav.selectedScript.value, 'Home');
      expect(nav.selectedMenu.value, 'Tool');
    });

    test('非首页固定页会被忽略（不会把界面切到无效页）', () async {
      await nav.openHomePage('Overview');
      expect(nav.selectedScript.value, 'Home');
      expect(nav.selectedMenu.value, 'Home');
    });
  });
}
