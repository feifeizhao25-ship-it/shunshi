// User Life Stage Detection Service
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Life stage enum
enum LifeStage {
  /// Exploration (18-25)
  exploration,

  /// Pressure (25-40)
  pressure,

  /// Health (40-60)
  health,

  /// Companionship (60+)
  companionship,
}

/// User Profile
class UserProfile {
  final String name;
  final int age;
  final LifeStage lifeStage;
  final DateTime birthday;
  final String gender;

  const UserProfile({
    required this.name,
    required this.age,
    required this.lifeStage,
    required this.birthday,
    this.gender = 'unknown',
  });

  factory UserProfile.fromAge(int age) {
    return UserProfile(
      name: 'User',
      age: age,
      lifeStage: LifeStageHelper.fromAge(age),
      birthday: DateTime.now().subtract(Duration(days: age * 365)),
    );
  }

  factory UserProfile.fromBirthday(DateTime birthday) {
    final age = LifeStageHelper.calculateAge(birthday);
    return UserProfile(
      name: 'User',
      age: age,
      lifeStage: LifeStageHelper.fromAge(age),
      birthday: birthday,
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    LifeStage? lifeStage,
    DateTime? birthday,
    String? gender,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      lifeStage: lifeStage ?? this.lifeStage,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
    );
  }

  /// Get stage name
  String get stageName => LifeStageHelper.getName(lifeStage);

  /// Get stage description
  String get stageDescription => LifeStageHelper.getDescription(lifeStage);

  /// Get home modules
  List<String> get homeModules => LifeStageHelper.getHomeModules(lifeStage);
}

/// Life stage helper
class LifeStageHelper {
  /// Get stage from age
  static LifeStage fromAge(int age) {
    if (age < 25) return LifeStage.exploration;
    if (age < 40) return LifeStage.pressure;
    if (age < 60) return LifeStage.health;
    return LifeStage.companionship;
  }

  /// Calculate age from birthday
  static int calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Get stage name
  static String getName(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return 'Exploration';
      case LifeStage.pressure:
        return 'Pressure Management';
      case LifeStage.health:
        return 'Wellness & Body Type';
      case LifeStage.companionship:
        return 'Companionship';
    }
  }

  /// Get stage description
  static String getDescription(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return 'Daily rhythms & emotional wellness';
      case LifeStage.pressure:
        return 'Stress & health management';
      case LifeStage.health:
        return 'Wellness & body type conditioning';
      case LifeStage.companionship:
        return 'Life companionship';
    }
  }

  /// Get home modules for stage
  static List<String> getHomeModules(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return ['Daily Rhythm', 'AI Chat', 'Sleep Tips'];
      case LifeStage.pressure:
        return ["Today's Insight", 'Three Small Things', 'Follow-up Reminders'];
      case LifeStage.health:
        return ['Seasonal Wellness', 'Daily Wellness', 'Body Type Conditioning'];
      case LifeStage.companionship:
        return ['Daily Wisdom', 'Voice Chat', 'Daily Suggestions'];
    }
  }
}

/// User Profile Provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);

  /// Set birthday
  void setBirthday(DateTime birthday) {
    final profile = UserProfile.fromBirthday(birthday);
    state = profile;
  }

  /// Set age
  void setAge(int age) {
    final profile = UserProfile.fromAge(age);
    state = profile;
  }

  /// Update profile
  void updateProfile({
    String? name,
    DateTime? birthday,
    String? gender,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      name: name,
      birthday: birthday,
      gender: gender,
    );
  }

  /// Clear profile
  void clearProfile() {
    state = null;
  }
}
