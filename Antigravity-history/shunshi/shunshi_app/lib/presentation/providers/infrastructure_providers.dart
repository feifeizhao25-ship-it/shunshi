import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/ai_router_api.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../data/repositories/followup_repository_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/repositories/followup_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/repositories/user_repository.dart';

// ────────── Infrastructure Providers ──────────

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope override');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  const baseUrl = String.fromEnvironment(
    'AI_ROUTER_URL',
    defaultValue: 'https://api.shunshi.ai/v1',
  );
  const apiKey = String.fromEnvironment('AI_ROUTER_API_KEY', defaultValue: '');
  return ApiClient(baseUrl: baseUrl, apiKey: apiKey.isEmpty ? null : apiKey);
});

final aiRouterApiProvider = Provider<AiRouterApi>((ref) {
  return AiRouterApi(client: ref.watch(apiClientProvider));
});

// ────────── Repository Providers ──────────

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(
    api: ref.watch(aiRouterApiProvider),
    prefs: ref.watch(sharedPrefsProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(prefs: ref.watch(sharedPrefsProvider));
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepositoryImpl();
});

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepositoryImpl(prefs: ref.watch(sharedPrefsProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    iap: InAppPurchase.instance,
    prefs: ref.watch(sharedPrefsProvider),
  );
});
