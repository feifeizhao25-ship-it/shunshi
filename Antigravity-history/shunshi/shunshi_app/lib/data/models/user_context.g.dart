// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'user_context.dart';

QuietHours _$QuietHoursFromJson(Map<String, dynamic> json) => QuietHours(
      enabled: json['enabled'] as bool? ?? false,
      start: json['start'] as String? ?? '22:00',
      end: json['end'] as String? ?? '07:00',
    );

Map<String, dynamic> _$QuietHoursToJson(QuietHours instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'start': instance.start,
      'end': instance.end,
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      language: json['language'] as String? ?? 'zh',
      darkMode: json['dark_mode'] as bool? ?? false,
      notificationsEnabled:
          json['notifications_enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'language': instance.language,
      'dark_mode': instance.darkMode,
      'notifications_enabled': instance.notificationsEnabled,
    };

UserContext _$UserContextFromJson(Map<String, dynamic> json) => UserContext(
      userId: json['user_id'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      quietHours: json['quiet_hours'] == null
          ? const QuietHours()
          : QuietHours.fromJson(json['quiet_hours'] as Map<String, dynamic>),
      memoryEnabled: json['memory_enabled'] as bool? ?? true,
      proactiveEnabled: json['proactive_enabled'] as bool? ?? true,
      preferences: json['preferences'] == null
          ? const UserPreferences()
          : UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserContextToJson(UserContext instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'is_premium': instance.isPremium,
      'quiet_hours': instance.quietHours.toJson(),
      'memory_enabled': instance.memoryEnabled,
      'proactive_enabled': instance.proactiveEnabled,
      'preferences': instance.preferences.toJson(),
    };
