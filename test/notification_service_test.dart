import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/service/notification_service.dart';

/// 纯逻辑单测：不触碰真实系统通知，也不依赖 get_storage 的磁盘/平台通道。
/// 真实的原生投放（local_notifier 插件、PowerShell WinRT）在 `flutter build
/// windows --debug` 之后由人工在 Tool 页「测试通知」验证。

/// 假存储：只保留内存里的一份值。
class _FakePrefStore implements NotifyPrefStore {
  _FakePrefStore([this.value]);

  bool? value;
  int writeCount = 0;

  @override
  bool? read() => value;

  @override
  Future<void> write(bool next) async {
    value = next;
    writeCount++;
  }
}

/// 假投放通道：记录收到的通知，可模拟成功/失败/抛异常。
class _FakeSender {
  _FakeSender({this.result = true, this.throwError = false});

  final bool result;
  final bool throwError;
  final List<List<String?>> calls = <List<String?>>[];

  Future<bool> send(String title, String? subtitle, String body) async {
    calls.add(<String?>[title, subtitle, body]);
    if (throwError) throw StateError('boom');
    return result;
  }
}

/// 构造一个不经过 Get.put 的服务实例（onInit 不会自动调用）。
NotificationService _buildService({
  NotifyPrefStore? prefs,
  _FakeSender? sender,
}) {
  return NotificationService(
    prefs: prefs ?? _FakePrefStore(),
    desktopSender: sender?.send,
  );
}

