import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../storage/storage_manager.dart';

class FamilyApi {
  FamilyApi({Dio? dio, String? Function()? readToken})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiClient.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ),
      _readToken = readToken ?? (() => StorageManager.user.getToken());
  final Dio _dio;
  final String? Function() _readToken;

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final token = _readToken();
    if (token == null || token.trim().isEmpty) throw StateError('请先登录');
    final response = await _dio.request(
      path,
      data: data,
      options: Options(
        method: method,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    if (_readToken() != token) throw StateError('登录状态已变化');
    return response.data;
  }

  Future<Map<String, dynamic>> load() async {
    final body = await _request('GET', '/api/v1/family');
    if (body is! Map ||
        body['family_name'] is! String ||
        body['members'] is! List) {
      throw const FormatException('家庭信息格式不正确');
    }
    for (final member in body['members']) {
      if (member is! Map ||
          member['id'] is! String ||
          member['name'] is! String ||
          member['relation'] is! String ||
          (member['age'] != null && member['age'] is! int)) {
        throw const FormatException('成员信息格式不正确');
      }
    }
    return Map<String, dynamic>.from(body);
  }

  Future<void> add(Map<String, dynamic> values) async {
    final result = await _request(
      'POST',
      '/api/v1/family/members',
      data: values,
    );
    if (result is! Map || result['id'] is! String) {
      throw const FormatException('添加结果未确认');
    }
  }

  void dispose() => _dio.close(force: true);

  Future<void> remove(String id) async {
    final result = await _request(
      'DELETE',
      '/api/v1/family/members/${Uri.encodeComponent(id)}',
    );
    if (result is! Map || result['success'] != true) throw StateError('移除未确认');
  }
}
