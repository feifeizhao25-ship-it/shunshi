/// ──────────────────────────────────────────────────
/// User & UserContext — 用户核心实体
/// 映射自 iOS 端 User.swift + AIAgentService.UserContext
/// ──────────────────────────────────────────────────

enum Gender {
  male,
  female,
  other;

  String get displayName {
    switch (this) {
      case Gender.male:
        return '男';
      case Gender.female:
        return '女';
      case Gender.other:
        return '其他';
    }
  }

  factory Gender.fromString(String? value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }
}

enum MembershipType {
  free,
  premium,
  vip;

  String get displayName {
    switch (this) {
      case MembershipType.free:
        return '普通会员';
      case MembershipType.premium:
        return '高级会员';
      case MembershipType.vip:
        return 'VIP会员';
    }
  }

  factory MembershipType.fromString(String? value) {
    switch (value) {
      case 'premium':
        return MembershipType.premium;
      case 'vip':
        return MembershipType.vip;
      default:
        return MembershipType.free;
    }
  }
}

enum RelationshipTier { free, premium, vip }

enum DayTimeSlot {
  morning,
  noon,
  afternoon,
  evening,
  night;

  factory DayTimeSlot.current() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return DayTimeSlot.morning;
    if (hour >= 12 && hour < 14) return DayTimeSlot.noon;
    if (hour >= 14 && hour < 18) return DayTimeSlot.afternoon;
    if (hour >= 18 && hour < 22) return DayTimeSlot.evening;
    return DayTimeSlot.night;
  }

  String get greeting {
    switch (this) {
      case DayTimeSlot.morning:
        return '早上好';
      case DayTimeSlot.noon:
        return '中午好';
      case DayTimeSlot.afternoon:
        return '下午好';
      case DayTimeSlot.evening:
        return '晚上好';
      case DayTimeSlot.night:
        return '夜深了';
    }
  }
}

// ─── Location ────────────────────
class Location {
  final String province;
  final String city;

  const Location({required this.province, required this.city});

  String get displayName => '$province $city';

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        province: json['province'] as String? ?? '',
        city: json['city'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'province': province, 'city': city};
}

// ─── UserConstitution ────────────
class UserConstitutionResult {
  final String type;
  final int score;

  const UserConstitutionResult({required this.type, required this.score});

  factory UserConstitutionResult.fromJson(Map<String, dynamic> json) =>
      UserConstitutionResult(
        type: json['type'] as String? ?? 'balanced',
        score: json['score'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'type': type, 'score': score};
}

class UserConstitution {
  final UserConstitutionResult? primary;
  final UserConstitutionResult? secondary;
  final DateTime? testedAt;

  const UserConstitution({this.primary, this.secondary, this.testedAt});

  factory UserConstitution.fromJson(Map<String, dynamic> json) =>
      UserConstitution(
        primary: json['primary'] != null
            ? UserConstitutionResult.fromJson(json['primary'])
            : null,
        secondary: json['secondary'] != null
            ? UserConstitutionResult.fromJson(json['secondary'])
            : null,
        testedAt: json['tested_at'] != null
            ? DateTime.tryParse(json['tested_at'] as String)
            : null,
      );
}

// ─── UserPreferences ─────────────
class UserPreferences {
  final bool notificationEnabled;
  final DateTime? morningReminder;
  final DateTime? eveningReminder;
  final bool solarTermReminder;
  final bool dietReminder;

  const UserPreferences({
    this.notificationEnabled = true,
    this.morningReminder,
    this.eveningReminder,
    this.solarTermReminder = true,
    this.dietReminder = true,
  });

  static const defaults = UserPreferences();

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        notificationEnabled: json['notification_enabled'] as bool? ?? true,
        morningReminder: json['morning_reminder'] != null
            ? DateTime.tryParse(json['morning_reminder'] as String)
            : null,
        eveningReminder: json['evening_reminder'] != null
            ? DateTime.tryParse(json['evening_reminder'] as String)
            : null,
        solarTermReminder: json['solar_term_reminder'] as bool? ?? true,
        dietReminder: json['diet_reminder'] as bool? ?? true,
      );
}

// ─── UserStats ───────────────────
class UserStats {
  final int checkInDays;
  final int favoritesCount;
  final int? wellnessScore;
  final int currentStreak;
  final int bestStreak;

  const UserStats({
    this.checkInDays = 0,
    this.favoritesCount = 0,
    this.wellnessScore,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  static const empty = UserStats();

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        checkInDays: json['check_in_days'] as int? ?? 0,
        favoritesCount: json['favorites_count'] as int? ?? 0,
        wellnessScore: json['wellness_score'] as int?,
        currentStreak: json['current_streak'] as int? ?? 0,
        bestStreak: json['best_streak'] as int? ?? 0,
      );
}

// ─── Membership ──────────────────
class Membership {
  final MembershipType type;
  final DateTime? expiresAt;

