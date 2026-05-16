import '../network/api_client.dart';
import '../config/app_config.dart';

/// Global API client singleton.
/// All pages should use this instead of creating their own Dio instances.
/// Provides: 401 silent refresh, 5xx retry, timeout levels, request dedup, locale injection.
final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
