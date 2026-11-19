import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/theme.dart' show darkTheme;
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/service/notification_service.dart';
import 'package:oasx/views/home/tool_view.dart';

/// 视觉快照：把工具页按 1000x900 渲染成 PNG，用于人工核对
/// 「系统通知」分区与原有「推送测试」分区的排版、暗色主题是否正常。
///
/// 生成命令：`flutter test test/tool_view_golden_test.dart --update-goldens`
///
/// 注意：flutter_test 默认用 Ahem 字体（所有字都渲染成方块），
/// 快照里必须显式加载系统字体，否则截图看不出任何文案。

class _MemPrefs implements NotifyPrefStore {
  _MemPrefs([this.value]);
  bool? value;

  @override
  bool? read() => value;

  @override
  Future<void> write(bool next) async => value = next;
}

/// 加载 Windows 自带中文字体，让快照里的文本可读。
Future<void> _loadRealFonts() async {
  const candidates = <String, List<String>>{
    'Microsoft YaHei': <String>[
      r'C:\Windows\Fonts\msyh.ttc',
    ],
    'Microsoft YaHei UI': <String>[
      r'C:\Windows\Fonts\msyh.ttc',
    ],
    'Segoe UI': <String>[
      r'C:\Windows\Fonts\segoeui.ttf',
    ],
  };
  for (final entry in candidates.entries) {
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        final bytes = await file.readAsBytes();
        final loader = FontLoader(entry.key)
          ..addFont(Future<ByteData>.value(
            ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length),
          ));
        await loader.load();
        break;
      } catch (_) {
        // 字体加载失败就用默认字体，不影响断言
      }
    }
  }
}

/// 在真实暗色主题上补齐字体族（含按钮类，按钮样式自带 textStyle，
/// 不会从 textTheme 继承字体），只为让快照可读。
ThemeData _snapshotTheme() {
  const font = 'Microsoft YaHei UI';
  const fallback = <String>['Microsoft YaHei', 'Segoe UI'];
  final base = darkTheme;
  TextStyle fix(TextStyle? style, double size) => (style ?? TextStyle(fontSize: size))
      .copyWith(
        fontFamily: font,
        fontFamilyFallback: fallback,
      );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: font,
      fontFamilyFallback: fallback,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(fix(
          base.outlinedButtonTheme.style?.textStyle?.resolve({}),
          11.5,
        )),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(fix(
          base.textButtonTheme.style?.textStyle?.resolve({}),
          12,
        )),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(fix(
          base.elevatedButtonTheme.style?.textStyle?.resolve({}),
          12.5,
        )),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRealFonts);

  setUp(() {
    applyPalette(dark: true);
    Get.reset();
  });

  tearDown(Get.reset);

  // 快照依赖 Windows 自带的中文字体（msyh.ttc / segoeui.ttf）。
  // 其它平台（CI 里的 Linux）没有这些字体，字形会不一致，
  // 直接跳过，避免在无关环境里报「快照不匹配」。
  final hasWindowsFonts = Platform.isWindows &&
      File(r'C:\Windows\Fonts\msyh.ttc').existsSync();

  testWidgets(
      '工具页（暗色）视觉快照', skip: !hasWindowsFonts, (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = NotificationService(
      prefs: _MemPrefs(true),
      desktopSender: (title, subtitle, body) async => true,
    );
    service.onInit();
    Get.put<NotificationService>(service);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // 用真实的暗色主题（含输入框、按钮的真实样式），
        // 而不是裸 ThemeData，否则快照和界面实际观感对不上。
        // 字体显式指定为已加载的系统中文：flutter_test 默认 Ahem 字体，
        // 不指定的话快照里全是方块，看不出文案只能看出布局。
        theme: _snapshotTheme(),
        home: Scaffold(
          backgroundColor: AppColors.bg,
          body: const ToolView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 冒烟断言：两个分区标题都在，开关已按持久化值打开
    expect(find.text(I18n.system_notify.tr), findsOneWidget);
    expect(find.text(I18n.notify_test.tr), findsOneWidget);
    expect(find.text(I18n.system_notify_test.tr), findsOneWidget);
    expect(find.text(I18n.notify_test_send.tr), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tool_view_dark.png'),
    );
  });
}
