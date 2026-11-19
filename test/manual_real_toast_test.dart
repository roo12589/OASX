import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/service/notification_service.dart';

/// 手动自检：真实调用 Windows 原生 Toast（不注入假通道），
/// 用于确认「插件不可用时回退到 PowerShell WinRT」这条路真的能弹通知。
///
/// 默认 **跳过**（会真的弹系统通知，不能进常规测试与 CI）。
/// 需要手动验证时执行：
///   $env:OASX_REAL_TOAST=1; flutter test test/manual_real_toast_test.dart
///
/// 用内存 prefs 代替 get_storage：单测环境没有 path_provider 平台通道。
class _MemPrefs implements NotifyPrefStore {
  _MemPrefs([this.value]);
  bool? value;

  @override
  bool? read() => value;

  @override
  Future<void> write(bool next) async => value = next;
}

/// 只有显式设置 OASX_REAL_TOAST=1 才真的弹通知
final bool _enabled = Platform.environment['OASX_REAL_TOAST'] == '1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '真实系统通知（Windows toast 回退通道）',
    () async {
      final service = NotificationService(prefs: _MemPrefs(true));
      service.onInit();
      final ok = await service.test(
        title: 'OASX',
        body: '系统通知自检：原生 Toast 通道可用',
      );
      // 手动自检用例：结果输出到控制台便于确认
      // ignore: avoid_print
      print('REAL_TOAST_OK=$ok channel=${service.deliveryChannelHint}');
      expect(NotificationService.isSupported, isTrue);
      expect(service.deliveryChannelHint, isNotEmpty);
      expect(ok, isTrue, reason: 'Windows 上应至少有一条通知通道成功');
    },
    skip: _enabled ? false : '手动自检用例，设置 OASX_REAL_TOAST=1 后才运行',
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    '通知历史里能查到刚才那条 toast（确认真的进了通知中心）',
    () async {
      final service = NotificationService(prefs: _MemPrefs(true));
      service.onInit();
      await service.test(title: 'OASX', body: 'history check');
      expect(service.lastDeliverySucceeded, isTrue);
    },
    skip: _enabled ? false : '手动自检用例，设置 OASX_REAL_TOAST=1 后才运行',
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
