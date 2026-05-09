import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/storage_manager.dart';

/// 微信登录服务
/// 
/// 接入步骤:
/// 1. 在 pubspec.yaml 添加依赖: fluwx: ^4.x
/// 2. 在 AndroidManifest.xml 配置 WXEntryActivity
/// 3. 在微信开放平台注册应用，获取 AppID
/// 4. 调用 [initialize] 初始化
/// 5. 调用 [login] 发起登录
///
/// TODO: 接入真实微信SDK前，使用模拟模式
class WechatAuthService {
  static const String _provider = 'wechat';
  static bool _initialized = false;

  /// 是否已安装微信
  bool get isWechatInstalled => _initialized; // TODO: 替换为 fluwx.isWeChatInstalled

  /// 初始化微信SDK
  Future<void> initialize() async {
    // TODO: 接入 fluwx
    // await Fluwx().registerApi(
    //   appId: 'YOUR_WECHAT_APPID',
    //   universalLink: 'https://yourdomain.com/universal_link/',
    // );
    _initialized = true;
  }

  /// 发起微信登录
  ///
  /// 流程:
  /// 1. 调用微信SDK获取 AuthCode
  /// 2. 将 AuthCode 发送到后端
  /// 3. 后端用 AuthCode 向微信换取 OpenID + UnionID
  /// 4. 后端返回 JWT Token
  Future<WechatLoginResult> login() async {
    try {
      // TODO: 替换为真实微信SDK调用
      // final auth = await Fluwx().authBy(which: NormalAuth(scope: 'snsapi_userinfo'));
      // if (!auth.isSuccessful) throw Exception('微信授权失败: ${auth.errorCode}');
      // final authCode = auth.code!;

      // 模拟模式（开发测试用）
      await Future.delayed(const Duration(seconds: 1));
      const authCode = 'PLACEHOLDER_WECHAT_CODE';

      // 发送到后端换取 Token
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await dio.post('/auth/wechat', data: {
        'code': authCode,
        'device_info': {'platform': 'android', 'variant': AppConfig.appVariant},
      });

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['access_token'];
        final refreshToken = data['data']['refresh_token'];
        
        // 保存 Token
        await StorageManager.user.setToken(token);
        await StorageManager.user.setRefreshToken(refreshToken);

        return WechatLoginResult.success(
          token: token,
          refreshToken: refreshToken,
          userInfo: data['data']['user'],
        );
      }

      return WechatLoginResult.failure(message: data['error'] ?? '登录失败');
    } on DioException catch (e) {
      return WechatLoginResult.failure(
        message: '网络错误: ${e.message}',
        code: e.response?.statusCode?.toString(),
      );
    } catch (e) {
      return WechatLoginResult.failure(message: '未知错误: $e');
    }
  }

  /// 检查微信登录状态
  Future<bool> checkLoginStatus() async {
    final token = StorageManager.user.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await dio.get('/auth/me');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    await StorageManager.user.clearAuth();
    // TODO: 调用 fluwx 登出
  }
}

class WechatLoginResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? userInfo;
  final String? message;
  final String? code;

  WechatLoginResult._({
    required this.success,
    this.token,
    this.refreshToken,
    this.userInfo,
    this.message,
    this.code,
  });

  factory WechatLoginResult.success({
    required String token,
    required String refreshToken,
    Map<String, dynamic>? userInfo,
  }) => WechatLoginResult._(
    success: true,
    token: token,
    refreshToken: refreshToken,
    userInfo: userInfo,
  );

  factory WechatLoginResult.failure({
    required String message,
    String? code,
  }) => WechatLoginResult._(
    success: false,
    message: message,
    code: code,
  );
}

/// 全局实例
final wechatAuthService = WechatAuthService();
