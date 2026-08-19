import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription_state.dart';

/// 订阅状态 Provider（统一双端）
final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionStateNotifier, SubscriptionState>((ref) {
  return SubscriptionStateNotifier();
});

class SubscriptionStateNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionStateNotifier() : super(const SubscriptionState());

  void update(SubscriptionState newState) {
    state = newState;
  }

  void setActive({required String productId, required DateTime expiresAt}) {
    state = SubscriptionState(
      status: SubscriptionStatus.active,
      productId: productId,
      expirationDate: expiresAt,
      purchaseDate: DateTime.now(),
    );
  }

  void setExpired() {
    state = state.copyWith(status: SubscriptionStatus.expired);
  }

  void clear() {
    state = const SubscriptionState();
  }
}

/// 便捷 isPremium Provider
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionStateProvider).isPremium;
});
