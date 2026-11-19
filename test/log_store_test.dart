import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/component/log/log_store.dart';

/// 这些测试不触碰真实 app 缓存目录，只验证纯逻辑部分
/// （JSON 编解码、日期 key、级别解析）。
/// 涉及 path_provider 的 IO 部分需要真实平台通道，端到端验证在实机截图里做。
void main() {
  group('PersistedLog', () {
    test('JSON 往返', () {
      final original = PersistedLog(
        time: DateTime(2026, 11, 10, 12, 34, 56),
        text: '12:34:56.000 INFO hello',
      );
      final json = original.toJson();
      final restored = PersistedLog.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.time, original.time);
      expect(restored.text, original.text);
    });

    test('JSON 可以编码成单行（JSONL 要求）', () {
      final entry = PersistedLog(
        time: DateTime(2026, 11, 10, 1, 2, 3),
        text: 'a\nb',
      );
      final line = jsonEncode(entry.toJson());
      expect(line.contains('\n'), isFalse,
          reason: 'JSONL 每行必须是一条完整记录，换行会被转义');
      expect(line.contains(r'\n'), isTrue, reason: '换行应被转义成 \\n');
    });

    test('level 从文本里解析', () {
      expect(
        PersistedLog(time: DateTime.now(), text: '12:00:00 INFO x').level,
        'INFO',
      );
      expect(
        PersistedLog(time: DateTime.now(), text: '12:00:00 WARNING x').level,
        'WARNING',
      );
      expect(
        PersistedLog(time: DateTime.now(), text: '12:00:00 ERROR x').level,
        'ERROR',
      );
      expect(
        PersistedLog(time: DateTime.now(), text: '12:00:00 CRITICAL x').level,
        'CRITICAL',
      );
    });

    test('没有级别的普通行', () {
      expect(
        PersistedLog(time: DateTime.now(), text: 'just a line').level,
        '',
      );
    });

    test('级别不会被单词内部的字母误匹配', () {
      // "INFORMATION" 里含 INFO，但 \b 边界在字母之间不成立
      expect(
        PersistedLog(time: DateTime.now(), text: 'INFORMATION_LOGGED').level,
        '',
      );
    });

    test('非法 JSON 返回 null 而不是抛异常', () {
      expect(PersistedLog.fromJson(<String, dynamic>{}), isNull);
      expect(
        PersistedLog.fromJson({'t': 'not-a-date', 'm': 'x'}),
        isNull,
      );
      expect(
        PersistedLog.fromJson({'t': DateTime.now().toIso8601String()}),
        isNull,
      );
    });
  });

  group('LogStore 纯逻辑', () {
    test('dateKey 补零正确', () {
      final store = LogStore(scriptName: 'test');
      expect(store.dateKey(DateTime(2026, 1, 2)), '2026-01-02');
      expect(store.dateKey(DateTime(2026, 11, 10)), '2026-11-10');
      expect(store.dateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('默认参数', () {
      final store = LogStore();
      expect(store.scriptName, 'default');
      expect(store.maxLinesPerFile, 20000);
    });

    test('可自定义脚本名与行数上限', () {
      final store = LogStore(scriptName: '临时大号', maxLinesPerFile: 100);
      expect(store.scriptName, '临时大号');
      expect(store.maxLinesPerFile, 100);
    });
  });

  group('目录名净化（通过可观察行为间接验证）', () {
    test('非法字符被替换，避免建目录失败', () {
      // _sanitize 是私有的，这里通过脚本名含非法字符时不抛异常来间接验证
      for (final name in [
        'a/b',
        r'a\b',
        'a:b',
        'a*b',
        'a?b',
        'a"b',
        'a<b',
        'a>b',
        'a|b',
      ]) {
        expect(() => LogStore(scriptName: name), returnsNormally);
      }
    });
  });

  group('文件路径推断（用临时目录验证 JSONL 往返）', () {
    test('写入的行能被逐行解析回来', () async {
      final dir = await Directory.systemTemp.createTemp('oasx_log_test_');
      try {
        final file = File('${dir.path}/2026-11-10.jsonl');
        final entries = [
          PersistedLog(time: DateTime(2026, 11, 10, 1, 1, 1), text: 'INFO a'),
          PersistedLog(
              time: DateTime(2026, 11, 10, 2, 2, 2), text: 'ERROR b'),
        ];
        await file.writeAsString(
          entries.map((e) => jsonEncode(e.toJson())).join('\n') + '\n',
        );

        final lines = await file.readAsLines();
        final parsed = lines
            .where((l) => l.isNotEmpty)
            .map((l) => PersistedLog.fromJson(
                jsonDecode(l) as Map<String, dynamic>))
            .whereType<PersistedLog>()
            .toList();

        expect(parsed.length, 2);
        expect(parsed[0].level, 'INFO');
        expect(parsed[1].level, 'ERROR');
        expect(parsed[1].text, 'ERROR b');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('坏行（半截写入）被跳过，不影响其它行', () async {
      final dir = await Directory.systemTemp.createTemp('oasx_log_bad_');
      try {
        final file = File('${dir.path}/2026-11-10.jsonl');
        final good = jsonEncode(
          PersistedLog(time: DateTime(2026, 11, 10), text: 'INFO ok').toJson(),
        );
        // 中间夹一行被截断的 JSON（模拟写入中断）
        await file.writeAsString('$good\n{"t":"2026-11-10T00:00:00","m":\n$good\n');

        final parsed = <PersistedLog>[];
        for (final line in await file.readAsLines()) {
          if (line.isEmpty) continue;
          try {
            final json = jsonDecode(line);
            if (json is Map<String, dynamic>) {
              final e = PersistedLog.fromJson(json);
              if (e != null) parsed.add(e);
            }
          } catch (_) {
            // 坏行跳过
          }
        }
        expect(parsed.length, 2, reason: '两行好的应保留，坏行跳过');
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
