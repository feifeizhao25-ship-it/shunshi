// Language isolation of the personalised home block: this edition's text is entirely English.
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/personal_home_section.dart';
import 'package:seasons/presentation/widgets/personal_home_strings_en.dart';

List<String> _all(PersonalHomeStrings s) => [
      s.heading, s.why, s.turnOff, s.turnOn, s.offTitle, s.offBody, s.confirmTitle, s.confirmBody, s.cancel, s.confirm,
      s.errorTitle, s.errorBody, s.retry, s.emptyTitle, s.emptyBody, s.saveFailed, s.loading, s.minutes(3), s.days(3),
    ];

void main() {
  final cjk = RegExp(r'[\u3400-\u9fff]');
  final latin = RegExp(r'[A-Za-z]');
  test('every string of this edition is English only', () {
    for (final t in _all(kPersonalHomeStringsEn)) {
      expect(t.isNotEmpty, isTrue);
      expect(cjk.hasMatch(t), isFalse, reason: t);
      expect(latin.hasMatch(t), isTrue, reason: t);
    }
  });
}
