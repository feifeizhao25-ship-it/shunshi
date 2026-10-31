import '../../../data/network/api_client.dart';

/// Connects the culture & units page to this app's authenticated API client.
class CultureBinding {
  const CultureBinding._();

  static Future<Map<String, dynamic>> load() async {
    final res = await ApiClient().get('/api/v1/profile/culture');
    final data = res.data;
    if (data is! Map) throw StateError('unexpected response');
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> save(Map<String, dynamic> body) async {
    final res = await ApiClient().put('/api/v1/profile/culture', data: body);
    final data = res.data;
    if (data is! Map) throw StateError('unexpected response');
    return Map<String, dynamic>.from(data);
  }
}
