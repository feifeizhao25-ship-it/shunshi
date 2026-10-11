import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/restore_attempt.dart';

RestoreAttempt<String> attempt({
  Duration timeout = const Duration(seconds: 1),
}) => RestoreAttempt(
  isSuccess: (value) => value == 'verified',
  pendingResult: 'pending',
  failedResult: 'failed',
  timeout: timeout,
);
void main() {
  test('SDK completion alone is not restored success', () async {
    final state = attempt();
    var completed = false;
    final result = state.run(() async {})
      ..then((_) {
        completed = true;
      });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    state.report(state.activeId, 'verified');
    expect(await result, 'verified');
  });
  test('concurrent requests share one launch and outcome', () async {
    final state = attempt();
    var calls = 0;
    final first = state.run(() async {
          calls++;
        }),
        second = state.run(() async {
          calls++;
        });
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    state.report(state.activeId, 'verified');
    expect(await first, 'verified');
    expect(await second, 'verified');
  });
  test('expired receipt does not mask later verified receipt', () async {
    final state = attempt();
    var finished = false;
    final result = state.run(() async {})
      ..then((_) {
        finished = true;
      });
    state.report(state.activeId, 'expired');
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    state.report(state.activeId, 'verified');
    expect(await result, 'verified');
  });
  test('no records or stuck SDK becomes uncertain, never no-history', () async {
    final state = attempt(timeout: const Duration(milliseconds: 10));
    expect(await state.run(() => Completer<void>().future), 'pending');
    expect(state.activeId, isNull);
  });
  test('launch failure resolves and permits retry', () async {
    final state = attempt();
    expect(
      await state.run(() async {
        throw StateError('injected');
      }),
      'failed',
    );
    final result = state.run(() async {});
    state.report(state.activeId, 'verified');
    expect(await result, 'verified');
  });
  test(
    'old verification and old launch failure cannot settle a newer request',
    () async {
      final state = attempt();
      final sdk = Completer<void>();
      final first = state.run(() => sdk.future);
      final oldId = state.activeId;
      state.cancel();
      expect(await first, 'pending');
      var finished = false;
      final next = state.run(() async {})
        ..then((_) {
          finished = true;
        });
      state.report(oldId, 'verified');
      sdk.completeError(StateError('old failure'));
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      state.report(state.activeId, 'verified');
      expect(await next, 'verified');
    },
  );
  test('dispose cancellation resolves waiters without success', () async {
    final state = attempt();
    final result = state.run(() async {});
    state.cancel();
    state.cancel();
    expect(await result, 'pending');
    expect(state.activeId, isNull);
  });
}