void main() {
  // GetxService.onInit 内部会用到 WidgetsBinding，先初始化测试绑定。
  TestWidgetsFlutterBinding.ensureInitialized();

  group('平台能力', () {
    test('桌面平台 isSupported 为 true（测试跑在 Windows 上）', () {
      expect(NotificationService.isSupported, isTrue);
      expect(NotificationService.windowsAppUserModelId, isNotEmpty);
      expect(NotificationService.appDisplayName, 'OASX');
    });
  });

  group('开关持久化', () {
    test('默认关闭（没有历史值）', () {
      final service = _buildService();
      service.onInit();
      expect(service.enabled.value, isFalse);
    });

    test('onInit 读取已保存的开关', () {
      final service = _buildService(prefs: _FakePrefStore(true));
      service.onInit();
      expect(service.enabled.value, isTrue);
    });

    test('setEnabled 同时更新内存与存储', () async {
      final prefs = _FakePrefStore();
      final service = _buildService(prefs: prefs);
      service.onInit();

      final future = service.setEnabled(true);
      expect(service.enabled.value, isTrue, reason: '内存应立即更新');
      await future;
      expect(prefs.value, isTrue, reason: '返回后存储也应已写入');
      expect(prefs.writeCount, 1);
    });

    test('toggle 取反并持久化', () async {
      final prefs = _FakePrefStore();
      final service = _buildService(prefs: prefs);
      service.onInit();

      service.toggle();
      await Future<void>.delayed(Duration.zero);
      expect(service.enabled.value, isTrue);
      expect(prefs.value, isTrue);

      service.toggle();
      await Future<void>.delayed(Duration.zero);
      expect(service.enabled.value, isFalse);
      expect(prefs.value, isFalse);
    });

    test('存储写入抛异常时 setEnabled 不抛出', () async {
      final service = _buildService(prefs: _ThrowingPrefStore());
      service.onInit();
      await expectLater(service.setEnabled(true), completes);
      expect(service.enabled.value, isTrue);
    });
  });

  group('notify', () {
    test('开关关闭时不发送，返回 false', () async {
      final sender = _FakeSender();
      final service = _buildService(sender: sender);
      service.onInit();

      final ok = await service.notify(title: 't', body: 'b');
      expect(ok, isFalse);
      expect(sender.calls, isEmpty);
    });

    test('开关打开时发送，返回 true', () async {
      final sender = _FakeSender();
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      service.onInit();

      final ok = await service.notify(title: 't', body: 'b', subtitle: 's');
      expect(ok, isTrue);
      expect(sender.calls.single, <String?>['t', 's', 'b']);
    });

    test('通道抛异常时返回 false，不向上抛', () async {
      final sender = _FakeSender(throwError: true);
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      service.onInit();

      expect(await service.notify(title: 't'), isFalse);
      expect(service.lastDeliverySucceeded, isFalse);
    });
  });

  group('test 强制发送', () {
    test('无视开关直接发送', () async {
      final sender = _FakeSender();
      final service = _buildService(sender: sender);
      service.onInit();
      expect(service.enabled.value, isFalse);

      final ok = await service.test(title: 'hi', body: 'there');
      expect(ok, isTrue);
      expect(sender.calls.single, <String?>['hi', null, 'there']);
    });

    test('默认标题为应用名，body 为空字符串', () async {
      final sender = _FakeSender();
      final service = _buildService(sender: sender);
      service.onInit();

      await service.test();
      expect(sender.calls.single[0], 'OASX');
      expect(sender.calls.single[2], '');
    });

    test('投放失败返回 false', () async {
      final sender = _FakeSender(result: false);
      final service = _buildService(sender: sender);
      service.onInit();
      expect(await service.test(), isFalse);
    });

    test('投放抛异常返回 false，绝不抛出', () async {
      final sender = _FakeSender(throwError: true);
      final service = _buildService(sender: sender);
      service.onInit();
      expect(await service.test(), isFalse);
    });
  });

  group('reportError 节流', () {
    test('开关关闭时不发送', () async {
      final sender = _FakeSender();
      final service = _buildService(sender: sender);
      service.onInit();

      await service.reportError('boom');
      expect(sender.calls, isEmpty);
    });

    test('5 秒内最多 1 条', () async {
      final sender = _FakeSender();
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      var clock = DateTime(2026, 11, 11, 10, 0, 0);
      service.now = () => clock;
      service.onInit();

      await service.reportError('第一条');
      clock = clock.add(const Duration(seconds: 3));
      await service.reportError('第二条');
      expect(sender.calls.length, 1, reason: '间隔不足 5 秒应被丢弃');

      clock = clock.add(const Duration(seconds: 3)); // 距第一条 6 秒
      await service.reportError('第三条');
      expect(sender.calls.length, 2);
    });

    test('相同文本 60 秒内不重复', () async {
      final sender = _FakeSender();
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      var clock = DateTime(2026, 11, 11, 10, 0, 0);
      service.now = () => clock;
      service.onInit();

      await service.reportError('重复文本');
      clock = clock.add(const Duration(seconds: 30));
      await service.reportError('重复文本');
      expect(sender.calls.length, 1, reason: '60 秒内相同文本应被丢弃');

      clock = clock.add(const Duration(seconds: 31)); // 距首次 61 秒
      await service.reportError('重复文本');
      expect(sender.calls.length, 2, reason: '超过 60 秒后允许重复');
    });

    test('不同文本但间隔足够则分别发送', () async {
      final sender = _FakeSender();
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      var clock = DateTime(2026, 11, 11, 10, 0, 0);
      service.now = () => clock;
      service.onInit();

      await service.reportError('A');
      clock = clock.add(const Duration(seconds: 6));
      await service.reportError('B');
      expect(sender.calls.length, 2);
      expect(sender.calls.map((c) => c[2]).toList(), <String>['A', 'B']);
    });

    test('空白文本直接忽略', () async {
      final sender = _FakeSender();
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      service.onInit();

      await service.reportError('   ');
      expect(sender.calls, isEmpty);
    });

    test('通道抛异常时 reportError 不抛出', () async {
      final sender = _FakeSender(throwError: true);
      final service = _buildService(prefs: _FakePrefStore(true), sender: sender);
      service.onInit();
      await expectLater(service.reportError('炸了'), completes);
    });
  });

  group('原生脚本构造（Windows）', () {
    test('toast XML 做实体转义', () {
      final xml = NotificationService.buildWindowsToastXml(
        title: 'A&B <x>',
        body: 'quote " apostrophe \'',
      );
      expect(xml.contains('A&amp;B &lt;x&gt;'), isTrue);
      expect(xml.contains('&quot;'), isTrue);
      expect(xml.contains('&apos;'), isTrue);
      expect(xml.contains('<binding template="ToastText02">'), isTrue);
    });

    test('换行会被压成空格（XML 单行文本）', () {
      final xml = NotificationService.buildWindowsToastXml(
        title: 'line1\nline2',
        body: 'body',
      );
      expect(xml.contains('line1 line2'), isTrue);
    });

    test('subtitle 拼到标题行', () {
      final xml = NotificationService.buildWindowsToastXml(
        title: 'T',
        subtitle: 'S',
        body: 'B',
      );
      expect(xml.contains('T — S'), isTrue);
      expect(xml.contains('>B<'), isTrue);
    });

    test('UTF-16LE 编码可被 PowerShell -EncodedCommand 识别', () {
      final bytes = utf16LeBytes('A\u4e2d');
      expect(bytes.length, 4);
      expect(bytes[0], 0x41);
      expect(bytes[1], 0x00);
      expect(bytes[2], 0x2D); // 中 = U+4E2D
      expect(bytes[3], 0x4E);
      // 与 Dart 自带编码结果保持一致
      final expected = Uint8List.fromList('A\u4e2d'.codeUnits
          .expand((u) => <int>[u & 0xFF, (u >> 8) & 0xFF])
          .toList());
      expect(base64.encode(bytes), base64.encode(expected));
    });

    test('PowerShell 脚本通过环境变量传参，不拼接用户文本', () {
      for (final script in <String>[
        kWindowsToastScript,
        kWindowsRegisterScript,
      ]) {
        expect(script.contains(r'$env:OASX_TOAST_AUMID'), isTrue);
        // 脚本本身不出现任何用户文本占位拼接（标题/正文只走 $env:OASX_TOAST_XML）
        expect(script.contains('<text id='), isFalse);
      }
      expect(kWindowsToastScript.contains('ToastNotificationManager'), isTrue);
      expect(kWindowsRegisterScript.contains('AppUserModelId'), isTrue);
    });
  });

  group('macOS 脚本转义', () {
    test('双引号与反斜杠被转义', () {
      expect(
        NotificationService.escapeAppleScript('say "hi"'),
        r'say \"hi\"',
      );
      expect(
        NotificationService.escapeAppleScript(r'C:\path'),
        r'C:\\path',
      );
    });

    test('换行被压成空格', () {
      expect(
        NotificationService.escapeAppleScript('a\nb'),
        'a b',
      );
    });
  });

  group('全局入口 notificationService', () {
    test('未注册时返回 null', () {
      Get.reset();
      expect(notificationService, isNull);
    });

    test('注册后返回同一实例', () {
      Get.reset();
      final service = _buildService(prefs: _FakePrefStore(true));
      service.onInit();
      Get.put<NotificationService>(service);
      expect(notificationService, same(service));
      expect(notificationService?.enabled.value, isTrue);
      Get.reset();
    });
  });
}

class _ThrowingPrefStore implements NotifyPrefStore {
  @override
  bool? read() => null;

  @override
  Future<void> write(bool value) async => throw StateError('disk full');
}
