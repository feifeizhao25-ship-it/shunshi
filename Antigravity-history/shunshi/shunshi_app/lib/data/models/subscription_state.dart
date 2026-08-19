import 'package:json_annotation/json_annotation.dart';

part 'subscription_state.g.dart';

enum SubscriptionTier { free, premium }

enum SubscriptionPlatform { ios, android, unknown }

@JsonSerializable()
class SubscriptionState {
  final SubscriptionTier tier;
  final SubscriptionPlatform platform;
  final DateTime? expiresAt;
  final bool isActive;
  final String? productId;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.platform = SubscriptionPlatform.unknown,
    this.expiresAt,
    this.isActive = false,
    this.productId,
    this.isLoading = false,
    this.error,
  });

  bool get isPremium => tier == SubscriptionTier.premium && isActive;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    SubscriptionPlatform? platform,
    DateTime? expiresAt,
    bool? isActive,
    String? productId,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      platform: platform ?? this.platform,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      productId: productId ?? this.productId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStateFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionStateToJson(this);
}
