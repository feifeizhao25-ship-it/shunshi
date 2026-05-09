import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/storage_manager.dart';

/// Apple Sign-In 服务
///
/// 接入步骤:
/// 1. 在 pubspec.yaml 添加依赖: sign_in_with_apple: ^6.x
/// 2. 在 Xcode 中配置 Sign in with Apple Capability
/// 3. 在 Apple Developer Portal 配置 App ID
/// 4. 在后端配置 Apple 团队 ID 和 Key ID
/// 5. 调用 [login] 发起登录
///
/// TODO: 接入真实 Apple Sign-In SDK 前，使用模拟模式
class AppleAuthService {
  static const String _provider = 'apple';

  /// 检查设备是否支持 Apple Sign-In
  bool get isAvailable => true; // iOS 13+ 都支持; Android 也可用 Web 方式

  /// 发起 Apple Sign-In
  ///
  /// 流程:
  /// 1. 调用 Apple SDK 获取 identityToken + authorizationCode
  /// 2. 将凭证发送到后端
  /// 3. 后端验证 Apple 公钥签名
  /// 4. 后端返回 JWT Token
  Future<AppleLoginResult> login() async {
    try {
      // TODO: 替换为真实 Apple Sign-In 调用
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      // );
      // final identityToken = credential.identityToken;
      // final authorizationCode = credential.authorizationCode;
      // final userIdentifier = credential.userIdentifier;

      // 模拟模式
      await Future.delayed(const Duration(seconds: 1));
      const identityToken = 'PLACEHOLDER_APPLE_TOKEN';
      const authorizationCode = 'PLACEHOLDER_APPLE_CODE';

      // 发送到后端
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await dio.post('/auth/apple/login', data: {
        'identity_token': identityToken,
        'authorization_code': authorizationCode,
        'device_info': {'platform': 'android', 'variant': AppConfig.appVariant},
      });

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['access_token'];
        final refreshToken = data['data']['refresh_token'];
        
        await StorageManager.user.setToken(token);
        await StorageManager.user.setRefreshToken(refreshToken);

        return AppleLoginResult.success(
          token: token,
          refreshToken: refreshToken,
          userInfo: data['data']['user'],
        );
      }

      return AppleLoginResult.failure(message: data['error'] ?? 'Apple 登录失败');
    } on DioException catch (e) {
      return AppleLoginResult.failure(
        message: '网络错误: ${e.message}',
        code: e.response?.statusCode?.toString(),
      );
    } catch (e) {
      return AppleLoginResult.failure(message: '未知错误: $e');
    }
  }

  /// 登出
  Future<void> logout() async {
    await StorageManager.user.clearAuth();
    // Apple Sign-In 无需额外登出操作
  }
}

class AppleLoginResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? userInfo;
  final String? message;
  final String? code;

  AppleLoginResult._({
    required this.success,
    this.token,
    this.refreshToken,
    this.userInfo,
    this.message,
    this.code,
  });

  factory AppleLoginResult.success({
    required String token,
    required String refreshToken,
    Map<String, dynamic>? userInfo,
  }) => AppleLoginResult._(
    success: true,
    token: token,
    refreshToken: refreshToken,
    userInfo: userInfo,
  );

  factory AppleLoginResult.failure({
    required String message,
    String? code,
  }) => AppleLoginResult._(
    success: false,
    message: message,
    code: code,
  );
}

/// 全局实例
final appleAuthService = AppleAuthService();
