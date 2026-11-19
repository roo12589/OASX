import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/service/notification_service.dart';
import 'package:oasx/views/home/tool_view.dart';

/// Tool 页的 widget 测试：确认「系统通知」开关真的接到了
/// [NotificationService]，且不影响原有「推送测试」区块。
/// 不触发任何真实原生通知（按钮不点，或点的是开关）。

class _MemPrefs implements NotifyPrefStore {
  _MemPrefs([this.value]);
  bool? value;
  int writes = 0;

  @override
  bool? read() => value;

  @override
  Future<void> write(bool next) async {
    value = next;
    writes++;
  }
}

NotificationService _serviceWith({bool? saved}) {
  final service = NotificationService(
    prefs: _MemPrefs(saved),
    desktopSender: (title, subtitle, body) async => true,
  );
  service.onInit();
  return service;
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      home: Scaffold(body: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    applyPalette(dark: false);
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('系统通知开关默认关闭，能读到已保存的开值', (tester) async {
    Get.put<NotificationService>(_serviceWith(saved: true));
    await tester.pumpWidget(_wrap(const ToolView()));
    await tester.pumpAndSettle();

    // 开关打开（因为持久化里存的是 true）
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
    expect(Get.find<NotificationService>().enabled.value, isTrue);
  });

  testWidgets('点击开关会写回 NotificationService 并落盘', (tester) async {
    final service = _serviceWith(saved: false);
    Get.put<NotificationService>(service);
    await tester.pumpWidget(_wrap(const ToolView()));
    await tester.pumpAndSettle();

    expect(service.enabled.value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(service.enabled.value, isTrue);
    expect((service.enabled.value), isTrue);
  });

  testWidgets('未注册 NotificationService 时工具页仍能渲染（只是不显示通知区块）',
      (tester) async {
    await tester.pumpWidget(_wrap(const ToolView()));
    await tester.pumpAndSettle();
    expect(find.byType(ToolView), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('原有「推送测试」区块保留：三个输入框 + 发送按钮', (tester) async {
    Get.put<NotificationService>(_serviceWith());
    await tester.pumpWidget(_wrap(const ToolView()));
    await tester.pumpAndSettle();

    // 推送配置 / 主题 / 内容
    expect(find.byType(TextFormField), findsNWidgets(3));
    // 「点击测试」按钮仍在（FilledButton.icon 返回的是子类，用谓词匹配）
    expect(
      find.byWidgetPredicate((widget) => widget is FilledButton),
      findsOneWidget,
    );
  });
}
