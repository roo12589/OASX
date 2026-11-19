import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, visibleForTesting;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_notifier/local_notifier.dart';

import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/utils/logger.dart';

/// 系统通知开关的持久化抽象，方便单测注入假实现。
///
/// 生产环境用 [StorageNotifyPrefStore] 读写 get_storage；
/// 单测里不触碰真实磁盘与 path_provider 平台通道。
abstract class NotifyPrefStore {
  /// 读取开关，未写过时返回 null。
  bool? read();

  /// 写入开关。
  Future<void> write(bool value);
}

/// 基于 get_storage 的实现（[StorageKey.systemNotify]）。
class StorageNotifyPrefStore implements NotifyPrefStore {
  StorageNotifyPrefStore({GetStorage? storage}) : _storage = storage ?? GetStorage();

  final GetStorage _storage;

  @override
  bool? read() => _storage.read<bool>(StorageKey.systemNotify.name);

  @override
  Future<void> write(bool value) =>
      _storage.write(StorageKey.systemNotify.name, value);
}

/// 原生系统通知服务。
///
/// 设计目标：**任何情况下都不能拖垮主流程，也不能让工程无法构建**。
/// 因此通知投放是「两层 + 静默降级」：
///
/// 1. 首选 local_notifier 插件：
///    - Windows 走 WinToast（WinRT ToastNotificationManager + AUMID 快捷方式）；
///    - macOS 走 UNUserNotificationCenter；
///    - Linux 走 libnotify；
/// 2. 插件不可用（未注册 / 平台不支持 / 调用抛异常）时，退回到「零依赖自实现」：
///    - Windows：PowerShell + WinRT ToastNotificationManager，
///      AUMID 写入 HKCU\\Software\\Classes\\AppUserModelId\\<AUMID>；
///    - macOS：osascript display notification；
///    - Linux：notify-send。
///
/// 所有原生调用一律 try/catch，失败只 logger.w 并返回 false，绝不向外抛异常。
///
/// 对外签名（enabled / setEnabled / toggle / test / notify / reportError /
/// isSupported / notificationService）被 Tool 页与 ErrorReporter 依赖，不可随意改动。
class NotificationService extends GetxService {
  NotificationService({
    NotifyPrefStore? prefs,
    Future<bool> Function(String title, String? subtitle, String body)?
        desktopSender,
  })  : _prefs = prefs ?? StorageNotifyPrefStore(),
        _injectedSender = desktopSender;

  final NotifyPrefStore _prefs;

  /// 可注入的投放实现（单测替换掉真实原生调用）。
  final Future<bool> Function(String title, String? subtitle, String body)?
      _injectedSender;

  /// 系统通知总开关，默认关闭；持久化到 [StorageKey.systemNotify]。
  final enabled = false.obs;

  /// 通知里使用的应用名。
  static const String appDisplayName = 'OASX';

  /// Windows AppUserModelID。发 toast 前会注册到 HKCU（无需管理员权限）。
  static const String windowsAppUserModelId = 'OAS.Application.OASX';

  /// 当前平台是否支持原生系统通知。
  ///
  /// 桌面三平台为 true（本项目的目标平台）；web 没有原生能力；
  /// 移动端未接入对应插件，同样按不支持处理（UI 会显示「不支持」并禁用开关）。
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 节流：5 秒内最多 1 条。
  static const Duration minInterval = Duration(seconds: 5);

  /// 相同文本 60 秒内不重复。
  static const Duration duplicateWindow = Duration(seconds: 60);

  /// 节流/去重用的时钟，单测可以随意拨动。
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  DateTime? _lastReportAt;
  final Map<String, DateTime> _recentTexts = <String, DateTime>{};

  bool _aumidEnsured = false;
  bool _pluginReady = false;

  /// 上一次真实投放结果（true 表示至少有一层通道成功），排障用。
  bool get lastDeliverySucceeded => _lastDeliverySucceeded;
  bool _lastDeliverySucceeded = false;

  /// 当前运行时实际使用的通道说明（日志/排障用）。
  String get deliveryChannelHint {
    if (!isSupported) return 'unsupported';
    if (Platform.isWindows) return 'windows-toast';
    if (Platform.isMacOS) return 'macos-osascript';
    return 'linux-notify-send';
  }

