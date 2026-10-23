import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// 0S3：顺时不是医疗/保健产品；《广告法》第十七条禁止非医疗内容涉及疾病治疗功能。
// 国内界面文案不得出现功效化用语。
const banned = ['排毒', '利尿', '消肿', '增强免疫'];

void main() {
  test('android-cn/lib 不含医疗功效化用语', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final w in banned) {
          if (lines[i].contains(w)) hits.add('${f.path}:${i + 1} $w');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
