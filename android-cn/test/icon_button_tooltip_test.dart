import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/profile/privacy_page.dart';
import 'package:shunshi/presentation/widgets/cn_back_button.dart';

/// axe 在 Flutter web 的数据与隐私页上报：返回 IconButton 没有可访问名称。
/// IconButton 的 tooltip 会成为这个名字。lib 里每处 IconButton 都必须带上。
void main() {
  test('android-cn/lib 的每个 IconButton 都有 tooltip', () {
    final missing = <String>[];
    var checked = 0;
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final src = file.readAsStringSync();
      for (final call in _iconButtonCalls(src)) {
        checked++;
        final tip = _tooltipArg(call.args);
        if (tip == null || _tooltipIsBlank(tip)) {
          missing.add('${file.path}:${call.line} ${call.header}');
        }
      }
    }
    expect(checked, greaterThan(20), reason: '扫描没有找到 IconButton，解析器可能失效');
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  testWidgets('CnBackButton 的可访问名称是返回', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CnBackButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
        ),
      ),
    );
    expect(find.byTooltip('返回'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton)).tooltip, '返回');
  });

  testWidgets('数据与隐私页的返回按钮有可访问名称', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
    expect(find.byTooltip('返回'), findsOneWidget);
  });
}

class _Call {
  const _Call(this.line, this.header, this.args);
  final int line;
  final String header;
  final String args;
}

final _suffix = RegExp(r'^\.(filledTonal|filled|outlined)');

List<_Call> _iconButtonCalls(String src) {
  final calls = <_Call>[];
  final n = src.length;
  var i = 0;
  while (i < n) {
    final skipped = _skipTrivia(src, i);
    if (skipped != i) {
      i = skipped;
      continue;
    }
    if (src.startsWith('IconButton', i) && _boundary(src, i, i + 'IconButton'.length)) {
      var k = i + 'IconButton'.length;
      var header = 'IconButton';
      final suffix = _suffix.matchAsPrefix(src, k);
      if (suffix != null) {
        header = 'IconButton${suffix.group(0)}';
        k = suffix.end;
      }
      var p = k;
      while (p < n && (src[p] == ' ' || src[p] == '\t' || src[p] == '\n' || src[p] == '\r')) {
        p++;
      }
      if (p < n && src[p] == '(') {
        final end = _matchParen(src, p);
        final line = '\n'.allMatches(src.substring(0, i)).length + 1;
        calls.add(_Call(line, header, src.substring(p + 1, end - 1)));
        i = end;
        continue;
      }
    }
    i++;
  }
  return calls;
}

String? _tooltipArg(String args) {
  final n = args.length;
  var i = 0;
  var depth = 0;
  while (i < n) {
    final skipped = _skipTrivia(args, i);
    if (skipped != i) {
      i = skipped;
      continue;
    }
    final c = args[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
      i++;
      continue;
    }
    if (c == ')' || c == ']' || c == '}') {
      if (depth > 0) depth--;
      i++;
      continue;
    }
    if (depth == 0 && _isIdentStart(c)) {
      final start = i;
      i++;
      while (i < n && _isIdentPart(args[i])) {
        i++;
      }
      final name = args.substring(start, i);
      final after = _skipTrivia(args, i);
      if (after < n && args[after] == ':') {
        if (name == 'tooltip') {
          final valueStart = _skipTrivia(args, after + 1);
          return args.substring(valueStart, _valueEnd(args, valueStart)).trim();
        }
        i = after + 1;
        continue;
      }
      continue;
    }
    i++;
  }
  return null;
}

bool _tooltipIsBlank(String value) {
  return value.isEmpty || value == 'null' || value == "''" || value == '""';
}

int _valueEnd(String src, int i) {
  final n = src.length;
  var depth = 0;
  while (i < n) {
    final skipped = _skipTrivia(src, i);
    if (skipped != i) {
      i = skipped;
      continue;
    }
    final c = src[i];
    if (depth == 0 && c == ',') return i;
    if (c == '(' || c == '[' || c == '{') depth++;
    if ((c == ')' || c == ']' || c == '}') && depth > 0) depth--;
    i++;
  }
  return i;
}

int _matchParen(String src, int open) {
  final n = src.length;
  var depth = 0;
  var i = open;
  while (i < n) {
    final skipped = _skipTrivia(src, i);
    if (skipped != i) {
      i = skipped;
      continue;
    }
    final c = src[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return i + 1;
    }
    i++;
  }
  return n;
}

int _skipTrivia(String src, int i) {
  final n = src.length;
  if (i >= n) return i;
  if (src.startsWith('//', i)) {
    final nl = src.indexOf('\n', i);
    return nl < 0 ? n : nl + 1;
  }
  if (src.startsWith('/*', i)) {
    final end = src.indexOf('*/', i + 2);
    return end < 0 ? n : end + 2;
  }
  final stringEnd = _stringEnd(src, i);
  if (stringEnd != null) return stringEnd;
  return i;
}

int? _stringEnd(String src, int i) {
  final n = src.length;
  if (i >= n) return null;
  var raw = false;
  var q = i;
  if (src[q] == 'r' && (q == 0 || !_isIdentPart(src[q - 1])) && q + 1 < n && (src[q + 1] == "'" || src[q + 1] == '"')) {
    raw = true;
    q++;
  }
  if (q >= n) return null;
  final String quote;
  if (src.startsWith("'''", q)) {
    quote = "'''";
  } else if (src.startsWith('"""', q)) {
    quote = '"""';
  } else if (src[q] == "'" || src[q] == '"') {
    quote = src[q];
  } else {
    return null;
  }
  var j = q + quote.length;
  while (j < n) {
    if (!raw && src[j] == r'\') {
      j += 2;
      continue;
    }
    if (src.startsWith(quote, j)) return j + quote.length;
    j++;
  }
  return n;
}

bool _boundary(String src, int start, int end) {
  if (start > 0 && _isIdentPart(src[start - 1])) return false;
  if (end < src.length && _isIdentPart(src[end])) return false;
  return true;
}

bool _isIdentStart(String c) {
  final u = c.codeUnitAt(0);
  return c == '_' || (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
}

bool _isIdentPart(String c) {
  final u = c.codeUnitAt(0);
  return _isIdentStart(c) || (u >= 48 && u <= 57);
}
