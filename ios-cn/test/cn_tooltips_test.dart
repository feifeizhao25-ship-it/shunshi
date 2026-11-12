import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/l10n/cn_tooltips.dart';

void main() {
  testWidgets('AppBar back and menu tooltips are Chinese', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: cnLocalizationsDelegates,
        home: const Scaffold(body: Text('root')),
      ),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('会员中心')),
          body: PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'end', child: Text('结束陪伴')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('返回'), findsOneWidget);
    expect(find.byTooltip('打开菜单'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byTooltip('Show menu'), findsNothing);
  });
}
