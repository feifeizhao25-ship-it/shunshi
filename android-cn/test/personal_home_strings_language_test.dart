// Language isolation of the personalised home block: this edition's text is entirely Chinese.
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/personal_home_section.dart';
import 'package:shunshi/presentation/widgets/personal_home_strings_zh.dart';

List<String> _all(PersonalHomeStrings s) => [
      s.heading, s.why, s.turnOff, s.turnOn, s.offTitle, s.offBody, s.confirmTitle, s.confirmBody, s.cancel, s.confirm,
      s.errorTitle, s.errorBody, s.retry, s.emptyTitle, s.emptyBody, s.saveFailed, s.loading, s.minutes(3), s.days(3),
    ];

void main() {
  final cjk = RegExp(r'[\u3400-\u9fff]');
  final latin = RegExp(r'[A-Za-z]');
  test('every string of this edition is Chinese only', () {
    for (final t in _all(kPersonalHomeStringsZh)) {
      expect(t.isNotEmpty, isTrue);
      expect(cjk.hasMatch(t), isTrue, reason: t);
      expect(latin.hasMatch(t), isFalse, reason: t);
    }
  });
}
