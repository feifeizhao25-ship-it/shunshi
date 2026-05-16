/// 应用编译时配置
/// 通过 --dart-define 在构建时注入，开发环境回退至本地地址。
///
/// 用法示例:
///   flutter run --dart-define=API_BASE_URL=https://api.seasonsapp.com/api/v1
///   flutter build android --dart-define=API_BASE_URL=https://api.seasonsapp.com/api/v1 \
///                          --dart-define=APP_VARIANT=android-global
class AppConfig {
  AppConfig._();

  // ─── API ──────────────────────────────────────────────────────────────────
  /// 后端 API 基础地址（含 /api/v1）
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://116.62.32.43:4000',
  );

  /// 后端基础地址（不含 /api/v1），用于 Dio baseUrl 等
  static const String baseUrl = 'http://116.62.32.43:4000';

  // ─── 应用变体 ──────────────────────────────────────────────────────────────
  /// 平台变体标识（ios-cn / android-cn / ios-global / android-global）
  static const String appVariant = String.fromEnvironment(
    'APP_VARIANT',
    defaultValue: 'android-global',
  );

  // ─── 环境 ──────────────────────────────────────────────────────────────────
  /// 是否为正式发布（AOT 编译）
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// 是否为调试模式
  static bool get isDebug => !isProduction;

  // ─── 超时 ──────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout    = Duration(seconds: 30);
}
