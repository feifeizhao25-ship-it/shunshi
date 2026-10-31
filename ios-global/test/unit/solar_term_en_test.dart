import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/solar_term/solar_term_en.dart';
import 'package:seasons/core/solar_term/solar_term_table.dart';

void main() {
  test('every solar term in the table has an English name', () {
    for (final t in kSolarTermTable) {
      expect(kSolarTermEn.containsKey(t.name), isTrue, reason: t.name);
    }
  });
  test('mid-October 2026 is Cold Dew, never Start of Summer', () {
    final zh = solarTermNameOn(DateTime(2026, 10, 16));
    expect(zh, '寒露');
    expect(kSolarTermEn[zh]!.$1, 'Cold Dew');
  });
}
