import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi_flutter/domain/entities/care_status.dart';
import 'package:shunshi_flutter/domain/entities/follow_up_plan.dart';
import 'package:shunshi_flutter/domain/usecases/apply_presence_policy.dart';

void main() {
  late ApplyPresencePolicy useCase;

  setUp(() {
    useCase = ApplyPresencePolicy();
  });

  group('ApplyPresencePolicy', () {
    test('默认状态应返回 normal', () {
      const record = PresenceRecord();
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.normal);
    });

    test('连续3次忽略应返回 reduced', () {
      const record = PresenceRecord(consecutiveIgnores: 3, stableDays: 2);
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.reduced);
    });

    test('连续5次忽略也应返回 reduced', () {
      const record = PresenceRecord(consecutiveIgnores: 5, stableDays: 0);
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.reduced);
    });

    test('稳定7天应返回 hidden', () {
      const record = PresenceRecord(consecutiveIgnores: 0, stableDays: 7);
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.hidden);
    });

    test('稳定10天应返回 hidden', () {
      const record = PresenceRecord(consecutiveIgnores: 0, stableDays: 10);
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.hidden);
    });

    test('静默模式应立即 hidden（优先级最高）', () {
      const record = PresenceRecord(
        silentModeActive: true,
        consecutiveIgnores: 0,
        stableDays: 0,
      );
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.hidden);
    });

    test('静默模式 + 忽略 应返回 hidden（不是 reduced）', () {
      const record = PresenceRecord(
        silentModeActive: true,
        consecutiveIgnores: 5,
        stableDays: 0,
      );
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.hidden);
    });

    test('2次忽略 + 不稳定 应返回 normal', () {
      const record = PresenceRecord(consecutiveIgnores: 2, stableDays: 3);
      final level = useCase.evaluate(record);
      expect(level, PresenceLevel.normal);
    });
  });
}
