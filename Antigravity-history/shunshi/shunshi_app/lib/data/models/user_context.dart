import 'package:json_annotation/json_annotation.dart';

part 'user_context.g.dart';

@JsonSerializable()
class QuietHours {
  final bool enabled;
  final String start; // "22:00"
  final String end; // "07:00"

  const QuietHours({
    this.enabled = false,
    this.start = '22:00',
    this.end = '07:00',
  });

  factory QuietHours.fromJson(Map<String, dynamic> json) =>
      _$QuietHoursFromJson(json);
  Map<String, dynamic> toJson() => _$QuietHoursToJson(this);
}

@JsonSerializable()
class UserPreferences {
  final String language;
  final bool darkMode;
  final bool notificationsEnabled;

  const UserPreferences({
    this.language = 'zh',
    this.darkMode = false,
    this.notificationsEnabled = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
}

@JsonSerializable()
class UserContext {
  final String userId;
  final bool isPremium;
  final QuietHours quietHours;
  final bool memoryEnabled;
  final bool proactiveEnabled;
  final UserPreferences preferences;

  const UserContext({
    required this.userId,
    this.isPremium = false,
    this.quietHours = const QuietHours(),
    this.memoryEnabled = true,
    this.proactiveEnabled = true,
    this.preferences = const UserPreferences(),
  });

  UserContext copyWith({
    String? userId,
    bool? isPremium,
    QuietHours? quietHours,
    bool? memoryEnabled,
    bool? proactiveEnabled,
    UserPreferences? preferences,
  }) {
    return UserContext(
      userId: userId ?? this.userId,
      isPremium: isPremium ?? this.isPremium,
      quietHours: quietHours ?? this.quietHours,
      memoryEnabled: memoryEnabled ?? this.memoryEnabled,
      proactiveEnabled: proactiveEnabled ?? this.proactiveEnabled,
      preferences: preferences ?? this.preferences,
    );
  }

  factory UserContext.fromJson(Map<String, dynamic> json) =>
      _$UserContextFromJson(json);
  Map<String, dynamic> toJson() => _$UserContextToJson(this);

  Map<String, dynamic> toApiContext() => {
        'is_premium': isPremium,
        'memory_enabled': memoryEnabled,
        'quiet_hours': quietHours.toJson(),
        'proactive_enabled': proactiveEnabled,
      };
}
