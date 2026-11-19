import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/service/notification_service.dart';
import 'package:oasx/utils/error_reporter.dart';

/// 验证「异常 → 系统通知」这条链路：
/// [ErrorReporter.report] 在系统通知开关打开时，必须真的调用通知通道；
/// 关闭时或服务未注册时必须安静地什么都不做（不抛异常）。
///
/// 通知通道用注入的假实现，不触碰真实原生能力。
class _MemPrefs implements NotifyPrefStore {
  _MemPrefs([this.value]);
  bool? value;

  @override
  bool? read() => value;

  @override
  Future<void> write(bool next) async => value = next;
}

class _Recorder {
  final calls = <List<String?>>[];

  Future<bool> send(String title, String? subtitle, String body) async {
    calls.add(<String?>[title, subtitle, body]);
    return true;
  }
}

NotificationService _putService({
  required bool enabled,
  required _Recorder recorder,
}) {
  final service = NotificationService(
    prefs: _MemPrefs(enabled),
    desktopSender: recorder.send,
  );
  service.onInit();
  Get.put<NotificationService>(service);
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.reset());
  tearDown(() => Get.reset());

  group('ErrorReporter', () {
    test('开关打开时，异常会触发一条系统通知', () async {
      final recorder = _Recorder();
      _putService(enabled: true, recorder: recorder);

      await ErrorReporter.report(
        StateError('boom'),
        source: 'network',
      );

      expect(recorder.calls.length, 1);
      expect(recorder.calls.single[2], contains('boom'));
      expect(recorder.calls.single[2], contains('network'));
    });

    test('开关关闭时不发通知，但调用本身不抛异常', () async {
      final recorder = _Recorder();
      _putService(enabled: false, recorder: recorder);

      await expectLater(
        ErrorReporter.report(Exception('silent'), source: 'ui'),
        completes,
      );
      expect(recorder.calls, isEmpty);
    });

    test('notify:false 时即使开关打开也不发通知', () async {
      final recorder = _Recorder();
      _putService(enabled: true, recorder: recorder);

      await ErrorReporter.report(
        Exception('quiet'),
        source: 'ui',
        notify: false,
      );
      expect(recorder.calls, isEmpty);
    });

    test('通知服务未注册时安静跳过', () async {
      await expectLater(
        ErrorReporter.report(Exception('nobody listening'), source: 'ui'),
        completes,
      );
    });

    test('自定义标题会透传给通知', () async {
      final recorder = _Recorder();
      _putService(enabled: true, recorder: recorder);

      await ErrorReporter.report(
        Exception('x'),
        source: 'ws',
        title: 'OASX error',
      );
      expect(recorder.calls.single[0], 'OASX error');
    });
  });
}
