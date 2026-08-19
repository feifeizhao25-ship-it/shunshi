import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../config/feature_flags.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../storage/local_storage.dart' as app_storage;
import '../storage/secure_storage.dart';
import '../../data/datasources/remote/ai_router_datasource.dart';
import '../../data/datasources/local/chat_local_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/generate_daily_plan.dart';
import '../../domain/usecases/apply_presence_policy.dart';
import '../../domain/usecases/schedule_follow_up.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════
//  基础设施 Providers
// ═══════════════════════════════════════════

final appConfigProvider = Provider<AppConfig>((ref) {
  // 默认 dev 环境，可通过 main.dart 覆写
  return AppConfig.dev();
});

final featureFlagsProvider = StateProvider<FeatureFlags>((ref) {
  return FeatureFlags.defaults();
});

final localStorageProvider = Provider<app_storage.LocalStorage>((ref) {
  return app_storage.LocalStorage();
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(config: config);
});

// ═══════════════════════════════════════════
//  DataSource Providers
// ═══════════════════════════════════════════

final aiRouterDatasourceProvider = Provider<AIRouterDatasource>((ref) {
  return AIRouterDatasource(ref.watch(apiClientProvider));
});

final chatLocalDatasourceProvider = Provider<ChatLocalDatasource>((ref) {
  return ChatLocalDatasource(ref.watch(localStorageProvider));
});

// ═══════════════════════════════════════════
//  Repository Providers
// ═══════════════════════════════════════════

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(ref.watch(aiRouterDatasourceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    remote: ref.watch(aiRouterDatasourceProvider),
    local: ref.watch(chatLocalDatasourceProvider),
  );
});

// ═══════════════════════════════════════════
//  UseCase Providers
// ═══════════════════════════════════════════

final sendMessageUseCaseProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(chatRepositoryProvider));
});

final generateDailyPlanUseCaseProvider = Provider<GenerateDailyPlan>((ref) {
  return GenerateDailyPlan(ref.watch(chatRepositoryProvider));
});

final applyPresencePolicyProvider = Provider<ApplyPresencePolicy>((ref) {
  return ApplyPresencePolicy();
});

final scheduleFollowUpProvider = Provider<ScheduleFollowUp>((ref) {
  return ScheduleFollowUp();
});
