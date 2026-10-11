import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/presentation/pages/subscription/subscription_page_v2.dart';

UserSubscriptionStatus status({bool paid = false}) => UserSubscriptionStatus(
  planId: paid ? 'jiahe' : 'free',
  planName: paid ? '家和版' : '免费版',
  isActive: paid,
  expiresAt: paid ? DateTime.utc(2027, 1, 1) : null,
  features: {},
);
const prices = {
  'yiyang_yearly': '¥388.00',
  'yiyang_monthly': '¥58.00',
  'family_yearly': '¥688.00',
};

void main() {
  Future<void> show(WidgetTester tester, SubscriptionPageV2 page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('paid status and store prices replace static promotion', (
    tester,
  ) async {
    await show(
      tester,
      SubscriptionPageV2(
        loadStatus: () async => status(paid: true),
        loadPrices: () async => prices,
      ),
    );
    expect(find.text('家和版'), findsOneWidget);
    expect(find.text('¥388.00'), findsOneWidget);
    expect(find.text('SVIP 尊享'), findsNothing);
    expect(find.text('RECOMMENDED'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('network failure is unknown; retry reads current paid status', (
    tester,
  ) async {
    var fail = true;
    await show(
      tester,
      SubscriptionPageV2(
        loadStatus: () async {
          if (fail) throw StateError('offline');
          return status(paid: true);
        },
        loadPrices: () async => prices,
      ),
    );
    expect(find.text('暂时无法查询'), findsOneWidget);
    expect(find.text('免费版'), findsNothing);
    fail = false;
    await tester.tap(find.text('重新查询'));
    await tester.pumpAndSettle();
    expect(find.text('家和版'), findsOneWidget);
  });
  testWidgets(
    'selected SKU is sent; submitted purchase does not grant membership',
    (tester) async {
      String? selected;
      await show(
        tester,
        SubscriptionPageV2(
          loadStatus: () async => status(),
          loadPrices: () async => prices,
          purchase: (sku) async {
            selected = sku;
            return true;
          },
        ),
      );
      await tester.tap(find.text('家和版年付'));
      await tester.pump();
      await tester.ensureVisible(find.text('前往商店确认购买'));
      await tester.tap(find.text('前往商店确认购买'));
      await tester.pumpAndSettle();
      expect(selected, 'family_yearly');
      await tester.scrollUntilVisible(find.text('免费版'), -300);
      expect(find.text('免费版'), findsOneWidget);
      expect(find.text('家和版'), findsNothing);
    },
  );
  testWidgets(
    'missing store prices disable purchase without fabricated price',
    (tester) async {
      await show(
        tester,
        SubscriptionPageV2(
          loadStatus: () async => status(),
          loadPrices: () async => {},
        ),
      );
      expect(find.text('商店价格暂不可用'), findsNWidgets(3));
      await tester.ensureVisible(find.byType(FilledButton));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );
  testWidgets('restore refreshes authority instead of granting locally', (
    tester,
  ) async {
    var paid = false;
    await show(
      tester,
      SubscriptionPageV2(
        loadStatus: () async => status(paid: paid),
        loadPrices: () async => prices,
        restore: () async {
          paid = true;
        },
      ),
    );
    await tester.ensureVisible(find.text('恢复购买'));
    await tester.tap(find.text('恢复购买'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('家和版'), -300);
    expect(find.text('家和版'), findsOneWidget);
  });
  testWidgets('large text on narrow screen does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: SubscriptionPageV2(
          loadStatus: () async => status(paid: true),
          loadPrices: () async => prices,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
