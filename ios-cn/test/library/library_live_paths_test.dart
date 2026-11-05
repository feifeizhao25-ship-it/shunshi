// 资料库的后端接口路径必须带 /api/v1：后端路由是 /api/v1/library/*，ApiClient 的 baseUrl 不含 /api/v1，
// 少了前缀会 404、页面永远退回离线内容（2026-11-05 真机复测发现）。
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/network/api_client.dart';
import 'package:shunshi/presentation/pages/library/shunshi_reference_library.dart';

class _RecordingClient extends ApiClient {
  final calls = <String>[];
  Response _ok(String m, String p) {
    calls.add('$m $p');
    return Response(requestOptions: RequestOptions(path: p), data: <String, dynamic>{});
  }

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async => _ok('GET', path);
  @override
  Future<Response> post(String path, {dynamic data}) async => _ok('POST', path);
  @override
  Future<Response> put(String path, {dynamic data}) async => _ok('PUT', path);
}

void main() {
  test('library live API calls /api/v1/library/*', () async {
    final c = _RecordingClient();
    final live = shunshiLibraryLive(c);
    await live.entries();
    await live.feed();
    await live.setPrefs({'enabled': true});
    await live.visit();
    await live.opened('x1');
    expect(c.calls, [
      'GET /api/v1/library/entries',
      'GET /api/v1/library/feed',
      'PUT /api/v1/library/preferences',
      'POST /api/v1/library/visit',
      'POST /api/v1/library/opened/x1',
    ]);
  });
}
