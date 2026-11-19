import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:oasx/service/notification_service.dart';
import 'package:oasx/utils/logger.dart';

/// 全局异常上报入口。
///
/// 统一负责两件事：
/// 1. 写日志（logger 可能还没初始化，所以每次都要判空）；
/// 2. 在用户开启「系统通知」时调用原生能力弹一条系统通知。
///
/// 所有调用都必须「不影响主流程」：这里绝不向外抛异常，
/// 通知失败只会静默降级为 false。
abstract final class ErrorReporter {
  /// 上报一条异常。[source] 用来区分来源（网络 / 脚本 / 界面 ...）。
  static Future<void> report(
    Object error, {
    String? source,
    StackTrace? stackTrace,
    String? title,
    bool notify = true,
  }) async {
    final message = error.toString();
    final tag = source == null || source.isEmpty ? '' : '[$source] ';
    _log('$tag$message');
    if (stackTrace != null) _log(stackTrace.toString());
    if (!notify) return;
    final service = notificationService;
    if (service == null) return;
    await service.reportError(
      tag.isEmpty ? message : '$tag$message',
      title: (title == null || title.isEmpty) ? 'OASX' : title,
    );
  }

  /// 把 Flutter 框架未捕获的异常接到全局上报上。
  ///
  /// 返回旧的 [FlutterError.onError]，方便测试或需要时还原。
  static FlutterExceptionHandler? installFlutterErrorHandler() {
    final previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      unawaited(report(
        details.exception,
        source: 'ui',
        stackTrace: details.stack,
      ));
      previous?.call(details);
    };
    return previous;
  }

  /// 把 Zone 级别（异步）未捕获异常接到全局上报上。
  static void installPlatformErrorHandler() {
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(report(error, source: 'async', stackTrace: stack));
      // 返回 true 表示已处理，避免直接崩掉整个应用
      return true;
    };
  }

  static void _log(String text) {
    try {
      logger.e(text);
    } catch (_) {
      // logger 尚未初始化（早期启动阶段）时忽略
      debugPrint(text);
    }
  }
}
