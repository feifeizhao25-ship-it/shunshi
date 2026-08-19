import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/subscription_state.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'app_state_provider.dart';
import 'infrastructure_providers.dart';

/// Subscription provider - 监听并刷新订阅状态
final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  StreamSubscription<SubscriptionState>? _sub;

  @override
  Future<SubscriptionState> build() async {
    final repo = ref.watch(subscriptionRepositoryProvider);
    // Cold start: get current entitlement
    final s = await repo.getEntitlement();
    // Listen for live updates
    _sub?.cancel();
    _sub = repo.listenEntitlement().listen((newState) {
      state = AsyncData(newState);
      // Sync premium status to UserContext
      ref
          .read(userContextProvider.notifier)
          .refreshPremiumStatus(newState.isPremium);
    });
    ref.onDispose(() => _sub?.cancel());
    // Sync initial state to UserContext
    ref
        .read(userContextProvider.notifier)
        .refreshPremiumStatus(s.isPremium);
    return s;
  }

  Future<void> purchase(String productId) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, error: null));
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.purchase(productId);
    state = AsyncData(result);
  }

  Future<void> restore() async {
    state = AsyncData(state.value!.copyWith(isLoading: true, error: null));
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.restore();
    state = AsyncData(result);
  }

  Future<List<SubscriptionProduct>> getProducts() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    return repo.getProducts();
  }
}
