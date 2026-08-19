import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_context.dart';
import '../../domain/repositories/user_repository.dart';
import 'infrastructure_providers.dart';

/// UserContext provider - 全局用户状态
final userContextProvider = AsyncNotifierProvider<UserContextNotifier, UserContext>(
  UserContextNotifier.new,
);

class UserContextNotifier extends AsyncNotifier<UserContext> {
  @override
  Future<UserContext> build() async {
    final repo = ref.watch(userRepositoryProvider);
    return repo.getUser();
  }

  Future<void> updateMemoryEnabled(bool enabled) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.updateMemoryEnabled(enabled);
    state = AsyncData((state.value ?? await repo.getUser()).copyWith(
      memoryEnabled: enabled,
    ));
  }

  Future<void> updateProactiveEnabled(bool enabled) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.updateProactiveEnabled(enabled);
    state = AsyncData((state.value ?? await repo.getUser()).copyWith(
      proactiveEnabled: enabled,
    ));
  }

  Future<void> updateQuietHours(QuietHours hours) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.updateQuietHours(hours);
    state = AsyncData((state.value ?? await repo.getUser()).copyWith(
      quietHours: hours,
    ));
  }

  Future<void> refreshPremiumStatus(bool isPremium) async {
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(isPremium: isPremium);
      await ref.read(userRepositoryProvider).saveUser(updated);
      state = AsyncData(updated);
    }
  }
}
