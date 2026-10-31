import '../../../data/network/api_client.dart';

/// Connects the plan & usage page to this app's authenticated API client.
class PlanUsageBinding {
  const PlanUsageBinding._();

  static Future<Map<String, dynamic>> load() async {
    final res = await ApiClient().get('/api/v1/subscription/plan-usage');
    final data = res.data;
    if (data is! Map) throw StateError('unexpected response');
    return Map<String, dynamic>.from(data);
  }
}
