enum SubscriptionTier {
  free,
  serenity,
  harmony,
  family,
  // Legacy wire value kept for backward compatibility. Normalize it to
  // serenity at API boundaries when entitlement behavior is evaluated.
  premium,
}

class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? country;
  final SubscriptionTier subscription;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic> preferences;
  
  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.country,
    this.subscription = SubscriptionTier.free,
    this.createdAt,
    this.lastActiveAt,
    this.preferences = const {},
  });
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? country,
    SubscriptionTier? subscription,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }
}
