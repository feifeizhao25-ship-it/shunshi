import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/skills/skills_page.dart';

void main() {
  Dio client(List<RequestOptions> calls, {bool forbidden = false}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          if (request.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: request,
                data: [
                  {
                    'skill_id': 'sleep',
                    'name': '睡前放松',
                    'description': '睡眠日常建议',
                    'is_premium': false,
                  },
                ],
              ),
            );
          } else if (forbidden) {
            handler.reject(
              DioException(
                requestOptions: request,
                response: Response(requestOptions: request, statusCode: 403),
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: request,
                data: {'status': 'success', 'final_response': '今晚先减少睡前屏幕使用。'},
              ),
            );
          }
        },
      ),
    );
    return dio;
  }

  testWidgets('列表字段、鉴权请求和实际响应正文一致', (tester) async {
    final calls = <RequestOptions>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SkillsPage(
          client: client(calls),
          accessToken: () async => 'test-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.first.path, '/api/v1/skills');
    await tester.tap(find.text('睡前放松'));
    await tester.pumpAndSettle();
    expect(calls.last.headers['Authorization'], 'Bearer test-token');
    expect(calls.last.data['skill_ids'], ['sleep']);
    expect(calls.last.data['message'], '请提供睡前放松的日常建议');
    expect(find.textContaining('今晚先减少睡前屏幕使用。'), findsOneWidget);
    expect(find.text('中'), findsNothing);
  });

  testWidgets('未登录不会发送生成请求', (tester) async {
    final calls = <RequestOptions>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SkillsPage(client: client(calls), accessToken: () async => null),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('睡前放松'));
    await tester.pumpAndSettle();
    expect(calls.where((request) => request.method == 'POST'), isEmpty);
    expect(find.text('请先登录，再使用此能力'), findsOneWidget);
  });

  testWidgets('权益被拒绝时明确显示错误', (tester) async {
    final calls = <RequestOptions>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SkillsPage(
          client: client(calls, forbidden: true),
          accessToken: () async => 'test-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('睡前放松'));
    await tester.pumpAndSettle();
    expect(find.text('当前账号无权使用此能力，请检查会员权益'), findsOneWidget);
    expect(find.text('本次建议'), findsNothing);
  });
}
