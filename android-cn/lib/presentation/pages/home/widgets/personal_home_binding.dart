import '../../../../data/network/api_client.dart';
import '../../../widgets/personal_home_section.dart';

/// Connects the personalised-home block to this app's authenticated API client.
class PersonalHomeBinding {
  const PersonalHomeBinding._();

  static PersonalHomeApi api() => PersonalHomeApi(
        load: () async {
          final res = await ApiClient().get('/api/v1/seasons/home/dashboard');
          final data = res.data;
          if (data is! Map) throw StateError('unexpected response');
          return Map<String, dynamic>.from(data);
        },
        setEnabled: (enabled) async {
          await ApiClient().post('/api/v1/seasons/profile/preferences', data: {'personalization_enabled': enabled});
        },
      );
}