  @override
  void onInit() {
    try {
      enabled.value = _prefs.read() ?? false;
    } catch (e) {
      _warn('读取系统通知开关失败: $e');
      enabled.value = false;
    }
    super.onInit();
  }

  /// 设置总开关：先更新内存，再落盘；返回时 [enabled] 已更新。
  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      await _prefs.write(value);
    } catch (e) {
      _warn('持久化系统通知开关失败: $e');
    }
  }

  /// 取反。
  void toggle() => unawaited(setEnabled(!enabled.value));

  /// 强制发一条测试通知：**无视开关**（但仍受平台限制），
  /// 用于 Tool 页验证原生能力是否真的可用。
  /// 成功返回 true，任何异常返回 false，绝不抛出。
  Future<bool> test({String? title, String? body}) async {
    return _deliver(
      title: (title == null || title.trim().isEmpty) ? appDisplayName : title,
      subtitle: null,
      body: body ?? '',
    );
  }

  /// 受开关与平台限制的通知：未开启或不支持时返回 false。
  Future<bool> notify({
    required String title,
    String? body,
    String? subtitle,
  }) async {
    if (!isSupported) return false;
    if (!enabled.value) return false;
    return _deliver(title: title, subtitle: subtitle, body: body ?? '');
  }

  /// 异常通知：受开关限制，内部节流（5 秒最多 1 条，相同文本 60 秒内不重复）。
  /// 绝不抛出，也绝不影响调用方主流程。
  Future<void> reportError(String message, {String title = 'OASX'}) async {
    try {
      if (!isSupported || !enabled.value) return;
      final text = message.trim();
      if (text.isEmpty) return;

      final stamp = now();
      final last = _lastReportAt;
      if (last != null && stamp.difference(last) < minInterval) return;

      final seenAt = _recentTexts[text];
      if (seenAt != null && stamp.difference(seenAt) < duplicateWindow) return;

      _lastReportAt = stamp;
      _recentTexts[text] = stamp;
      _pruneRecent(stamp);

      await _deliver(title: title, subtitle: null, body: text);
    } catch (e) {
      _warn('reportError 发送失败: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 内部实现
  // ---------------------------------------------------------------------------

  /// 清理过期去重记录，避免 map 无限增长。
  void _pruneRecent(DateTime stamp) {
    if (_recentTexts.length <= 32) return;
    _recentTexts.removeWhere((_, at) => stamp.difference(at) >= duplicateWindow);
  }

  /// 统一投放入口：先插件，再零依赖回退。返回值表示「至少一层通道成功」。
  Future<bool> _deliver({
    required String title,
    String? subtitle,
    required String body,
  }) async {
    if (!isSupported) {
      _lastDeliverySucceeded = false;
      return false;
    }

    final injected = _injectedSender;
    if (injected != null) {
      final ok = await _runGuarded(() => injected(title, subtitle, body));
      _lastDeliverySucceeded = ok;
      return ok;
    }

    var ok = await _sendByPlugin(title: title, subtitle: subtitle, body: body);
    if (!ok) {
      ok = await _sendByNativeFallback(
        title: title,
        subtitle: subtitle,
        body: body,
      );
    }
    _lastDeliverySucceeded = ok;
    return ok;
  }

  /// 包一层 try/catch，任何实现都不许把异常漏给调用方。
  Future<bool> _runGuarded(Future<bool> Function() action) async {
    try {
      return await action();
    } catch (e) {
      _warn('通知通道异常: $e');
      return false;
    }
  }

  /// 通道一：local_notifier 插件。
  Future<bool> _sendByPlugin({
    required String title,
    String? subtitle,
    required String body,
  }) {
    return _runGuarded(() async {
      // Windows 与 Linux 必须先 setup：插件内部把 _isInitialized 初值设为 false，
      // 且 notify() 在这两个平台上会直接抛「Not initialized」；macOS 不需要。
      // （Linux 的 setup 不走进原生通道，只置初始化标志，不会抛异常。）
      if ((Platform.isWindows || Platform.isLinux) && !_pluginReady) {
        if (Platform.isWindows) {
          // WinToast 的 setup 只设置进程内状态，不会写 HKCU；未打包应用必须先
          // 有 AppUserModelId 注册项，否则 show 会静默失败。
          await _ensureWindowsAppUserModelIdRegistered();
        }
        await localNotifier.setup(
          appName: appDisplayName,
          shortcutPolicy: ShortcutPolicy.ignore,
        );
      }
      _pluginReady = true;
      final notification = LocalNotification(
        title: title,
        subtitle: subtitle,
        body: body,
      );
      await notification.show();
      return true;
    });
  }

  /// 通道二：零依赖平台自实现。
  Future<bool> _sendByNativeFallback({
    required String title,
    String? subtitle,
    required String body,
  }) async {
    if (Platform.isWindows) {
      return _sendByWindowsToast(title: title, subtitle: subtitle, body: body);
    }
    if (Platform.isMacOS) {
      return _sendByMacOs(title: title, subtitle: subtitle, body: body);
    }
    if (Platform.isLinux) {
      return _sendByLinux(title: title, subtitle: subtitle, body: body);
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Windows：PowerShell + WinRT ToastNotificationManager
  // ---------------------------------------------------------------------------

  Future<bool> _sendByWindowsToast({
    required String title,
    String? subtitle,
    required String body,
  }) async {
    try {
      await _ensureWindowsAppUserModelIdRegistered();
      final xml = buildWindowsToastXml(
        title: title,
        subtitle: subtitle,
        body: body,
      );
      final code = await _runPowerShell(
        kWindowsToastScript,
        environment: <String, String>{
          'OASX_TOAST_XML': xml,
          'OASX_TOAST_AUMID': windowsAppUserModelId,
        },
      );
      if (code != 0) {
        _warn('Windows toast 投放失败，退出码 $code');
        return false;
      }
      return true;
    } catch (e) {
      _warn('Windows toast 异常: $e');
      return false;
    }
  }

  /// 只注册一次（进程内缓存），失败也不重试，避免每条通知都开 PowerShell。
  Future<void> _ensureWindowsAppUserModelIdRegistered() async {
    if (_aumidEnsured) return;
    _aumidEnsured = true;
    await _registerWindowsAppUserModelId();
  }

  /// 把 AUMID 注册到 HKCU，让未打包（unpackaged）应用也能发 toast。
  ///
  /// 需要注册两个 ID：
  /// - [windowsAppUserModelId]（'OAS.Application.OASX'）：零依赖回退通道使用；
  /// - [appDisplayName]（'OASX'）：local_notifier 插件把 appName 直接当 AUMID，
  ///   不注册的话插件会「返回成功但通知不出现」。
  Future<void> _registerWindowsAppUserModelId() async {
    for (final aumid in <String>[windowsAppUserModelId, appDisplayName]) {
      try {
        await _runPowerShell(
          kWindowsRegisterScript,
          environment: <String, String>{
            'OASX_TOAST_AUMID': aumid,
            'OASX_TOAST_APP': appDisplayName,
          },
        );
      } catch (e) {
        _warn('注册 Windows AUMID($aumid) 失败: $e');
      }
    }
  }

  /// 构造 ToastText02 的 XML（两行文本），做 XML 实体转义。
  @visibleForTesting
  static String buildWindowsToastXml({
    required String title,
    String? subtitle,
    required String body,
  }) {
    final heading = (subtitle == null || subtitle.trim().isEmpty)
        ? title
        : '$title — $subtitle';
    final firstLine = escapeXml(heading);
    final secondLine = escapeXml(body.isEmpty ? title : body);
    return '<toast><visual><binding template="ToastText02">'
        '<text id="1">$firstLine</text>'
        '<text id="2">$secondLine</text>'
        '</binding></visual></toast>';
  }

  /// XML 文本节点转义：& < > " ' 以及非法控制字符。
  @visibleForTesting
  static String escapeXml(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      switch (rune) {
        case 0x26:
          buffer.write('&amp;');
          break;
        case 0x3C:
          buffer.write('&lt;');
          break;
        case 0x3E:
          buffer.write('&gt;');
          break;
        case 0x22:
          buffer.write('&quot;');
          break;
        case 0x27:
          buffer.write('&apos;');
          break;
        case 0x0A:
        case 0x0D:
          buffer.write(' ');
          break;
        default:
          buffer.write(rune < 0x20 ? ' ' : String.fromCharCode(rune));
      }
    }
    return buffer.toString();
  }

  /// 用 -EncodedCommand 执行 PowerShell，规避引号/换行/中文编码问题。
  /// 依次尝试 powershell.exe（Windows PowerShell 5.1，WinRT 可用）与 pwsh。
  Future<int> _runPowerShell(
    String script, {
    Map<String, String>? environment,
  }) async {
    final encoded = base64.encode(utf16LeBytes(script));
    const candidates = <String>[
      r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe',
      'powershell.exe',
      'pwsh.exe',
    ];
    Object? lastError;
    for (final exe in candidates) {
      try {
        final result = await Process.run(
          exe,
          <String>[
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-EncodedCommand',
            encoded,
          ],
          environment: environment,
        ).timeout(const Duration(seconds: 12));
        if (result.exitCode == 0) return 0;
        lastError = 'exit ${result.exitCode}: ${result.stderr}';
      } catch (e) {
        lastError = e;
      }
    }
    _warn('PowerShell 执行失败: $lastError');
    return 1;
  }

  // ---------------------------------------------------------------------------
  // macOS / Linux
  // ---------------------------------------------------------------------------

  Future<bool> _sendByMacOs({
    required String title,
    String? subtitle,
    required String body,
  }) async {
    try {
      final heading = (subtitle == null || subtitle.trim().isEmpty)
          ? title
          : '$title — $subtitle';
      final script = 'display notification "${escapeAppleScript(body)}" '
          'with title "${escapeAppleScript(heading)}"';
      final result = await Process.run(
        'osascript',
        <String>['-e', script],
      ).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) {
        _warn('osascript 失败: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      _warn('macOS 通知异常: $e');
      return false;
    }
  }

  @visibleForTesting
  static String escapeAppleScript(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');
  }

  Future<bool> _sendByLinux({
    required String title,
    String? subtitle,
    required String body,
  }) async {
    try {
      final heading = (subtitle == null || subtitle.trim().isEmpty)
          ? title
          : '$title — $subtitle';
      final result = await Process.run(
        'notify-send',
        <String>['--app-name=$appDisplayName', heading, body],
      ).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) {
        _warn('notify-send 失败: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      _warn('Linux 通知异常: $e');
      return false;
    }
  }

  void _warn(String message) {
    try {
      logger.w(message);
    } catch (_) {
      // logger 尚未初始化（早期启动阶段）时退化为 debugPrint
      debugPrint(message);
    }
  }
}

/// UTF-16LE 字节序列，供 PowerShell -EncodedCommand 使用。
/// 顶层函数便于单测覆盖（中文/emoji 都要能正确编码）。
Uint8List utf16LeBytes(String text) {
  final units = text.codeUnits;
  final bytes = Uint8List(units.length * 2);
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    bytes[i * 2] = unit & 0xFF;
    bytes[i * 2 + 1] = (unit >> 8) & 0xFF;
  }
  return bytes;
}

/// Windows 端「注册 AUMID」脚本：把可读的 DisplayName/IconUri 写进 HKCU，
/// 未打包应用才有资格弹 toast。变量通过环境变量传入，避免任何转义问题。
const String kWindowsRegisterScript = r'''
$ErrorActionPreference = 'Stop'
$aumid = $env:OASX_TOAST_AUMID
$appName = $env:OASX_TOAST_APP
if ([string]::IsNullOrWhiteSpace($aumid)) { throw 'missing AUMID' }
$key = "HKCU:\Software\Classes\AppUserModelId\$aumid"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name 'DisplayName' -Value $appName -Force
$icon = Join-Path $env:SystemRoot 'System32\shell32.dll'
if (Test-Path $icon) { Set-ItemProperty -Path $key -Name 'IconUri' -Value $icon -Force }
''';

/// Windows 端「发 toast」脚本：WinRT ToastNotificationManager。
const String kWindowsToastScript = r'''
$ErrorActionPreference = 'Stop'
$aumid = $env:OASX_TOAST_AUMID
$xmlText = $env:OASX_TOAST_XML
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime] | Out-Null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($xmlText)
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($aumid).Show($toast)
''';

/// 全局便捷入口：未注册时返回 null，调用方不必再判 Get.isRegistered。
NotificationService? get notificationService =>
    Get.isRegistered<NotificationService>()
        ? Get.find<NotificationService>()
        : null;
