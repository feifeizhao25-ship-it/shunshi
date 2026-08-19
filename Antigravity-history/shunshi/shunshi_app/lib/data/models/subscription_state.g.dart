// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'subscription_state.dart';

SubscriptionState _$SubscriptionStateFromJson(Map<String, dynamic> json) =>
    SubscriptionState(
      tier: $enumDecodeNullable(_$SubscriptionTierEnumMap, json['tier']) ??
          SubscriptionTier.free,
      platform:
          $enumDecodeNullable(_$SubscriptionPlatformEnumMap, json['platform']) ??
              SubscriptionPlatform.unknown,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      isActive: json['is_active'] as bool? ?? false,
      productId: json['product_id'] as String?,
      isLoading: json['is_loading'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$SubscriptionStateToJson(SubscriptionState instance) =>
    <String, dynamic>{
      'tier': _$SubscriptionTierEnumMap[instance.tier]!,
      'platform': _$SubscriptionPlatformEnumMap[instance.platform]!,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'is_active': instance.isActive,
      'product_id': instance.productId,
      'is_loading': instance.isLoading,
      'error': instance.error,
    };

const _$SubscriptionTierEnumMap = {
  SubscriptionTier.free: 'free',
  SubscriptionTier.premium: 'premium',
};

const _$SubscriptionPlatformEnumMap = {
  SubscriptionPlatform.ios: 'ios',
  SubscriptionPlatform.android: 'android',
  SubscriptionPlatform.unknown: 'unknown',
};

T? $enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) return null;
  return enumValues.entries
      .singleWhere(
        (e) => e.value == source,
        orElse: () => enumValues.entries.first,
      )
      .key;
}
