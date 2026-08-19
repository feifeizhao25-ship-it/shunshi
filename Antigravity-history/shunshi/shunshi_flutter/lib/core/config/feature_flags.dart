/// Feature Flags — 支持 RemoteConfig 热更新 + 本地 fallback
class FeatureFlags {
  final bool enablePresencePolicy;
  final bool enableLifePhaseMemory;
  final bool enableSafeMode;
  final bool enableNewDailyPlanPrompt;
  final String promptCoreVersion;
  final String promptPolicyVersion;
  final String promptTaskVersion;

  const FeatureFlags({
    required this.enablePresencePolicy,
    required this.enableLifePhaseMemory,
    required this.enableSafeMode,
    required this.enableNewDailyPlanPrompt,
    required this.promptCoreVersion,
    required this.promptPolicyVersion,
    required this.promptTaskVersion,
  });

  /// 默认值（本地 fallback）
  factory FeatureFlags.defaults() => const FeatureFlags(
        enablePresencePolicy: true,
        enableLifePhaseMemory: true,
        enableSafeMode: true,
        enableNewDailyPlanPrompt: false,
        promptCoreVersion: 'core_v1.2',
        promptPolicyVersion: 'policy_v1.0',
        promptTaskVersion: 'task_v2.1',
      );

  /// 从远端 JSON 解析
  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    final defaults = FeatureFlags.defaults();
    return FeatureFlags(
      enablePresencePolicy:
          json['enable_presence_policy'] as bool? ?? defaults.enablePresencePolicy,
      enableLifePhaseMemory:
          json['enable_life_phase_memory'] as bool? ?? defaults.enableLifePhaseMemory,
      enableSafeMode:
          json['enable_safe_mode'] as bool? ?? defaults.enableSafeMode,
      enableNewDailyPlanPrompt:
          json['enable_new_daily_plan_prompt'] as bool? ??
              defaults.enableNewDailyPlanPrompt,
      promptCoreVersion:
          json['prompt_core_version'] as String? ?? defaults.promptCoreVersion,
      promptPolicyVersion:
          json['prompt_policy_version'] as String? ?? defaults.promptPolicyVersion,
      promptTaskVersion:
          json['prompt_task_version'] as String? ?? defaults.promptTaskVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'enable_presence_policy': enablePresencePolicy,
        'enable_life_phase_memory': enableLifePhaseMemory,
        'enable_safe_mode': enableSafeMode,
        'enable_new_daily_plan_prompt': enableNewDailyPlanPrompt,
        'prompt_core_version': promptCoreVersion,
        'prompt_policy_version': promptPolicyVersion,
        'prompt_task_version': promptTaskVersion,
      };

  FeatureFlags copyWith({
    bool? enablePresencePolicy,
    bool? enableLifePhaseMemory,
    bool? enableSafeMode,
    bool? enableNewDailyPlanPrompt,
    String? promptCoreVersion,
    String? promptPolicyVersion,
    String? promptTaskVersion,
  }) {
    return FeatureFlags(
      enablePresencePolicy: enablePresencePolicy ?? this.enablePresencePolicy,
      enableLifePhaseMemory: enableLifePhaseMemory ?? this.enableLifePhaseMemory,
      enableSafeMode: enableSafeMode ?? this.enableSafeMode,
      enableNewDailyPlanPrompt:
          enableNewDailyPlanPrompt ?? this.enableNewDailyPlanPrompt,
      promptCoreVersion: promptCoreVersion ?? this.promptCoreVersion,
      promptPolicyVersion: promptPolicyVersion ?? this.promptPolicyVersion,
      promptTaskVersion: promptTaskVersion ?? this.promptTaskVersion,
    );
  }
}
