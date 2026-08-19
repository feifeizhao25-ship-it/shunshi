import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ai_response.dart';
import '../../domain/usecases/generate_daily_plan.dart';
import 'app_state_provider.dart';
import 'infrastructure_providers.dart';

final dailyPlanProvider =
    AsyncNotifierProvider<DailyPlanNotifier, DailyPlanState>(
  DailyPlanNotifier.new,
);

class DailyPlanState {
  final AiResponse? plan;
  final bool isExpanded;
  final bool isDegraded;

  const DailyPlanState({
    this.plan,
    this.isExpanded = false,
    this.isDegraded = false,
  });

  DailyPlanState copyWith({
    AiResponse? plan,
    bool? isExpanded,
    bool? isDegraded,
  }) {
    return DailyPlanState(
      plan: plan ?? this.plan,
      isExpanded: isExpanded ?? this.isExpanded,
      isDegraded: isDegraded ?? this.isDegraded,
    );
  }
}

class DailyPlanNotifier extends AsyncNotifier<DailyPlanState> {
  @override
  Future<DailyPlanState> build() async {
    return _load();
  }

  Future<DailyPlanState> _load() async {
    final user = ref.read(userContextProvider).value;
    if (user == null) {
      return DailyPlanState(
        plan: AiResponse.degraded(''),
        isDegraded: true,
      );
    }
    final useCase = GenerateDailyPlan(ref.read(aiRepositoryProvider));
    final plan = await useCase.call(userId: user.userId, context: user);
    return DailyPlanState(
      plan: plan,
      isDegraded: plan.needsSafeMode || plan.safetyFlag == 'sensitive',
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load());
  }

  void toggleExpanded() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isExpanded: !current.isExpanded));
  }
}
