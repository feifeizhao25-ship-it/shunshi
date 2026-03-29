import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../widgets/components/soft_card.dart';

/// Settings / Privacy Page — SEASONS Global
/// Includes: memory control, data export, delete account, AI disclosure

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _memoryEnabled = true;
  bool _notificationsEnabled = true;
  bool _exportLoading = false;
  // _deleteLoading used for future loading indicator in delete button
  String _userId = 'seasons-user';
  late Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8000',
      connectTimeout: const Duration(seconds: 15),
    ));
    _loadUserId();
    _loadMemoryPreference();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getString('user_id') ?? 'seasons-user';
      });
    } catch (_) {}
  }

  Future<void> _loadMemoryPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('memory_enabled') ?? true;
      setState(() => _memoryEnabled = enabled);
    } catch (_) {}
  }

  Future<void> _saveMemoryPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('memory_enabled', enabled);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeasonsColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
          color: SeasonsColors.textPrimary,
        ),
        title: Text(
          'Settings',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SeasonsSpacing.md),

            // ── AI Disclosure ──
            _buildSectionHeader('About SEASONS'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildDisclosureCard(context),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Memory Control ──
            _buildSectionHeader('Memory'),
            const SizedBox(height: SeasonsSpacing.sm),
            Text(
              'Control what SEASONS remembers about you',
              style: SeasonsTextStyles.caption.copyWith(
                color: SeasonsColors.textTertiary,
              ),
            ),
            const SizedBox(height: SeasonsSpacing.md),
            _buildMemoryToggle(context),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Notifications ──
            _buildSectionHeader('Notifications'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildNotificationToggle(context),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Data ──
            _buildSectionHeader('Your Data'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildDataOptions(context),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── Safety & Support ──
            _buildSectionHeader('Safety & Support'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildSafetyCard(context),
            const SizedBox(height: SeasonsSpacing.xxl),

            // ── About ──
            _buildSectionHeader('About'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildAboutCard(context),
            const SizedBox(height: SeasonsSpacing.xxl),

            const SizedBox(height: SeasonsSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: SeasonsTextStyles.caption.copyWith(
        color: SeasonsColors.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDisclosureCard(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SeasonsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Text(
                  'You are talking to AI',
                  style: SeasonsTextStyles.bodyMedium.copyWith(
                    color: SeasonsColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            'SEASONS uses AI to provide personalized calm lifestyle support. Our AI is not a therapist, doctor, or mental health professional. It is a gentle companion designed to help you unwind, reflect, and find calm.',
            style: SeasonsTextStyles.bodySmall.copyWith(
              color: SeasonsColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          const Divider(height: 1, color: SeasonsColors.border),
          const SizedBox(height: SeasonsSpacing.md),
          _buildDisclosureRow(Icons.medical_services_outlined, 'Not medical advice'),
          const SizedBox(height: SeasonsSpacing.sm),
          _buildDisclosureRow(Icons.psychology_outlined, 'Not therapy'),
          const SizedBox(height: SeasonsSpacing.sm),
          _buildDisclosureRow(Icons.delete_outline, 'You can delete your data'),
          const SizedBox(height: SeasonsSpacing.sm),
          _buildDisclosureRow(Icons.visibility_off_outlined, 'You control memory'),
        ],
      ),
    );
  }

  Widget _buildDisclosureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SeasonsColors.primary),
        const SizedBox(width: SeasonsSpacing.sm),
        Text(
          text,
          style: SeasonsTextStyles.caption.copyWith(
            color: SeasonsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryToggle(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.lg,
        vertical: SeasonsSpacing.md,
      ),
      onTap: () {
        setState(() => _memoryEnabled = !_memoryEnabled);
        _showMemorySnackbar(context, _memoryEnabled);
      },
      child: Row(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: _memoryEnabled
                ? SeasonsColors.primary
                : SeasonsColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                  ),
                ),
                Text(
                  _memoryEnabled
                      ? 'SEASONS remembers your preferences'
                      : 'SEASONS has no memory of past conversations',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: SeasonsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _memoryEnabled,
            onChanged: (v) {
              setState(() => _memoryEnabled = v);
              _showMemorySnackbar(context, v);
            },
            activeColor: SeasonsColors.primary,
          ),
        ],
      ),
    );
  }

  void _showMemorySnackbar(BuildContext context, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Memory enabled — SEASONS will personalize your experience'
              : 'Memory disabled — conversations are not remembered',
        ),
        backgroundColor: SeasonsColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNotificationToggle(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.lg,
        vertical: SeasonsSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: _notificationsEnabled
                ? SeasonsColors.primary
                : SeasonsColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminders',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                  ),
                ),
                Text(
                  _notificationsEnabled
                      ? 'Receive gentle daily nudges'
                      : 'No notifications will be sent',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: SeasonsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
            },
            activeColor: SeasonsColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDataOptions(BuildContext context) {
    return Column(
      children: [
        // Export data
        SoftCard(
          borderRadius: SeasonsSpacing.radiusLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          onTap: () => _requestExport(context),
          child: Row(
            children: [
              Icon(
                Icons.download_outlined,
                color: _exportLoading
                    ? SeasonsColors.textTertiary
                    : SeasonsColors.primary,
                size: 22,
              ),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export My Data',
                      style: SeasonsTextStyles.body.copyWith(
                        color: SeasonsColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Download all your reflections and preferences',
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_exportLoading)
                const Icon(Icons.check, color: SeasonsColors.primary, size: 18)
              else
                const Icon(Icons.chevron_right,
                    color: SeasonsColors.textTertiary, size: 18),
            ],
          ),
        ),
        const SizedBox(height: SeasonsSpacing.sm),

        // Clear memory
        SoftCard(
          borderRadius: SeasonsSpacing.radiusLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          onTap: () => _confirmClearMemory(context),
          child: Row(
            children: [
              Icon(Icons.restart_alt, color: SeasonsColors.warm, size: 22),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear Memory',
                      style: SeasonsTextStyles.body.copyWith(
                        color: SeasonsColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Remove all stored preferences and summaries',
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: SeasonsColors.textTertiary, size: 18),
            ],
          ),
        ),
        const SizedBox(height: SeasonsSpacing.sm),

        // Delete account
        SoftCard(
          borderRadius: SeasonsSpacing.radiusLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          onTap: () => _confirmDeleteAccount(context),
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red.shade300, size: 22),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: SeasonsTextStyles.body.copyWith(
                        color: Colors.red.shade300,
                      ),
                    ),
                    Text(
                      'Permanently remove all your data',
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: SeasonsColors.textTertiary, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      onTap: () => _showSafetyDialog(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SeasonsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🛟', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crisis Support',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'If you are in crisis, please seek real-world support',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: SeasonsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: SeasonsColors.textTertiary, size: 18),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Column(
      children: [
        SoftCard(
          borderRadius: SeasonsSpacing.radiusLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: SeasonsColors.textTertiary, size: 22),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Text(
                  'Privacy Policy',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new,
                  color: SeasonsColors.textTertiary, size: 16),
            ],
          ),
        ),
        const SizedBox(height: SeasonsSpacing.sm),
        SoftCard(
          borderRadius: SeasonsSpacing.radiusLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.article_outlined,
                  color: SeasonsColors.textTertiary, size: 22),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Text(
                  'Terms of Service',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new,
                  color: SeasonsColors.textTertiary, size: 16),
            ],
          ),
        ),
        const SizedBox(height: SeasonsSpacing.sm),
        SoftCard(
          borderRadius: SeasonsSpacing.radiusLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.lg,
            vertical: SeasonsSpacing.md,
          ),
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.help_outline,
                  color: SeasonsColors.textTertiary, size: 22),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Text(
                  'Help & Support',
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: SeasonsColors.textTertiary, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestExport(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonsColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Export your data?',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'We will prepare a JSON file containing all your memories and preferences for download.',
          style: SeasonsTextStyles.bodySmall.copyWith(
            color: SeasonsColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Export',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _exportLoading = true);

    try {
      // Call the export API
      final response = await _dio.get(
        '/api/v1/memory/export',
        queryParameters: {'user_id': _userId},
      );

      final data = response.data as Map<String, dynamic>;
      final exportJson = const JsonEncoder.withIndent('  ').convert(data);

      // Save to temp file and share
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/seasons_data_export.json');
      await file.writeAsString(exportJson);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SEASONS Data Export',
        text: 'Your SEASONS data export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data export ready. Sharing file...'),
            backgroundColor: SeasonsColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export failed. Please try again.'),
            backgroundColor: Colors.red.shade300,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  void _confirmClearMemory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonsColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear all memory?',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove all stored preferences and conversation summaries. You can rebuild them over time.',
          style: SeasonsTextStyles.bodySmall.copyWith(
            color: SeasonsColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Call the backend API to clear memories
              try {
                await _dio.post(
                  '/api/v1/memory/clear',
                  data: {'user_id': _userId},
                );
              } catch (_) {
                // Continue even if API fails — clear locally
              }
              _setMemoryEnabled(false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Memory cleared'),
                    backgroundColor: SeasonsColors.surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text(
              'Clear',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.warm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonsColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete your account?',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: Colors.red.shade300,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete all your data including reflections, preferences, and subscription. This action cannot be undone.',
          style: SeasonsTextStyles.bodySmall.copyWith(
            color: SeasonsColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _performAccountDeletion(context);
            },
            child: Text(
              'Delete',
              style: SeasonsTextStyles.body.copyWith(
                color: Colors.red.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(BuildContext context) async {

    try {
      // Call the backend API to delete user account
      await _dio.delete(
        '/api/v1/users/$_userId',
        queryParameters: {'confirm': true},
      );

      // Clear all local data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted. Sorry to see you go.'),
            backgroundColor: SeasonsColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Navigate to login/onboarding
        context.go('/onboarding');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red.shade300,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
    }
  }

  void _showSafetyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonsColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'If you are in crisis',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEASONS is not a crisis service. If you are experiencing a mental health emergency, please:',
              style: SeasonsTextStyles.bodySmall.copyWith(
                color: SeasonsColors.textSecondary,
              ),
            ),
            const SizedBox(height: SeasonsSpacing.md),
            _buildCrisisRow('🇺🇸 US', '988 Suicide & Crisis Lifeline — call or text 988'),
            const SizedBox(height: SeasonsSpacing.sm),
            _buildCrisisRow('🇬🇧 UK', 'Samaritans — call 116 123'),
            const SizedBox(height: SeasonsSpacing.sm),
            _buildCrisisRow('🌍 International', 'findahelpline.com'),
            const SizedBox(height: SeasonsSpacing.md),
            Text(
              'If you are in immediate danger, contact your local emergency services.',
              style: SeasonsTextStyles.caption.copyWith(
                color: SeasonsColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisRow(String flag, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(flag, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: SeasonsTextStyles.caption.copyWith(
              color: SeasonsColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _setMemoryEnabled(bool enabled) {
    setState(() => _memoryEnabled = enabled);
    _saveMemoryPreference(enabled);

    // When turning memory OFF, also call the backend API to clear all memories
    if (!enabled) {
      _clearMemoriesOnBackend();
    }
  }

  Future<void> _clearMemoriesOnBackend() async {
    try {
      await _dio.post(
        '/api/v1/memory/clear',
        data: {'user_id': _userId},
      );
    } catch (_) {
      // Silently fail — local state already updated
    }
  }
}
