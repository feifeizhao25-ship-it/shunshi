import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/solar_term.dart';
import '../../core/di/injection.dart';
import 'subscription_providers.dart';
import '../../domain/entities/user.dart';

/// 每日计划 Provider
final dailyPlanProvider = FutureProvider.autoDispose<DailyPlan>((ref) async {
  final isPremium = ref.watch(isPremiumProvider);
  final flags = ref.watch(featureFlagsProvider);
  final useCase = ref.watch(generateDailyPlanUseCaseProvider);

  final userContext = UserContext(
    userId: 'current_user', // TODO: from auth
    memory: const UserMemory(),
    isPremium: isPremium,
  );

  try {
    return await useCase.execute(
      userContext: userContext,
      promptVersions: {
        'core': flags.promptCoreVersion,
        'policy': flags.promptPolicyVersion,
        'task': flags.promptTaskVersion,
      },
    );
  } catch (_) {
    return DailyPlan.fallback();
  }
});

/// 当前节气 Provider
final currentSolarTermProvider =
    StateProvider<SolarTerm?>((ref) => null);

/// 底部导航索引
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
