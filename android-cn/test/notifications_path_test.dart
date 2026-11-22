import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('通知列表请求不带尾斜杠（带斜杠会被后端 307 到 http:// 绝对地址）', () {
    final src = File('lib/presentation/pages/notifications/notifications_page.dart').readAsStringSync();
    expect(src.contains("'/api/v1/notifications/'"), isFalse);
    expect(src.contains("'/api/v1/notifications'"), isTrue);
  });
}
