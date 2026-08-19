import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_context.dart';
import 'app_state_provider.dart';
import 'infrastructure_providers.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserContext>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<UserContext> {
  @override
  Future<UserContext> build() async {
    return ref.watch(userContextProvider.future);
  }

  Future<void> setMemoryEnabled(bool enabled) async {
    await ref.read(userContextProvider.notifier).updateMemoryEnabled(enabled);
    state = AsyncData(
      (state.value ?? await ref.read(userRepositoryProvider).getUser())
          .copyWith(memoryEnabled: enabled),
    );
  }

  Future<void> setProactiveEnabled(bool enabled) async {
    await ref.read(userContextProvider.notifier).updateProactiveEnabled(enabled);
    state = AsyncData(
      (state.value ?? await ref.read(userRepositoryProvider).getUser())
          .copyWith(proactiveEnabled: enabled),
    );
  }

  Future<void> setQuietHours(QuietHours hours) async {
    await ref.read(userContextProvider.notifier).updateQuietHours(hours);
    state = AsyncData(
      (state.value ?? await ref.read(userRepositoryProvider).getUser())
          .copyWith(quietHours: hours),
    );
  }
}
