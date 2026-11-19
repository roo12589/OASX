import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/views/layout/appbar.dart';

/// 标题栏回归测试。
///
/// 本轮在标题栏里恢复了「更新器 / 工具」入口，并把 Home 固定到标签栏最左侧，
/// 标题栏本来就挤（Logo + 标签 + 更多 + 主题 + 设置 + 三个窗口按钮）。
/// 这里锁定两件事：
/// 1. 窄窗口下标题栏不 overflow（不会被挤爆）；
/// 2. 更新器 / 工具入口与主题、设置按钮都真的在。
class _TestNavCtrl extends NavCtrl {
  // 不调用 super.onInit()：真实实现会请求 OAS 后端。
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}
}

/// ScriptService.onInit 会请求后端配置列表，单测里绕开。
class _TestScriptService extends ScriptService {
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('oasx_appbar_test');
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
    nav.tabOrder.assignAll(['oas1', 'oas2']);
    nav.navNameList.assignAll(['Home', 'oas1', 'oas2']);
    Get.put<NavCtrl>(nav, permanent: true);
    // 标题栏里的脚本标签带电源开关，需要 ScriptService；
    // 主题按钮需要 ThemeService。都注册成真实类型但不触发网络。
    Get.put<WebSocketService>(WebSocketService(), permanent: true);
    Get.put<ScriptService>(_TestScriptService(), permanent: true);
    Get.put<ThemeService>(ThemeService(), permanent: true);
  });

  tearDown(Get.reset);

  // 标题栏里的「更新器 / 工具 / 更多」只在 /main 路由下显示，
  // 所以这里必须用 GetMaterialApp 把当前路由置为 /main。
  Widget host(Size size) => GetMaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        initialRoute: '/main',
        getPages: [
          GetPage(
            name: '/main',
            page: () => Builder(
              builder: (context) => Scaffold(
                appBar: buildPlatformAppBar(context),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );

  for (final width in [1000.0, 1200.0, 1500.0]) {
    testWidgets('标题栏在 ${width.toInt()} 宽下不溢出', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(Size(width, 800)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('标题栏包含更新器 / 工具 / 主题 / 设置入口', (tester) async {
    tester.view.physicalSize = const Size(1500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const Size(1500, 800)));
    await tester.pumpAndSettle();

    expect(find.byTooltip(I18n.updater.tr), findsOneWidget);
    expect(find.byTooltip(I18n.tool.tr), findsOneWidget);
    expect(find.byTooltip(I18n.change_theme.tr), findsOneWidget);
    expect(find.byTooltip(I18n.setting.tr), findsOneWidget);
  });

  testWidgets('点标题栏「工具」按钮会切到工具页', (tester) async {
    tester.view.physicalSize = const Size(1500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const Size(1500, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(I18n.tool.tr));
    await tester.pumpAndSettle();

    expect(nav.selectedScript.value, 'Home');
    expect(nav.selectedMenu.value, 'Tool');
  });

  // 回归：DragToMoveArea 内部带 onDoubleTap，双击识别器会让子级单击
  // 必须等 ~300ms 双击超时才触发。按钮一旦被包进拖拽区，点一下就像没反应。
  testWidgets('标题栏按钮单击必须立即生效（不能等双击超时）', (tester) async {
    tester.view.physicalSize = const Size(1500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const Size(1500, 800)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(I18n.tool.tr));
    // 只推进一帧，不等待任何延迟
    await tester.pump();

    expect(nav.selectedMenu.value, 'Tool',
        reason: '按钮不应被 DragToMoveArea 的双击识别器拖慢');
  });
}
