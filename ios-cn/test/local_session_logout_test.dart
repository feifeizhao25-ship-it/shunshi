import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/data/storage/local_session.dart';
import 'package:shunshi/data/storage/storage_manager.dart';

String _jwt(String sub) {
  String b64(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64({'sub': sub, 'type': 'access'})}.sig';
}

class _Adapter implements HttpClientAdapter {
  _Adapter({this.fail = false});

  final bool fail;
  final List<RequestOptions> calls = [];
  String? tokenDuringRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    tokenDuringRequest = StorageManager.user.getToken();
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await StorageManager.init();
  }

  test('logout posts /api/v1/auth/logout before clearing the local token', () async {
    final token = _jwt('u-1');
    await boot({
      'auth_token': token,
      'user_name': '甲',
      'theme_mode': 'dark',
    });
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://x.test'))..httpClientAdapter = adapter;

    await endLocalSession(client: dio);

    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.single.method, 'POST');
    expect(adapter.calls.single.uri.path, '/api/v1/auth/logout');
    expect(adapter.calls.single.headers['Authorization'], 'Bearer $token');
    expect(adapter.tokenDuringRequest, token);
    expect(StorageManager.user.getToken(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_name'), isNull);
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('network failure still clears the local session', () async {
    final token = _jwt('u-2');
    await boot({'auth_token': token, 'user_name': '乙'});
    final adapter = _Adapter(fail: true);
    final dio = Dio(BaseOptions(baseUrl: 'http://x.test'))..httpClientAdapter = adapter;

    await endLocalSession(client: dio);

    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.single.uri.path, '/api/v1/auth/logout');
    expect(StorageManager.user.getToken(), isNull);
    expect((await SharedPreferences.getInstance()).getString('user_name'), isNull);
  });

  test('no local token skips the logout request and still clears account keys', () async {
    await boot({'user_name': '丙'});
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://x.test'))..httpClientAdapter = adapter;

    await endLocalSession(client: dio);

    expect(adapter.calls, isEmpty);
    expect((await SharedPreferences.getInstance()).getString('user_name'), isNull);
  });
}
