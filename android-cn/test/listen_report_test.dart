import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/audio/listen_report.dart';

void main() {
  test('a blank audio id is not reported', () {
    expect(reportsListenProgress(null), isFalse);
    expect(reportsListenProgress(''), isFalse);
    expect(reportsListenProgress('   '), isFalse);
    expect(reportsListenProgress('breathe-1'), isTrue);
  });
}
