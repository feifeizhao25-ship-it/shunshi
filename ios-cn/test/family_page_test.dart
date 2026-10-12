import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/services/family_api.dart';
import 'package:shunshi/presentation/pages/family/family_page_v2.dart';

class FamilyAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  List<Map<String, dynamic>> members = [
    {'id': 'one', 'name': '家人', 'relation': 'parent', 'age': null},
  ];
  bool offline = false;
  Completer<void>? wait;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (wait != null) await wait!.future;
    if (offline) {
      return ResponseBody.fromString(
        '{}',
        503,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    dynamic data;
    if (options.method == 'POST') {
      final values = Map<String, dynamic>.from(options.data);
      members.add({'id': 'new', ...values});
      data = members.last;
    } else if (options.method == 'DELETE') {
      members.removeWhere((m) => options.path.endsWith('/${m['id']}'));
      data = {'success': true};
    } else {
      data = {'family_name': '我的家庭', 'members': members};
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FamilyApi api(FamilyAdapter adapter, {String? Function()? readToken}) =>
    FamilyApi(
      dio: Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..httpClientAdapter = adapter,
      readToken: readToken ?? () => 'current-user-token',
    );

void main() {
  test(
    'service uses current auth and exact family response, no guest creation',
    () async {
      final adapter = FamilyAdapter();
      final result = await api(adapter).load();
      expect(result['members'][0]['age'], isNull);
      expect(adapter.requests.single.path, '/api/v1/family');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer current-user-token',
      );
    },
  );
  test('signed out does not send requests', () async {
    final adapter = FamilyAdapter();
    await expectLater(
      api(adapter, readToken: () => null).load(),
      throwsStateError,
    );
    expect(adapter.requests, isEmpty);
  });
  test('response from prior account is rejected', () async {
    final adapter = FamilyAdapter()..wait = Completer<void>();
    var token = 'a';
    final pending = api(adapter, readToken: () => token).load();
    final assertion = expectLater(pending, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    token = 'b';
    adapter.wait!.complete();
    await assertion;
  });
  testWidgets('null age is unknown while zero is a valid age', (tester) async {
    final adapter = FamilyAdapter();
    adapter.members.add({
      'id': 'baby',
      'name': '宝宝',
      'relation': 'child',
      'age': 0,
    });
    await tester.pumpWidget(MaterialApp(home: FamilyPageV2(api: api(adapter))));
    await tester.pumpAndSettle();
    expect(find.text('父母 · 年龄未填写'), findsOneWidget);
    expect(find.text('子女 · 0 岁'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('add validates and sends name relation and optional age', (
    tester,
  ) async {
    final adapter = FamilyAdapter();
    await tester.pumpWidget(MaterialApp(home: FamilyPageV2(api: api(adapter))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加家庭成员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请填写姓名'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '  妈妈  ');
    await tester.enterText(find.byType(TextFormField).last, '121');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入 0 至 120 的整数'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final request = adapter.requests.singleWhere((r) => r.method == 'POST');
    expect(request.data, {'name': '妈妈', 'relation': 'parent', 'age': null});
    expect(find.text('妈妈'), findsOneWidget);
  });
  testWidgets('load failure is not an empty family and retry works', (
    tester,
  ) async {
    final adapter = FamilyAdapter()..offline = true;
    await tester.pumpWidget(MaterialApp(home: FamilyPageV2(api: api(adapter))));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂时无法读取'), findsOneWidget);
    expect(find.textContaining('还没有家庭成员'), findsNothing);
    adapter.offline = false;
    await tester.tap(find.text('重新读取'));
    await tester.pumpAndSettle();
    expect(find.text('家人'), findsOneWidget);
  });
  testWidgets('deletion requires confirmation and refreshes persisted list', (
    tester,
  ) async {
    final adapter = FamilyAdapter();
    await tester.pumpWidget(MaterialApp(home: FamilyPageV2(api: api(adapter))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('移除成员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
    await tester.tap(find.byTooltip('移除成员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认移除'));
    await tester.pumpAndSettle();
    expect(find.textContaining('还没有家庭成员'), findsOneWidget);
  });
  testWidgets('disposed page ignores a late load', (tester) async {
    final adapter = FamilyAdapter()..wait = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: FamilyPageV2(api: api(adapter))));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    adapter.wait!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
