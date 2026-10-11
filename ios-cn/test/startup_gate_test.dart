import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/startup_gate.dart';

void main() {
  Widget ready(BuildContext _) => const MaterialApp(home: Text('已进入应用'));
  testWidgets('storage resolves before store listeners and normal app', (
    tester,
  ) async {
    final storage = Completer<void>();
    final events = <String>[];
    await tester.pumpWidget(
      StartupGate(
        initializeStorage: () {
          events.add('storage');
          return storage.future;
        },
        initializeNotifications: () async {
          events.add('notification');
        },
        initializeStore: () async {
          events.add('store');
        },
        readyBuilder: ready,
      ),
    );
    await tester.pump();
    expect(events, ['storage']);
    expect(find.text('已进入应用'), findsNothing);
    storage.complete();
    await tester.pumpAndSettle();
    expect(events, ['storage', 'notification', 'store']);
    expect(find.text('已进入应用'), findsOneWidget);
  });
  testWidgets('storage failure blocks dependent services and retry succeeds', (
    tester,
  ) async {
    var attempts = 0, stores = 0, notifications = 0;
    await tester.pumpWidget(
      StartupGate(
        initializeStorage: () async {
          if (++attempts == 1) throw StateError('private storage detail');
        },
        initializeNotifications: () async {
          notifications++;
        },
        initializeStore: () async {
          stores++;
        },
        readyBuilder: ready,
      ),
    );
    await tester.pumpAndSettle();
    expect(stores, 0);
    expect(notifications, 0);
    expect(find.text('本机账号资料暂时无法读取，请重试。'), findsOneWidget);
    expect(find.textContaining('private storage'), findsNothing);
    await tester.tap(find.text('重新启动'));
    await tester.pumpAndSettle();
    expect(stores, 1);
    expect(notifications, 1);
    expect(attempts, 2);
    expect(find.text('已进入应用'), findsOneWidget);
  });
  testWidgets('optional service failure does not prevent app access', (
    tester,
  ) async {
    var store = false;
    await tester.pumpWidget(
      StartupGate(
        initializeStorage: () async {},
        initializeNotifications: () async {
          throw StateError('notification');
        },
        initializeStore: () async {
          store = true;
          throw StateError('store');
        },
        readyBuilder: ready,
      ),
    );
    await tester.pumpAndSettle();
    expect(store, isTrue);
    expect(find.text('已进入应用'), findsOneWidget);
  });
  testWidgets('disposed gate never starts dependent services', (tester) async {
    final storage = Completer<void>();
    var starts = 0;
    await tester.pumpWidget(
      StartupGate(
        initializeStorage: () => storage.future,
        initializeNotifications: () async {
          starts++;
        },
        initializeStore: () async {
          starts++;
        },
        readyBuilder: ready,
      ),
    );
    await tester.pumpWidget(const SizedBox());
    storage.complete();
    await tester.pump();
    expect(starts, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'optional service timeout allows entry without claiming readiness',
    (tester) async {
      await tester.pumpWidget(
        StartupGate(
          initializeStorage: () async {},
          initializeNotifications: () async {},
          initializeStore: () => Completer<void>().future,
          readyBuilder: ready,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 36));
      await tester.pumpAndSettle();
      expect(find.text('已进入应用'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
