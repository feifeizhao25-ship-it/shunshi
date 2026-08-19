import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/safety/system_notice_messages.dart';
import '../../data/models/user_context.dart';
import '../../design_system/design_system.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';

class MeSettingsPage extends ConsumerWidget {
  const MeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final isPremium = subAsync.value?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: '我的'),
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: AppText.bodyMedium('加载失败，请重启应用。'),
        ),
        data: (user) => _buildContent(context, ref, user, isPremium),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UserContext user,
    bool isPremium,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscription status
          if (isPremium)
            AppCard.elevated(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
              child: Row(
                children: const [
                  Icon(Icons.favorite_rounded,
                      color: AppColors.secondary, size: 20),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleLarge('连续照护已开启'),
                        AppText.bodySmall('你正在享受完整的陪伴支持'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            AppCard.outlined(
              onTap: () => context.push('/subscribe'),
              child: Row(
                children: const [
                  Icon(Icons.favorite_border_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleLarge('了解连续照护'),
                        AppText.bodySmall('持续的陪伴，从这里开始'),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),

          // Memory settings section
          const AppText.titleMedium('记忆与隐私',
              color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),

          AppCard.elevated(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingSwitch(
                  title: '记忆功能',
                  subtitle: '记住重要内容，帮助我更好地陪伴你',
                  value: user.memoryEnabled,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).setMemoryEnabled(v);
                    _showSnack(
                      context,
                      v
                          ? SystemNoticeMessages.memoryEnabled
                          : SystemNoticeMessages.memoryDisabled,
                    );
                  },
                ),
                const Divider(height: 0),
                _SettingTile(
                  title: '清空记忆',
                  subtitle: '删除所有记录的对话内容',
                  icon: Icons.delete_sweep_outlined,
                  iconColor: AppColors.error,
                  onTap: () => _confirmClearMemory(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Care preferences
          const AppText.titleMedium('关怀设置', color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),

          AppCard.elevated(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingSwitch(
                  title: '主动关怀',
                  subtitle: '允许顺时在合适的时间主动问候',
                  value: user.proactiveEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setProactiveEnabled(v),
                ),
                const Divider(height: 0),
                _SettingTile(
                  title: '静默时间',
                  subtitle:
                      '${user.quietHours.start} - ${user.quietHours.end}',
                  icon: Icons.bedtime_outlined,
                  onTap: () => _editQuietHours(context, ref, user.quietHours),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Boundary explanation
          AppCard.filled(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 16, color: AppColors.textSecondary),
                    SizedBox(width: AppSpacing.xs),
                    AppText.labelMedium('关于边界',
                        color: AppColors.textSecondary),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                AppText.bodySmall(
                  '顺时是你的生活陪伴，不是医疗服务。遇到需要专业帮助的情况，我会建议你寻找合适的支持。',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmClearMemory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空记忆'),
        content:
            const Text('这将删除顺时记住的所有内容，无法恢复。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(chatProvider.notifier).clearMemory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(SystemNoticeMessages.memoryCleared),
          ),
        );
      }
    }
  }

  Future<void> _editQuietHours(
    BuildContext context,
    WidgetRef ref,
    QuietHours current,
  ) async {
    await AppSheet.show(
      context: context,
      title: '静默时间',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard.filled(
              child: const AppText.bodyMedium(
                '在静默时间内，顺时不会主动推送关怀消息。你随时都可以来聊天。',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _TimeRow(
              label: '开始',
              time: current.start,
            ),
            const SizedBox(height: AppSpacing.md),
            _TimeRow(
              label: '结束',
              time: current.end,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton.primary(
              label: '确认',
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(title),
                if (subtitle != null)
                  AppText.bodySmall(subtitle!),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium(title),
                  if (subtitle != null) AppText.bodySmall(subtitle!),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String time;

  const _TimeRow({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText.titleMedium(label),
        const Spacer(),
        AppCard.outlined(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppText.titleLarge(time, color: AppColors.primary),
        ),
      ],
    );
  }
}
