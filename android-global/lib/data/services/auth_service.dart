/// 认证服务 - 支持多种登录方式
/// 真实实现: 调用后端 /api/v1/auth/* 接口
library;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/api_service.dart';
import '../storage/storage_manager.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? _currentUser;
  bool _isAnonymous = true;

  final UserService _userService = UserService();

  /// Google Sign In (真实实现)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'error': '用户取消了 Google 登录'};
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return {'error': 'Google 登录失败: 未获取到 ID Token'};
      }

      // 调用后端 Google 登录接口
      final response = await _userService.googleLogin(
        idToken: idToken,
        deviceId: _getDeviceId(),
        platform: _getPlatform(),
      );

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        _saveAuthData(data);
        _currentUser = data['user'];
        _isAnonymous = false;
        return {'success': true, 'user': _currentUser};
      } else {
        return {'error': response['detail'] ?? 'Google 登录失败'};
      }
    } catch (e) {
      return {'error': 'Google 登录失败: ${e.toString()}'};
    }
  }

  /// Apple Sign In (真实实现)
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        return {'error': 'Apple 登录失败: 未获取到 identity token'};
      }

      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }

      // 调用后端 Apple 登录接口
      final response = await _userService.appleLogin(
        identityToken: credential.identityToken!,
        authorizationCode: credential.authorizationCode,
        name: displayName,
        deviceId: _getDeviceId(),
        platform: _getPlatform(),
      );

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        _saveAuthData(data);
        _currentUser = data['user'];
        _isAnonymous = false;
        return {'success': true, 'user': _currentUser};
      } else {
        return {'error': response['detail'] ?? 'Apple 登录失败'};
      }
    } on SignInWithAppleException catch (e) {
      return {'error': 'Apple 登录失败: ${e.toString()}'};
    } catch (e) {
      return {'error': 'Apple 登录失败: ${e.toString()}'};
    }
  }

  /// 邮箱登录 (调用后端)
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return {'error': '请输入邮箱和密码'};
    }

    try {
      final response = await _userService.login(email, password);

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        _saveAuthData(data);
        _currentUser = data['user'];
        _isAnonymous = false;
        return {'success': true, 'user': _currentUser};
      } else {
        return {'error': response['detail'] ?? '登录失败'};
      }
    } catch (e) {
      return {'error': '登录失败: ${e.toString()}'};
    }
  }

  /// 邮箱注册 (调用后端)
  Future<Map<String, dynamic>> registerWithEmail(String name, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return {'error': '请输入邮箱和密码'};
    }

    try {
      final response = await _userService.register(name, email, password);

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        _saveAuthData(data);
        _currentUser = data['user'];
        _isAnonymous = false;
        return {'success': true, 'user': _currentUser};
      } else {
        return {'error': response['detail'] ?? '注册失败'};
      }
    } catch (e) {
      return {'error': '注册失败: ${e.toString()}'};
    }
  }

  /// 匿名登录 (调用后端)
  Future<Map<String, dynamic>> signInAnonymously() async {
    try {
      final response = await _userService.guestLogin(
        deviceId: _getDeviceId(),
        platform: _getPlatform(),
      );

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        _saveAuthData(data);
        _currentUser = data['user'];
        _isAnonymous = true;
        return {'success': true, 'user': _currentUser};
      } else {
        return {'error': response['detail'] ?? '游客登录失败'};
      }
    } catch (e) {
      return {'error': '游客登录失败: ${e.toString()}'};
    }
  }

  /// 获取当前用户
  Map<String, dynamic>? getCurrentUser() => _currentUser;

  /// 是否已登录
  bool get isLoggedIn => _currentUser != null && !_isAnonymous;

  /// 是否匿名用户
  bool get isAnonymous => _isAnonymous;

  /// 登出 (调用后端)
  Future<void> signOut() async {
    try {
      _userService.logout();
    } catch (_) {}

    _currentUser = null;
    _isAnonymous = true;
    StorageManager.user.clear();
  }

  /// 升级匿名账户 (绑定邮箱)
  Future<Map<String, dynamic>> upgradeAnonymous(String email, String password) async {
    if (_currentUser == null || !_isAnonymous) {
      return {'error': '当前不是匿名登录'};
    }

    try {
      final response = await _userService.register(
        email.split('@').first,
        email,
        password,
      );

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        _saveAuthData(data);
        _currentUser = data['user'];
        _isAnonymous = false;
        return {'success': true, 'user': _currentUser};
      } else {
        return {'error': response['detail'] ?? '升级失败'};
      }
    } catch (e) {
      return {'error': '升级失败: ${e.toString()}'};
    }
  }

  /// 从本地存储恢复登录状态
  Future<bool> restoreSession() async {
    final token = StorageManager.user.getToken();
    if (token == null) return false;

    try {
      final response = await _userService.getProfile();
      if (response['success'] == true) {
        _currentUser = response['data'];
        _isAnonymous = false;
        return true;
      }
    } catch (_) {}

    return false;
  }

  // ============ 私有辅助 ============

  void _saveAuthData(Map<String, dynamic> data) {
    final token = data['token'];
    final refreshToken = data['refresh_token'];
    if (token != null) {
      StorageManager.user.saveToken(token);
    }
    if (refreshToken != null) {
      StorageManager.user.saveRefreshToken(refreshToken);
    }
    final user = data['user'];
    if (user != null) {
      StorageManager.user.saveUserInfo(Map<String, dynamic>.from(user));
    }
  }

  String _getDeviceId() {
    var deviceId = StorageManager.user.getString('device_id');
    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      StorageManager.user.saveString('device_id', deviceId);
    }
    return deviceId;
  }

  String _getPlatform() {
    // 由各平台覆盖
    return 'ios';
  }
}
