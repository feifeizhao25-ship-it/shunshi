/// 数据模型 - 用户
class User {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final String subscriptionType;
  final DateTime? subscriptionExpiresAt;
  final String? constitution;

  User({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.subscriptionType = 'free',
    this.subscriptionExpiresAt,
    this.constitution,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      avatar: json['avatar'],
      subscriptionType: json['subscription_type'] ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null 
          ? DateTime.parse(json['subscription_expires_at']) 
          : null,
      constitution: json['constitution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'subscription_type': subscriptionType,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'constitution': constitution,
    };
  }

  bool get isPremium => subscriptionType == 'premium' || subscriptionType == 'family';
}
