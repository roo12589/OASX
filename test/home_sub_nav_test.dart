import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/views/home/home_sub_nav.dart';

/// 首页子页切换条的 widget 测试。
///
/// 这是本轮修复的「入口」本体：点「更新器 / 工具」必须真的把
/// [NavCtrl.selectedMenu] 切过去。
///
/// 注意用的是 [_TestNavCtrl]：真实 [NavCtrl.onInit] 会请求 OAS 后端，
/// 单测里必须绕开，否则会连真实服务、变慢且不稳定。
class _TestNavCtrl extends NavCtrl {
  // 不调用 super.onInit()：真实实现会请求 OAS 后端。
  @override
  // ignore: must_call_super
  Future<void> onInit() async {
    // 不请求网络、不读服务端菜单
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir =
        Directory.systemTemp.createTempSync('oasx_home_sub_nav_test');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return tempDir.path;
    });
    await GetStorage.init();
  });

  late NavCtrl nav;

  setUp(() {
    applyPalette(dark: false);
    Get.reset();
    GetStorage().erase();
    nav = _TestNavCtrl();
    nav.selectedScript.value = 'Home';
    nav.selectedMenu.value = 'Home';
    Get.put<NavCtrl>(nav, permanent: true);
  });

  tearDown(Get.reset);

  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('渲染主页 / 更新器 / 工具三个入口', (tester) async {
    await tester.pumpWidget(wrap(const HomeSubNav()));
    await tester.pumpAndSettle();

    expect(find.text(I18n.home.tr), findsOneWidget);
    expect(find.text(I18n.updater.tr), findsOneWidget);
    expect(find.text(I18n.tool.tr), findsOneWidget);
  });

  testWidgets('点「更新器」切到 Updater 子页', (tester) async {
    await tester.pumpWidget(wrap(const HomeSubNav()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(I18n.updater.tr));
    await tester.pumpAndSettle();

    expect(nav.selectedMenu.value, 'Updater');
  });

  testWidgets('点「工具」切到 Tool 子页', (tester) async {
    await tester.pumpWidget(wrap(const HomeSubNav()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(I18n.tool.tr));
    await tester.pumpAndSettle();

    expect(nav.selectedMenu.value, 'Tool');
  });

  testWidgets('再点回「主页」切回 Home', (tester) async {
    nav.selectedMenu.value = 'Tool';
    await tester.pumpWidget(wrap(const HomeSubNav()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(I18n.home.tr));
    await tester.pumpAndSettle();

    expect(nav.selectedMenu.value, 'Home');
  });
}
