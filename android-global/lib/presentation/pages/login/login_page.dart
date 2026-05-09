// lib/presentation/pages/login/login_page.dart
//
// Seasons login page — email + password / Google / Apple / guest
// Design: SeasonsColors (calm blue, light gray), generous whitespace, soft inputs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../data/storage/storage_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_localizations.dart';

/// Login mode
enum _LoginMode { password, register }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _LoginMode _mode = _LoginMode.password;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Password login
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password');
      // i18n note: error messages set via string are replaced in build()
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final client = ApiClient();
      final response = await client.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      final respData = response.data;
      // Backend returns {success: true, data: {user, token, refresh_token, ...}}
      final data = respData is Map && respData['data'] != null
          ? respData['data'] as Map<String, dynamic>
          : respData as Map<String, dynamic>;
      await _handleLoginSuccess(data);
    } on DioException catch (e) {
      final msg = _dioErrorMessage(e);
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Register
  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final client = ApiClient();
      final response = await client.post('/api/v1/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      final respData = response.data;
      final data = respData is Map && respData['data'] != null
          ? respData['data'] as Map<String, dynamic>
          : respData as Map<String, dynamic>;
      await _handleLoginSuccess(data);
    } on DioException catch (e) {
      final msg = _dioErrorMessage(e);
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Guest login
  Future<void> _guestLogin() async {
    setState(() => _isLoading = true);
    _errorMessage = null;
    try {
      final client = ApiClient();
      final response = await client.post('/api/v1/auth/guest-login', data: {
        'platform': 'android',
      });
      final respData = response.data;
      final data = respData is Map && respData['data'] != null
          ? respData['data'] as Map<String, dynamic>
          : respData as Map<String, dynamic>;
      await _handleLoginSuccess(data);
    } on DioException catch (e) {
      final msg = _dioErrorMessage(e);
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Guest login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Google login - POST /api/v1/auth/google
  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Add google_sign_in package + google-services.json
      // final googleUser = await GoogleSignIn().signIn();
      // final auth = await googleUser?.authentication;
      // final res = await Dio().post('${ApiClient.baseUrl}/api/v1/auth/google',
      //   data: {'id_token': auth?.idToken});
      // await _handleLoginSuccess(res.data['data']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('login_google_signin_requires_sdk_setup'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google login failed: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  /// Apple login - POST /api/v1/auth/apple
  Future<void> _appleLogin() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Add sign_in_with_apple package + Apple Developer cert
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [Scope.email, Scope.fullName]);
      // final res = await Dio().post('${ApiClient.baseUrl}/api/v1/auth/apple',
      //   data: {'identity_token': credential.identityToken});
      // await _handleLoginSuccess(res.data['data']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('login_apple_signin_requires_apple_developer'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple login failed: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  /// Handle successful login — persist tokens and user info to StorageManager
  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    // Extract token (backend may return 'token' or 'access_token')
    final token = (data['token'] ?? data['access_token']) as String?;
    final refreshToken = (data['refresh_token']) as String?;
    final user = data['user'] as Map<String, dynamic>?;

    if (token != null) {
      await StorageManager.user.saveToken(token);
    }
    if (refreshToken != null) {
      await StorageManager.user.saveRefreshToken(refreshToken);
    }
    if (user != null) {
      await StorageManager.user.saveUserInfo(user);
      // Persist user_id for providers that read it from SharedPreferences
      final prefs = StorageManager.user;
      // Store user_id in SharedPreferences for other providers
      final userId = user['id'] as String?;
      if (userId != null) {
        final sp = await SharedPreferences.getInstance();
        await sp.setString('user_id', userId);
      }
    }
    await StorageManager.user.setLoggedIn(true);

    if (!mounted) return;
    context.go('/home');
  }

  String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Network timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network connection failed. Please check your internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) return 'Wrong email or password.';
        if (statusCode == 409) return 'Email already registered.';
        if (statusCode == 422) return 'Please check your input.';
        return 'Server error ($statusCode). Please try later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? SeasonsDarkColors.background : SeasonsColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Brand
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: SeasonsColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(Icons.nature_people, size: 36, color: SeasonsColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).t('login_brand'), style: SeasonsTextStyles.greeting),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).t('login_subtitle'),
                      style: SeasonsTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Error
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SeasonsColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Name field (register mode)
              if (_mode == _LoginMode.register) ...[
                _buildInputField(
                  controller: _nameController,
                  hint: AppLocalizations.of(context).t('login_full_name'),
                  prefix: Icons.person_outline,
                ),
                const SizedBox(height: 16),
              ],

              // Email
              _buildInputField(
                controller: _emailController,
                hint: AppLocalizations.of(context).t('login_email'),
                prefix: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              _buildInputField(
                controller: _passwordController,
                hint: AppLocalizations.of(context).t('login_password'),
                prefix: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 8),

              // Switch mode
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _mode = _mode == _LoginMode.password
                          ? _LoginMode.register
                          : _LoginMode.password;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _mode == _LoginMode.password
                        ? AppLocalizations.of(context).t('login_create_account')
                        : AppLocalizations.of(context).t('login_has_account'),
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login / Register button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_mode == _LoginMode.password ? _login : _register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SeasonsColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: SeasonsColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _mode == _LoginMode.password ? AppLocalizations.of(context).t('login_sign_in') : AppLocalizations.of(context).t('register_title'),
                          style: SeasonsTextStyles.button,
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: SeasonsColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context).t('login_or_continue_with'),
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.textHint,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: SeasonsColors.divider)),
                ],
              ),

              const SizedBox(height: 28),

              // Social login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: Icons.g_mobiledata,
                    label: AppLocalizations.of(context).t('login_google_1'),
                    color: const Color(0xFF4285F4),
                    onTap: _googleLogin,
                  ),
                  const SizedBox(width: 32),
                  _buildSocialButton(
                    icon: Icons.apple,
                    label: AppLocalizations.of(context).t('login_apple_1'),
                    color: const Color(0xFF000000),
                    onTap: _appleLogin,
                  ),
                  const SizedBox(width: 32),
                  _buildSocialButton(
                    icon: Icons.person_outline,
                    label: AppLocalizations.of(context).t('login_guest_1'),
                    color: SeasonsColors.textSecondary,
                    onTap: _guestLogin,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Skip
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    AppLocalizations.of(context).t('login_skip'),
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.textHint,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: SeasonsColors.surfaceDim,
        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
        border: Border.all(color: SeasonsColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: SeasonsTextStyles.body.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: SeasonsTextStyles.caption.copyWith(
            color: SeasonsColors.textHint,
          ),
          prefixIcon: Icon(prefix, color: SeasonsColors.textHint, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: SeasonsTextStyles.caption),
        ],
      ),
    );
  }
}
