/// 环境枚举
enum Env { dev, staging, prod }

/// 应用环境配置
class AppConfig {
  final Env env;
  final String aiRouterBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppConfig._({
    required this.env,
    required this.aiRouterBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory AppConfig.dev() => const AppConfig._(
        env: Env.dev,
        aiRouterBaseUrl: 'https://ai-router-dev.shunshi.app',
        supabaseUrl: String.fromEnvironment('SUPABASE_URL',
            defaultValue: 'https://dev.supabase.co'),
        supabaseAnonKey:
            String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      );

  factory AppConfig.staging() => const AppConfig._(
        env: Env.staging,
        aiRouterBaseUrl: 'https://ai-router-staging.shunshi.app',
        supabaseUrl: String.fromEnvironment('SUPABASE_URL',
            defaultValue: 'https://staging.supabase.co'),
        supabaseAnonKey:
            String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      );

  factory AppConfig.prod() => const AppConfig._(
        env: Env.prod,
        aiRouterBaseUrl: 'https://dev-api.shunshi.ai',
        supabaseUrl: String.fromEnvironment('SUPABASE_URL',
            defaultValue: 'https://your-project.supabase.co'),
        supabaseAnonKey:
            String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'),
      );

  bool get isDev => env == Env.dev;
  bool get isStaging => env == Env.staging;
  bool get isProd => env == Env.prod;
}
