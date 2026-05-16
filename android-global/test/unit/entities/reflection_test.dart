// test/unit/entities/reflection_test.dart
// Global SEASONS Reflection entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/reflection.dart';

void main() {
  group('Reflection entity', () {
    test('Mood enum has all values', () {
      expect(Mood.values.length, 8);
      expect(Mood.values, containsAll([
        Mood.calm,
        Mood.happy,
        Mood.energetic,
        Mood.tired,
        Mood.anxious,
        Mood.sad,
        Mood.grateful,
        Mood.hopeful,
      ]));
    });

    test('EnergyLevel enum has all values', () {
      expect(EnergyLevel.values.length, 3);
      expect(EnergyLevel.values, containsAll([
        EnergyLevel.low,
        EnergyLevel.medium,
        EnergyLevel.high,
      ]));
    });
  });
}
