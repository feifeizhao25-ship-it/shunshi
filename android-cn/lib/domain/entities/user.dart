// lib/domain/entities/user.dart
// 顺时用户实体 — 包含中医体质和家庭信息

/// 会员等级
enum SubscriptionTier {
  free,       // 免费版
  standard,   // 标准版
  premium,    // 尊享版
  family,     // 家庭版
}

/// 中医体质类型
enum ConstitutionType {
  balanced,      // 平和质
  qiDeficiency,  // 气虚质
  yangDeficiency,// 阳虚质
  yinDeficiency, // 阴虚质
  phlegmDamp,    // 痰湿质
  dampHeat,      // 湿热质
  bloodStasis,   // 血瘀质
  qiStagnation,  // 气郁质
  allergic,      // 特禀质
  unknown,       // 未识别
}

/// 性别
enum Gender { male, female, other, unknown }

/// 顺时用户
class User {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final Gender gender;
  final DateTime? birthDate;
  final SubscriptionTier subscription;
  final ConstitutionType constitution;
  final String hemisphere; // 'north' | 'south'
  final bool aiMemoryEnabled;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic> preferences;

  const User({
    required this.id,
    this.phone,
    this.email,
    this.name,
    this.avatarUrl,
    this.gender = Gender.unknown,
    this.birthDate,
    this.subscription = SubscriptionTier.free,
    this.constitution = ConstitutionType.unknown,
    this.hemisphere = 'north',
    this.aiMemoryEnabled = true,
    this.createdAt,
    this.lastActiveAt,
    this.preferences = const {},
  });

  bool get isPremium => subscription != SubscriptionTier.free;
  bool get isFamilyPlan => subscription == SubscriptionTier.family;

  /// 获取体质中文名
  String get constitutionName {
    const names = {
      ConstitutionType.balanced: '平和质',
      ConstitutionType.qiDeficiency: '气虚质',
      ConstitutionType.yangDeficiency: '阳虚质',
      ConstitutionType.yinDeficiency: '阴虚质',
      ConstitutionType.phlegmDamp: '痰湿质',
      ConstitutionType.dampHeat: '湿热质',
      ConstitutionType.bloodStasis: '血瘀质',
      ConstitutionType.qiStagnation: '气郁质',
      ConstitutionType.allergic: '特禀质',
      ConstitutionType.unknown: '未识别',
    };
    return names[constitution] ?? '未知';
  }

  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? name,
    String? avatarUrl,
    Gender? gender,
    DateTime? birthDate,
    SubscriptionTier? subscription,
    ConstitutionType? constitution,
    String? hemisphere,
    bool? aiMemoryEnabled,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      subscription: subscription ?? this.subscription,
      constitution: constitution ?? this.constitution,
      hemisphere: hemisphere ?? this.hemisphere,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'name': name,
    'avatar_url': avatarUrl,
    'gender': gender.name,
    'birth_date': birthDate?.toIso8601String(),
    'subscription': subscription.name,
    'constitution': constitution.name,
    'hemisphere': hemisphere,
    'ai_memory_enabled': aiMemoryEnabled,
    'created_at': createdAt?.toIso8601String(),
    'last_active_at': lastActiveAt?.toIso8601String(),
    'preferences': preferences,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    name: json['name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    gender: Gender.values.firstWhere(
      (e) => e.name == json['gender'],
      orElse: () => Gender.unknown,
    ),
    birthDate: json['birth_date'] != null
        ? DateTime.tryParse(json['birth_date'] as String)
        : null,
    subscription: SubscriptionTier.values.firstWhere(
      (e) => e.name == json['subscription'],
      orElse: () => SubscriptionTier.free,
    ),
    constitution: ConstitutionType.values.firstWhere(
      (e) => e.name == json['constitution'],
      orElse: () => ConstitutionType.unknown,
    ),
    hemisphere: json['hemisphere'] as String? ?? 'north',
    aiMemoryEnabled: json['ai_memory_enabled'] as bool? ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    lastActiveAt: json['last_active_at'] != null
        ? DateTime.tryParse(json['last_active_at'] as String)
        : null,
    preferences: json['preferences'] as Map<String, dynamic>? ?? {},
  );
}
