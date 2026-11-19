import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 单条持久化日志。
class PersistedLog {
  const PersistedLog({
    required this.time,
    required this.text,
  });

  final DateTime time;
  final String text;

  /// 日志级别（从文本里解析，没有则为空）
  String get level {
    final m = RegExp(r'\b(INFO|WARNING|ERROR|CRITICAL|DEBUG)\b')
        .firstMatch(text);
    return m?.group(1) ?? '';
  }

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'm': text,
      };

  static PersistedLog? fromJson(Map<String, dynamic> json) {
    final t = DateTime.tryParse('${json['t']}');
    final m = json['m'];
    if (t == null || m is! String) return null;
    return PersistedLog(time: t, text: m);
  }
}

/// 按日期分文件存储日志。
///
/// 目录：`<appCache>/oasx_logs/<scriptName>/<yyyy-MM-dd>.jsonl`
/// 每行一条 JSON（JSONL），追加写入，避免整文件重写。
///
/// 设计取舍：
/// - 用缓存目录而不是 Documents：日志是易失数据，不占用户文档空间；
///   系统清理缓存时一并清掉也符合预期。
/// - 按脚本分目录：不同配置的日志不该混在一起。
/// - 单文件行数上限 [maxLinesPerFile]，超出后丢弃最老的（简单截断重写）。
class LogStore {
  LogStore({this.scriptName = 'default', this.maxLinesPerFile = 20000});

  final String scriptName;
  final int maxLinesPerFile;

  Directory? _root;

  /// 写入队列：串行化 append，避免并发写坏文件
  Future<void> _writeChain = Future.value();

  /// 内存里缓存「每个文件已写行数」，避免每次都读文件
  final Map<String, int> _lineCounts = {};

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final cache = await getApplicationCacheDirectory();
    final safeName = _sanitize(scriptName);
    final dir = Directory('${cache.path}/oasx_logs/$safeName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _root = dir;
    return dir;
  }

  String _sanitize(String name) {
    // 配置名可能含中文/空格，目录名只保留安全字符，其余转下划线
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'default';
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String dateKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  Future<File> _fileFor(DateTime t) async {
    final dir = await _dir();
    return File('${dir.path}/${dateKey(t)}.jsonl');
  }

  /// 追加一条日志（不阻塞调用方）
  void append(String text, {DateTime? at}) {
    final entry = PersistedLog(time: at ?? DateTime.now(), text: text);
    _writeChain = _writeChain.then((_) => _appendEntry(entry)).catchError((e) {
      // 持久化失败不能影响主流程
      return;
    });
  }

  Future<void> _appendEntry(PersistedLog entry) async {
    try {
      final file = await _fileFor(entry.time);
      final key = dateKey(entry.time);
      await file.writeAsString(
        '${jsonEncode(entry.toJson())}\n',
        mode: FileMode.append,
        flush: false,
      );
      final next = (_lineCounts[key] ?? 0) + 1;
      _lineCounts[key] = next;
      if (next > maxLinesPerFile) {
        await _trimOldest(file, maxLinesPerFile);
        _lineCounts[key] = maxLinesPerFile;
      }
    } catch (_) {
      // 忽略：日志落盘失败不应影响 UI
    }
  }

  /// 超出上限时，保留最新的 [keep] 行
  Future<void> _trimOldest(File file, int keep) async {
    try {
      final lines = await file.readAsLines();
      if (lines.length <= keep) return;
      final kept = lines.sublist(lines.length - keep);
      await file.writeAsString('${kept.join('\n')}\n', flush: true);
    } catch (_) {
      // 截断失败就留着，下次再试
    }
  }

  /// 列出所有有日志的日期（倒序，最新在前）
  Future<List<DateTime>> availableDates() async {
    try {
      final dir = await _dir();
      final result = <DateTime>[];
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.path.split(Platform.pathSeparator).last;
        if (!name.endsWith('.jsonl')) continue;
        final datePart = name.substring(0, name.length - '.jsonl'.length);
        final parsed = DateTime.tryParse(datePart);
        if (parsed != null) result.add(parsed);
      }
      result.sort((a, b) => b.compareTo(a));
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// 读取某一天的日志。
  ///
  /// [level] 非空时只返回该级别（INFO/WARNING/ERROR/...）
  /// [keyword] 非空时做包含匹配
  /// [limit] 最多返回多少条（取最新的），默认 2000
  Future<List<PersistedLog>> readDay(
    DateTime day, {
    String? level,
    String? keyword,
    int limit = 2000,
  }) async {
    try {
      final file = await _fileFor(day);
      if (!file.existsSync()) return const [];
      final lines = await file.readAsLines();
      final result = <PersistedLog>[];
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parsed = _decode(line);
        if (parsed == null) continue;
        if (level != null && level.isNotEmpty && parsed.level != level) {
          continue;
        }
        if (keyword != null &&
            keyword.isNotEmpty &&
            !parsed.text.toLowerCase().contains(keyword.toLowerCase())) {
          continue;
        }
        result.add(parsed);
      }
      if (result.length > limit) {
        return result.sublist(result.length - limit);
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  PersistedLog? _decode(String line) {
    try {
      final json = jsonDecode(line);
      if (json is Map<String, dynamic>) return PersistedLog.fromJson(json);
    } catch (_) {
      // 老版本或半行数据：当作纯文本，时间用 1970 占位不可取，
      // 直接跳过，避免污染列表。
    }
    return null;
  }

  /// 删除某天的日志文件
  Future<void> deleteDay(DateTime day) async {
    try {
      final file = await _fileFor(day);
      if (file.existsSync()) await file.delete();
      _lineCounts.remove(dateKey(day));
    } catch (_) {}
  }

  /// 清空该脚本的所有日志
  Future<void> clearAll() async {
    try {
      final dir = await _dir();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
      _root = null;
      _lineCounts.clear();
    } catch (_) {}
  }
}
