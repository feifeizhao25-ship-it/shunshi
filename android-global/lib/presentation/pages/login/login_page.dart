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
      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data);
    } catch (_) {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
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
      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data);
    } catch (_) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Guest login
  Future<void> _guestLogin() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final response = await client.post('/api/v1/auth/guest-login');
      final data = response.data as Map<String, dynamic>;
      _handleLoginSuccess(data);
    } catch (_) {
      setState(() {
        _errorMessage = 'Guest login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Google login (placeholder)
  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    // TODO: Integrate Google Sign-In SDK
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In coming soon')),
      );
    }
  }

  /// Apple login (placeholder)
  Future<void> _appleLogin() async {
    setState(() => _isLoading = true);
    // TODO: Integrate Sign in with Apple
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple Sign-In coming soon')),
      );
    }
  }

  void _handleLoginSuccess(Map<String, dynamic> data) {
    // Store token if available
    final token = data['token'] as String?;
    if (token != null) {
      // Save token — adjust based on GL storage implementation
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonsColors.background,
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
                    Text('Seasons', style: SeasonsTextStyles.greeting),
                    const SizedBox(height: 4),
                    Text(
                      'Live in harmony with nature',
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
                  hint: 'Full name',
                  prefix: Icons.person_outline,
                ),
                const SizedBox(height: 16),
              ],

              // Email
              _buildInputField(
                controller: _emailController,
                hint: 'Email',
                prefix: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              _buildInputField(
                controller: _passwordController,
                hint: 'Password',
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
                        ? 'Create an account'
                        : 'Already have an account? Sign in',
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
                          _mode == _LoginMode.password ? 'Sign In' : 'Create Account',
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
                      'Or continue with',
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
                    label: 'Google',
                    color: const Color(0xFF4285F4),
                    onTap: _googleLogin,
                  ),
                  const SizedBox(width: 32),
                  _buildSocialButton(
                    icon: Icons.apple,
                    label: 'Apple',
                    color: const Color(0xFF000000),
                    onTap: _appleLogin,
                  ),
                  const SizedBox(width: 32),
                  _buildSocialButton(
                    icon: Icons.person_outline,
                    label: 'Guest',
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
                    'Skip for now',
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
