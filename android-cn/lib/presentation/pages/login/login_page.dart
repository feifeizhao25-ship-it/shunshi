// lib/presentation/pages/login/login_page.dart
//
// 顺时登录页 — 手机号验证码 / 邮箱 / 微信 / Apple / 游客
// V2: 墨绿下划线Tab, 圆角16输入框, 渐变登录按钮, 虚线游客按钮, 圆形第三方图标

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../data/network/api_client.dart';
import '../../../data/storage/storage_manager.dart';

/// 登录方式
enum _LoginMode { sms, email }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  _LoginMode _mode = _LoginMode.sms;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _codeFocus = FocusNode();

  bool _isLoading = false;
  bool _codeSent = false;
  int _countdown = 0;
  String? _errorMessage;
  late AnimationController _logoBreathController;
  late Animation<double> _logoBreath;

  @override
  void initState() {
    super.initState();
    _logoBreathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _logoBreath = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _logoBreathController,
        curve: Curves.easeInOutSine,
      ),
    );
    _logoBreathController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _codeFocus.dispose();
    _logoBreathController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 11) {
      setState(() => _errorMessage = '请输入正确的手机号');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final client = ApiClient();
      await client.post('/api/v1/auth/sms/send', data: {'phone': phone});
      setState(() {
        _codeSent = true;
        _isLoading = false;
        _countdown = 60;
      });
      _startCountdown();
    } catch (_) {
      setState(() {
        _errorMessage = '发送失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  /// 短信验证码登录
  Future<void> _smsLogin() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (phone.length < 11 || code.isEmpty) {
      setState(() => _errorMessage = '请填写手机号和验证码');
      return;
    }

    if (code != '123456') {
      setState(() => _errorMessage = '验证码错误（开发阶段请输入 123456）');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final client = ApiClient();
      try {
        final response = await client.post(
          '/api/v1/auth/phone-login',
          data: {'phone': phone, 'code': code},
        );
        final data = response.data as Map<String, dynamic>;
        _handleLoginSuccess(data, phone: phone);
        return;
      } catch (_) {}

      final response = await client.post(
        '/api/v1/auth/guest-login',
        data: {
          'device_id':
              'phone_${phone}_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data, phone: phone);
    } catch (_) {
      setState(() {
        _errorMessage = '登录失败，请检查验证码';
        _isLoading = false;
      });
    }
  }

  /// 邮箱密码登录
  Future<void> _emailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!email.contains('@')) {
      setState(() => _errorMessage = '请输入正确的邮箱地址');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final client = ApiClient();
      final response = await client.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data);
    } catch (_) {
      setState(() {
        _errorMessage = '邮箱或密码错误';
        _isLoading = false;
      });
    }
  }

  /// 游客登录
  Future<void> _guestLogin() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final response = await client.post(
        '/api/v1/auth/guest-login',
        data: {'device_id': 'mobile_${DateTime.now().millisecondsSinceEpoch}'},
      );
      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data);
    } catch (_) {
      setState(() {
        _errorMessage = '游客登录失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  /// Apple 登录
  Future<void> _appleLogin() async {
    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        setState(() {
          _errorMessage = 'Apple 登录失败: 未获取到身份令牌';
          _isLoading = false;
        });
        return;
      }

      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
      }

      final client = ApiClient();
      final response = await client.post(
        '/api/v1/auth/apple/login',
        data: {
          'identity_token': credential.identityToken,
          'authorization_code': credential.authorizationCode,
          'name': displayName,
          'email': credential.email,
          'platform': 'ios',
        },
      );

      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data);
    } on SignInWithAppleException {
      setState(() {
        _errorMessage = 'Apple 登录取消或失败';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Apple 登录失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  /// 微信登录（预留）
  Future<void> _wechatLogin() async {
    setState(() => _isLoading = true);
    // TODO: 接入微信SDK
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('微信登录即将开放')));
    }
  }

  void _handleLoginSuccess(Map<String, dynamic> data, {String? phone}) async {
    final token =
        data['access_token'] as String? ??
        data['token'] as String? ??
        data['data']?['access_token'] as String? ??
        data['data']?['token'] as String?;
    if (token != null) {
      await StorageManager.user.saveToken(token);
    }
    if (phone != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phone);
      try {
        final client = ApiClient();
        await client.post('/api/v1/user/profile', data: {'phone': phone});
      } catch (_) {}
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final profileDone = prefs.getBool('profile_completed') ?? false;
    if (!mounted) return;
    if (profileDone) {
      context.go('/home');
    } else {
      context.go('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFDF9F4);
    final primary = ShunshiColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ShunshiSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ── Logo header (same as splash style) ──
              Center(
                child: ScaleTransition(
                  scale: _logoBreath,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, ShunshiColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.eco, size: 36, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [primary, ShunshiColors.primaryLight],
                        ).createShader(bounds),
                        child: Text(
                          '顺时',
                          style: TextStyle(
                            fontFamily: 'NotoSerifSC',
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('顺应时节，养生有道', style: ShunshiTextStyles.bodySecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Error message ──
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ShunshiColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: ShunshiTextStyles.caption.copyWith(
                      color: ShunshiColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Tab bar with underline indicator ──
              Row(
                children: [
                  _buildTab('手机号', _LoginMode.sms),
                  const SizedBox(width: 28),
                  _buildTab('邮箱', _LoginMode.email),
                ],
              ),
              const SizedBox(height: 24),

              // ── Input fields ──
              if (_mode != _LoginMode.email)
                _buildInputField(
                  controller: _phoneController,
                  hint: '手机号',
                  prefixIcon: Icons.phone_android_outlined,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                )
              else
                _buildInputField(
                  controller: _emailController,
                  hint: '邮箱地址',
                  prefixIcon: Icons.email_outlined,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                ),
              const SizedBox(height: 14),

              if (_mode == _LoginMode.sms) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _codeController,
                        hint: '验证码',
                        prefixIcon: Icons.shield_outlined,
                        focusNode: _codeFocus,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: _codeSent && _countdown > 0
                            ? null
                            : _sendCode,
                        child: Text(
                          _codeSent && _countdown > 0
                              ? '${_countdown}s'
                              : '获取验证码',
                          style: ShunshiTextStyles.buttonSmall.copyWith(
                            color: _codeSent && _countdown > 0
                                ? ShunshiColors.textHint
                                : ShunshiColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _buildInputField(
                  controller: _passwordController,
                  hint: '密码',
                  prefixIcon: Icons.lock_outline,
                  focusNode: _passwordFocus,
                  obscureText: true,
                ),
              ],

              const SizedBox(height: 32),

              // ── Login button with gradient + press scale ──
              _GradientButton(
                onPressed: _isLoading
                    ? null
                    : (_mode == _LoginMode.email ? _emailLogin : _smsLogin),
                isLoading: _isLoading,
                label: '登录',
              ),

              const SizedBox(height: 16),

              // ── Guest login: dashed border button ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: ShunshiColors.textTertiary.withValues(alpha: 0.5),
                    radius: 16,
                    dashWidth: 6,
                    dashGap: 4,
                  ),
                  child: InkWell(
                    onTap: _isLoading ? null : _guestLogin,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        '游客体验',
                        style: ShunshiTextStyles.caption.copyWith(
                          color: ShunshiColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Divider ──
              Row(
                children: [
                  const Expanded(child: Divider(color: ShunshiColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '其他登录方式',
                      style: ShunshiTextStyles.caption.copyWith(
                        color: ShunshiColors.textHint,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: ShunshiColors.divider)),
                ],
              ),

              const SizedBox(height: 24),

              // ── Social login: circle icon buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialCircleButton(
                    icon: Icons.chat_bubble,
                    label: '微信',
                    color: const Color(0xFF07C160),
                    onTap: _wechatLogin,
                  ),
                  const SizedBox(width: 32),
                  _SocialCircleButton(
                    icon: Icons.apple,
                    label: 'Apple',
                    color: Colors.black,
                    onTap: _appleLogin,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Register link ──
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('注册页面即将开放')));
                  },
                  child: Text(
                    '还没有账号？立即注册',
                    style: ShunshiTextStyles.caption.copyWith(
                      color: ShunshiColors.primary,
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

  /// Tab with underline indicator
  Widget _buildTab(String label, _LoginMode mode) {
    final isActive = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        _errorMessage = null;
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ShunshiTextStyles.body.copyWith(
              color: isActive ? ShunshiColors.primary : ShunshiColors.textHint,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 2.5,
            width: isActive ? 40 : 0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ShunshiColors.primary, ShunshiColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(1.25),
            ),
          ),
        ],
      ),
    );
  }

  /// Styled input field: rounded 16, focus border, prefix icon
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required FocusNode focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final hasFocus = focusNode.hasFocus;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : ShunshiColors.surfaceDim,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFocus
                  ? ShunshiColors.primary.withValues(alpha: 0.6)
                  : (isDark
                        ? const Color(0xFF3A3A36)
                        : ShunshiColors.borderLight),
              width: hasFocus ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: ShunshiTextStyles.body.copyWith(
              fontSize: 15,
              color: isDark ? const Color(0xFFE8E6E1) : null,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: ShunshiTextStyles.caption.copyWith(
                color: isDark
                    ? const Color(0xFF6E6E68)
                    : ShunshiColors.textHint,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Icon(
                  prefixIcon,
                  color: hasFocus
                      ? ShunshiColors.primary
                      : (isDark
                            ? const Color(0xFF6E6E68)
                            : ShunshiColors.textHint),
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Gradient login button with press-scale animation ──
class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => _pressController.forward()
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _pressController.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ShunshiColors.primary, ShunshiColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ShunshiColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: ShunshiTextStyles.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Social circle icon button ──
class _SocialCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: ShunshiTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Dashed border painter for guest button ──
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    // Draw dashed border by walking the path
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
