import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:get_storage/get_storage.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:get/get.dart';

import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/ui_prefs_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/service/window_service.dart';
import 'package:oasx/utils/logger.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/routes.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/config/theme.dart' show lightTheme, darkTheme;

/// 全局开关：是否启用设备预览（桌面端模拟手机尺寸）。
/// 桌面调 UI 时建议关掉，它会给窗口套一层模拟设备外框。
const bool kDevicePreviewEnabled = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initService();

  if (kDevicePreviewEnabled && !kReleaseMode && PlatformUtils.isWindows) {
    runApp(
      DevicePreview(
        enabled: true,
        builder: (context) => const OASXApp(),
      ),
    );
    return;
  }
  runApp(const OASXApp());
}

class OASXApp extends StatelessWidget {
  const OASXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();
    final themeService = Get.find<ThemeService>();

    return ResponsiveApp(builder: (context) {
      return Obx(() {
        final themeMode = themeService.themeMode;
        // revision 变化时换 key，强制整棵树重建。
        // AppColors 是普通 getter（非响应式），只换 ThemeData 不够——
        // 已经 build 过的 widget 不会重新取色。
        final revision = themeService.revision;
        // 重建会新建 Navigator，因此要用当前路由作为 initialRoute，
        // 否则切主题会跳回 Home。
        final initialRoute =
            Get.currentRoute.isEmpty ? Routes.initial : Get.currentRoute;
        return GetMaterialApp(
          key: ValueKey<int>(revision),
          debugShowCheckedModeBanner: false,
          scrollBehavior: GlobalBehavior(),
          translations: localeService.messages,
          locale: localeService.currentLocale,
          fallbackLocale: localeService.fallbackLocale, //语言选择无效时，备用语言
          title: 'OASX',
          onInit: onInit,
          initialRoute: initialRoute,
          getPages: Routes.routes,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
        );
      });
    });
  }

  /// 但是我不能确定 Getx 框架这个时候是否成功初始化
  void onInit() {
    Get.put(SettingsController());
  }
}

class GlobalBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

Future<void> initService() async {
  await initLogger();
  await GetStorage.init();

  await Future.wait([
    Get.putAsync(() async => LocaleService()),
    Get.putAsync(() async => ThemeService()),
    Get.putAsync(() async => WindowService()),
    Get.putAsync(() async => UiPrefsService()),
  ]);

  Get.lazyPut(() => WebSocketService());
}