  const Membership({this.type = MembershipType.free, this.expiresAt});

  bool get isActive {
    switch (type) {
      case MembershipType.free:
        return true;
      case MembershipType.premium:
      case MembershipType.vip:
        if (expiresAt == null) return false;
        return expiresAt!.isAfter(DateTime.now());
    }
  }

  bool get isPremium =>
      (type == MembershipType.premium || type == MembershipType.vip) && isActive;

  static const free = Membership();

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        type: MembershipType.fromString(json['type'] as String?),
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
      );
}

// ─── SilentPeriod ────────────────
class SilentPeriod {
  final int startHour;
  final int endHour;
  final bool isActive;

  const SilentPeriod({
    this.startHour = 22,
    this.endHour = 7,
    this.isActive = false,
  });

  bool isInSilentPeriod(DateTime time) {
    if (!isActive) return false;
    final hour = time.hour;
    if (startHour > endHour) {
      return hour >= startHour || hour < endHour;
    }
    return hour >= startHour && hour < endHour;
  }

  Map<String, dynamic> toJson() => {
        'start': startHour,
        'end': endHour,
        'active': isActive,
      };
}

// ─── UserMemory ──────────────────
class UserMemory {
  final String constitution;
  final List<String> concerns;
  final List<String> foodTaboos;
  final Map<String, String> preferences;

  const UserMemory({
    this.constitution = '',
    this.concerns = const [],
    this.foodTaboos = const [],
    this.preferences = const {},
  });

  Map<String, dynamic> toJson() => {
        'constitution': constitution,
        'concerns': concerns,
        'food_taboos': foodTaboos,
        'preferences': preferences,
      };
}

// ─── User (主实体) ───────────────
class User {
  final String id;
  final String? phone;
  final String? nickname;
  final String? avatarUrl;
  final Gender? gender;
  final DateTime? birthDate;
  final DateTime? birthTime;
  final Location? location;
  final UserConstitution? constitution;
  final UserPreferences preferences;
  final UserStats stats;
  final Membership membership;
  final List<String> concerns;
  final String? sleepHabit;
  final String? foodPreference;
  final String? exerciseHabit;
  final DateTime createdAt;

  const User({
    required this.id,
    this.phone,
    this.nickname,
    this.avatarUrl,
    this.gender,
    this.birthDate,
    this.birthTime,
    this.location,
    this.constitution,
    this.preferences = const UserPreferences(),
    this.stats = const UserStats(),
    this.membership = const Membership(),
    this.concerns = const [],
    this.sleepHabit,
    this.foodPreference,
    this.exerciseHabit,
    required this.createdAt,
  });

  bool get isPremium => membership.isPremium;
  String get displayName => nickname ?? '用户';
  bool get hasCompletedProfile => nickname != null && gender != null && birthDate != null;
  bool get hasTestedConstitution => constitution?.primary != null;

  String get profileSummary {
    final parts = <String>['用户: $displayName'];
    if (gender != null) parts.add('性别: ${gender!.displayName}');
    if (concerns.isNotEmpty) parts.add('关注: ${concerns.join(", ")}');
    if (constitution?.primary != null) {
      parts.add('体质: ${constitution!.primary!.type}');
    }
    return parts.join(', ');
  }
}

// ─── UserContext (AI调用上下文) ───
class UserContext {
  final String userId;
  final UserMemory memory;
  final String? currentSolarTerm;
  final String? weather;
  final String? userProfile;
  final String? currentMood;
  final DateTime? lastActiveTime;
  final bool isPremium;
  final RelationshipTier relationshipTier;
  final DayTimeSlot timeOfDay;
  final SilentPeriod? silentPeriod;
  final bool lifePhaseEnabled;
  final bool presencePolicyEnabled;

  UserContext({
    required this.userId,
    required this.memory,
    this.currentSolarTerm,
    this.weather,
    this.userProfile,
    this.currentMood,
    this.lastActiveTime,
    this.isPremium = false,
    RelationshipTier? relationshipTier,
    this.silentPeriod,
    this.lifePhaseEnabled = true,
    this.presencePolicyEnabled = true,
  })  : relationshipTier = relationshipTier ??
            (isPremium ? RelationshipTier.premium : RelationshipTier.free),
        timeOfDay = DayTimeSlot.current();

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'is_premium': isPremium,
        'constitution': memory.constitution,
        'solar_term': currentSolarTerm,
        'mood': currentMood,
        'relationship_tier': relationshipTier.name,
        'silent_period': silentPeriod?.toJson(),
        'life_phase_enabled': lifePhaseEnabled,
        'presence_policy_enabled': presencePolicyEnabled,
      };
}
