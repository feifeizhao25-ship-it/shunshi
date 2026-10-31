import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/diet/diet_recommend_page.dart';

/// Real `/api/v1/knowledge/search` shape: top-level `results` (also under `data.results`),
/// client type names, `description`, `duration`, `difficulty`, `ingredients`.
void main() {
  Dio client(List<RequestOptions> calls, {bool fail = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      calls.add(request);
      if (fail) {
        handler.reject(DioException(requestOptions: request, type: DioExceptionType.connectionError));
        return;
      }
      final all = [
        {
          'id': 'seed_en_tea_013',
          'title': 'Ginger & Date Warming Tea',
          'description': 'Ginger warms the middle; red dates tonify qi.',
          'type': 'tea',
          'duration': '10 minutes',
          'difficulty': 'Easy',
          'ingredients': ['3 slices fresh ginger', '5 red dates', 'brown sugar', 'water'],
        },
        {
          'id': 'seed_en_food_therapy_019',
          'title': 'Honeysuckle Detox Tea',
          'description': 'Clears heat in summer.',
          'type': 'diet',
          'duration': '5 minutes',
          'difficulty': 'Easy',
          'ingredients': ['10g honeysuckle'],
        },
        {'id': 'x', 'title': 'Acupoint that is filtered out', 'description': '', 'type': 'meridian'},
      ];
      final type = request.queryParameters['content_type'];
      final results = type == null ? all : all.where((r) => r['type'] == type).toList();
      handler.resolve(Response(requestOptions: request, data: {
        'success': true,
        'results': results,
        'data': {'query': request.queryParameters['q'], 'total': results.length, 'results': results},
      }));
    }));
    return dio;
  }

  Future<void> open(WidgetTester tester, Dio dio, {String? type}) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: DietRecommendPage(client: dio, constitutionType: type)));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a real title, one tap target per card and no duplicate "View"', (tester) async {
    final calls = <RequestOptions>[];
    await open(tester, client(calls), type: 'yangxu');
    expect(calls.first.path, '/api/v1/knowledge/search');
    expect(calls.first.queryParameters['q'], 'Warm yang, dispel cold');
    expect(find.text('Diet recommendations'), findsOneWidget);
    expect(find.textContaining('diet_'), findsNothing);
    expect(find.text('View'), findsNothing);
    expect(find.text('Ginger & Date Warming Tea'), findsOneWidget);
    expect(find.text('Honeysuckle Detox Tea'), findsOneWidget);
    expect(find.text('Acupoint that is filtered out'), findsNothing);
    expect(find.text('10 minutes'), findsOneWidget);
    expect(find.textContaining('3 slices fresh ginger, 5 red dates, brown sugar'), findsOneWidget);
    expect(find.textContaining('Picked for your body type: Yang deficiency'), findsOneWidget);
  });

  testWidgets('a filter asks the backend for that type', (tester) async {
    final calls = <RequestOptions>[];
    await open(tester, client(calls));
    await tester.ensureVisible(find.byKey(const Key('diet_filter_tea')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diet_filter_tea')));
    await tester.pumpAndSettle();
    expect(calls.last.queryParameters['content_type'], 'tea');
    expect(find.text('Honeysuckle Detox Tea'), findsNothing);
    expect(find.text('Ginger & Date Warming Tea'), findsOneWidget);
  });

  testWidgets('a failed load shows a retry', (tester) async {
    await open(tester, client(<RequestOptions>[], fail: true));
    expect(find.text("We couldn't load recommendations. Please try again."), findsOneWidget);
  });
}
