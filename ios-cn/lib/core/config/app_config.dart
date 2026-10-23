/// 应用编译时配置
/// 通过 --dart-define 在构建时注入，开发环境回退至本地地址。
///
/// 用法示例:
///   flutter run --dart-define=API_BASE_URL=https://api.example.com
///   flutter build ios --dart-define=API_BASE_URL=https://api.example.com \
///                      --dart-define=APP_VARIANT=ios-cn
class AppConfig {
  AppConfig._();

  // ─── API ──────────────────────────────────────────────────────────────────
  /// 后端服务源地址（不含 /api/v1）
  /// 未传编译参数时只连本机。正式包必须传入已备案的 API 域名。
  /// 不要默认指向 shunshi.app / shunshi.ai。
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:4000',
  );

  // ─── 应用变体 ──────────────────────────────────────────────────────────────
  /// 平台变体标识（ios-cn / android-cn / ios-global / android-global）
  static const String appVariant = String.fromEnvironment(
    'APP_VARIANT',
    defaultValue: 'ios-cn',
  );

  // ─── 环境 ──────────────────────────────────────────────────────────────────
  /// 是否为正式发布（AOT 编译）
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// 是否为调试模式
  static bool get isDebug => !isProduction;

  // ─── 超时 ──────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
