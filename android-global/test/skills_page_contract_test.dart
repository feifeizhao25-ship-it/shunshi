import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/skills/skills_page.dart';

/// The page parses what `GET /api/v1/skills/practices` really returns and runs a practice by
/// its `skill_id`, showing the reply text from `final_response`.
void main() {
  Dio client(
    List<RequestOptions> calls, {
    int? failPostWith,
    String reply = 'Dim the lights and put your phone away.',
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          if (request.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'count': 1,
                  'locale': 'en',
                  'skills': [
                    {
                      'id': 'sleep_optimization',
                      'skill_id': 'generate_daily_plan_sleep',
                      'name': 'Sleep wind-down plan',
                      'description': 'A gentle evening routine.',
                      'category': 'daily_plan',
                      'is_premium': false,
                    },
                  ],
                },
              ),
            );
          } else if (failPostWith != null) {
            handler.reject(
              DioException(
                requestOptions: request,
                response: Response(
                  requestOptions: request,
                  statusCode: failPostWith,
                ),
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: request,
                data: {'status': 'success', 'final_response': reply},
              ),
            );
          }
        },
      ),
    );
    return dio;
  }

  Future<void> open(WidgetTester tester, Dio dio) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: SkillsPage(client: dio)));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'lists the practices from the real response shape and runs one by skill_id',
    (tester) async {
      final calls = <RequestOptions>[];
      await open(tester, client(calls));
      expect(calls.first.path, '/api/v1/skills/practices');
      expect(find.text('Sleep wind-down plan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('practice_sleep_optimization')));
      await tester.pumpAndSettle();
      expect(calls.last.path, '/api/v1/skills/execute');
      expect(calls.last.data['skill_ids'], ['generate_daily_plan_sleep']);
      expect(
        find.text('Dim the lights and put your phone away.'),
        findsOneWidget,
      );
      expect(find.text('AI-generated'), findsOneWidget);
    },
  );

  for (final entry in {
    401: 'Please sign in to use this practice.',
    403: 'This practice needs an active membership.',
  }.entries) {
    testWidgets('a ${entry.key} answer is explained in English', (
      tester,
    ) async {
      final calls = <RequestOptions>[];
      await open(tester, client(calls, failPostWith: entry.key));
      await tester.tap(find.byKey(const Key('practice_sleep_optimization')));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets('a failed load shows a retry instead of an empty page', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.reject(
            DioException(
              requestOptions: request,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );
    await open(tester, dio);
    expect(find.text('Try again'), findsOneWidget);
  });
}
