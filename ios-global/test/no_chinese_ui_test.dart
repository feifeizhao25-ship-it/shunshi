// 复测 B02 回归：国际版（SEASONS）界面里不能出现中文字符串。
//
// 复测在国际版「节气」页看到 “Next: 立冬”、“霜降”与英文名并列，「我的」页看到 “顺时小友”“免费用户”“ShunShi AI”。
// 其中有些是 \u 转义写的中文（`'\u987a\u65f6\u5c0f\u53cb'`），按字符搜是搜不到的，所以这里两种写法都扫。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/solar_term/solar_term_en.dart';

void main() {
  final cjkChar = RegExp(r'[\u3400-\u9fff\uf900-\ufaff]');
  final cjkEscape = RegExp(r'\\u(3[4-9a-fA-F]|[4-9][0-9a-fA-F]|[fF][9a-aA-A])[0-9a-fA-F]{2}');

  /// 允许出现中文的地方（都不是展示给用户的文案）：
  /// - 聊天页里的安全词表：用来识别用户输入里的中文风险词；
  /// - 语言选择列表里的语言自称。
  bool allowed(String path, String line) =>
      path.endsWith('pages/chat/chat_page.dart') ||
      path.endsWith('pages/library/wellness_library_parse.dart') || // 后端分类键，不展示
      line.contains("'日本語'");

  test('presentation 下没有中文字面量（含 \\u 转义）', () {
    final hits = <String>[];
    for (final f in Directory('lib/presentation').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      var n = 0;
      for (final line in f.readAsLinesSync()) {
        n++;
        if (line.trimLeft().startsWith('//')) continue;
        final code = line.replaceFirst(RegExp(r'\s//.*$'), '');
        if ((cjkChar.hasMatch(code) || cjkEscape.hasMatch(code)) && !allowed(f.path, line)) {
          hits.add('${f.path}:$n: ${line.trim()}');
        }
      }
    }
    expect(hits, isEmpty, reason: '国际版界面只能是英文');
  });

  test('品牌与默认文案是 SEASONS，不是 ShunShi / 顺时', () {
    final hits = <String>[];
    for (final f in Directory('lib/presentation').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final line in f.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        if (RegExp(r"""Text\(\s*['"][^'"]*ShunShi\b""").hasMatch(line)) hits.add('${f.path}: ${line.trim()}');
      }
    }
    expect(hits, isEmpty);
  });

  group('solarTermEnglish', () {
    test('API 没带 X-Region 时 name 是中文：用英文名，绝不显示中文', () {
      expect(solarTermEnglish({'name': '立冬', 'name_en': 'Beginning of Winter'}), 'Beginning of Winter');
      expect(solarTermEnglish({'name': '霜降'}), 'Frost Descent'); // 没有 name_en 时查本地英文表
      expect(solarTermEnglish({'name': '立冬', 'name_en': '立冬'}), 'Start of Winter');
    });
    test('已经是英文就原样用；认不出来的中文返回空，不显示', () {
      expect(solarTermEnglish({'name': 'Frost Descent'}), 'Frost Descent');
      expect(solarTermEnglish({'name': '未知节气'}), '');
      expect(solarTermEnglish(null), '');
    });
    test('节气页的「Next:」和标题走英文名', () {
      final src = File('lib/presentation/pages/solar/solar_term_page_v2.dart').readAsStringSync();
      expect(src.contains("Next: \${_next['name']}"), isFalse);
      expect(src.contains("Text(_term['name']?.toString()"), isFalse);
      expect(src.contains('solarTermEnglish(_next)'), isTrue);
    });
  });
}
