import '../../../core/culture/device_hints.dart';
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

  /// PUT /api/v1/profile/culture/device: what this device says (hemisphere, UTC offset). Never replaces a hemisphere
  /// the user chose, unless [force] (the "Use my device setting" button).
  static Future<Map<String, dynamic>> device(Map<String, dynamic> body) async {
    final res = await ApiClient().put('/api/v1/profile/culture/device', data: body);
    final data = res.data;
    if (data is! Map) throw StateError('unexpected response');
    return Map<String, dynamic>.from(data);
  }

  /// Once per app session, after sign-in: tell the server what the device detected.
  static Future<void> syncDeviceOnce() => DeviceCultureSync.run(device);

  /// "Use my device setting": re-detect and apply, replacing the user's own choice.
  static Future<Map<String, dynamic>> useDevice() async =>
      await DeviceCultureSync.run(device, force: true) ?? (throw StateError('could not apply'));
}
