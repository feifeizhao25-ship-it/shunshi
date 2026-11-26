import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the personalization switch names the factors the home actually uses', () {
    final src = File('lib/presentation/pages/settings/settings_page_v2.dart').readAsStringSync();
    expect(src.contains('目标、时段、体质和地区'), isTrue);
    expect(src.contains('只留当天的节气和假期提示'), isTrue);
    expect(src.contains('目标和地区来排'), isFalse);
  });
}
