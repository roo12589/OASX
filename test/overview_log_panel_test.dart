import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/overview/overview_log_panel.dart';

/// 最小可用的日志控制器（复用真实 LogMixin 的缓冲/节流逻辑）
class _FakeLogController extends GetxController with LogMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String stamp(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}'
        '.${d.millisecond.toString().padLeft(3, '0')}';
  }

  Future<_FakeLogController> pumpPanel(
    WidgetTester tester, {
    required List<String> logs,
    int errorCount = 1,
  }) async {
    final controller = _FakeLogController();
    Get.put<_FakeLogController>(controller);
    for (final line in logs) {
      controller.addLog(line);
    }
    // LogMixin 每 50ms 把 _pendingLogs 刷进 logs
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: darkTheme,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(
            width: 900,
            height: 700,
            child: OverviewLogPanel(
              controller: controller,
              errorCount: errorCount,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    return controller;
  }

  /// 把所有 RichText / Text 的内容合并成一段，便于断言
  String allVisibleText(WidgetTester tester) {
    final parts = <String>[];
    for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
      parts.add(w.text.toPlainText());
    }
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      if (w.data != null) parts.add(w.data!);
    }
    return parts.join('\n');
  }

  testWidgets('日志面板渲染真实日志行（含时间/级别）', (tester) async {
    final t = stamp(DateTime(2026, 11, 9, 0, 33, 15, 123));

    await pumpPanel(tester, logs: [
      '$t INFO Click(1095, 587) @GATE1_SELECT_3',
      '$t WARNING something odd',
      '$t ERROR island not found',
      'plain log without timestamp',
    ]);

    final text = allVisibleText(tester);
    expect(text.contains(I18n.log), isTrue, reason: '找不到日志 Tab: $text');
    expect(text.contains(I18n.runtime_log), isTrue);
    expect(text.contains(I18n.task_stats), isTrue);
    expect(text.contains('INFO'), isTrue, reason: '缺少 INFO 行: $text');
    expect(text.contains('ERROR'), isTrue, reason: '缺少 ERROR 行: $text');
    expect(text.contains('WARNING'), isTrue, reason: '缺少 WARNING 行: $text');

    // 无时间戳的行由 SelectableText 渲染（内部是 EditableText），
    // 用 textContaining 一并覆盖 Text / EditableText。
    expect(find.textContaining('plain log without timestamp'), findsWidgets,
        reason: '无时间戳的行也要显示');

    Get.delete<_FakeLogController>(force: true);
  });

  testWidgets('错误日志 Tab 显示 badge 数字', (tester) async {
    final t = stamp(DateTime(2026, 11, 9, 1, 0, 0, 0));
    await pumpPanel(tester, logs: ['$t ERROR boom'], errorCount: 3);

    // badge 显示传入的 errorCount
    expect(find.text('3'), findsWidgets);
    expect(find.text(I18n.error_log), findsOneWidget);

    Get.delete<_FakeLogController>(force: true);
  });

  testWidgets('切换到任务统计 Tab 显示统计卡片', (tester) async {
    final t = stamp(DateTime(2026, 11, 9, 2, 0, 0, 0));
    await pumpPanel(tester, logs: [
      '$t INFO a',
      '$t ERROR b',
      '$t WARNING c',
    ]);

    await tester.tap(find.text(I18n.task_stats));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lines'), findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);

    Get.delete<_FakeLogController>(force: true);
  });

  testWidgets('空日志显示占位文案', (tester) async {
    // 注意：测试环境没有加载语言包，用 .tr 只会回退成 key 本身
    await pumpPanel(tester, logs: const [], errorCount: 0);
    expect(find.text(I18n.no_data), findsWidgets);
    Get.delete<_FakeLogController>(force: true);
  });
}
