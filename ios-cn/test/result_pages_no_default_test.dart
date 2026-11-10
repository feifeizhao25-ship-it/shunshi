import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shunshi/presentation/pages/body_type/body_type_essence_page.dart';
import 'package:shunshi/presentation/pages/body_type/body_type_essence_v2.dart';
import 'package:shunshi/presentation/pages/constitution_report/constitution_report_page.dart';
import 'package:shunshi/presentation/pages/constitution_report/constitution_report_page_v2.dart';
import 'package:shunshi/presentation/pages/constitution_report/constitution_report_page_v3.dart';
import 'package:shunshi/presentation/pages/constitution_report/constitution_result_page.dart';
import 'package:shunshi/presentation/pages/solar/constitution_test_page.dart';

const _scores = {'阳虚': 0.42, '平和': 0.2};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pages = <String, Widget Function({String? type, Map<String, double>? scores})>{
    'result': ({type, scores}) => ConstitutionResultPage(constitutionType: type, scores: scores),
    'solar': ({type, scores}) => ConstitutionTestPage(constitutionType: type, scores: scores),
    'report': ({type, scores}) => ConstitutionReportPage(constitutionType: type, scores: scores),
    'report v2': ({type, scores}) => ConstitutionReportPageV2(constitutionType: type, scores: scores),
    'report v3': ({type, scores}) => ConstitutionReportPageV3(constitutionType: type, scores: scores),
    'essence': ({type, scores}) => BodyTypeEssencePage(bodyType: type, scores: scores),
    'essence v2': ({type, scores}) => BodyTypeEssenceV2(bodyType: type, scores: scores),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key} empty state has no invented result', (tester) async {
      await _pump(tester, entry.value());
      expect(find.text('还没有你的问卷结果'), findsOneWidget);
      expect(find.text('去做问卷'), findsOneWidget);
      expect(find.textContaining('气虚'), findsNothing);
      expect(find.textContaining('平和'), findsNothing);
      expect(find.textContaining('黄芪'), findsNothing);
      expect(find.text('85%'), findsNothing);
      expect(find.text('42%'), findsNothing);

      await tester.tap(find.text('去做问卷'));
      await tester.pumpAndSettle();
      expect(find.text('问卷页'), findsOneWidget);
    });

    testWidgets('${entry.key} renders only the passed scores', (tester) async {
      await _pump(tester, entry.value(type: '阳虚', scores: _scores));
      await tester.pump();
      expect(find.textContaining('阳虚'), findsWidgets);
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('还没有你的问卷结果'), findsNothing);
      expect(find.textContaining('气虚'), findsNothing);
      expect(find.textContaining('黄芪'), findsNothing);
      expect(find.text('85%'), findsNothing);
      expect(find.text('62%'), findsNothing);
      await tester.pump(const Duration(seconds: 40));
    });
  }

  testWidgets('type without scores is still empty', (tester) async {
    await _pump(tester, const ConstitutionTestPage(constitutionType: '阳虚'));
    expect(find.text('还没有你的问卷结果'), findsOneWidget);
    expect(find.text('阳虚'), findsNothing);
    expect(find.textContaining('气虚'), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  final router = GoRouter(
    initialLocation: '/page',
    routes: [
      GoRoute(path: '/page', builder: (_, __) => page),
      GoRoute(path: '/constitution-test', builder: (_, __) => const Scaffold(body: Text('问卷页'))),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
}
