import '../../../../data/network/api_client.dart';
import '../../../widgets/personal_home_section.dart';
import '../../../widgets/personal_home_strings_en.dart';

/// Connects the personalised-home block to this app's authenticated API client.
class PersonalHomeBinding {
  const PersonalHomeBinding._();

  // The server cannot know the user's local time; send the device's UTC offset (e.g. UTC+05:30).
  static String _utcOffset() {
    final o = DateTime.now().timeZoneOffset;
    final m = o.inMinutes.abs();
    final sign = o.isNegative ? '-' : '+';
    return 'UTC$sign${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  /// This edition's text; the shared widget carries no language of its own.
  static const PersonalHomeStrings strings = kPersonalHomeStringsEn;

  static PersonalHomeApi api() => PersonalHomeApi(
        load: () async {
          final res = await ApiClient().get('/api/v1/seasons/home/dashboard', queryParameters: {'tz': _utcOffset()});
          final data = res.data;
          if (data is! Map) throw StateError('unexpected response');
          return Map<String, dynamic>.from(data);
        },
        setEnabled: (enabled) async {
          await ApiClient().post('/api/v1/seasons/profile/preferences', data: {'personalization_enabled': enabled});
        },
      );
}
