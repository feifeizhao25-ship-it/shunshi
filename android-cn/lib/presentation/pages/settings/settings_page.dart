import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../data/network/api_client.dart';

/// 顺时 — 设置页面
///
/// 从个人中心拆分出的独立设置页面，涵盖：
/// - 通知设置（推送开关、时段、偏好）
/// - 免打扰时间
/// - 隐私设置（AI记忆、导出数据、清除记忆、重置聊天）
/// - 账户管理（注销）
/// - 关于（版本号、协议、隐私政策）
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── 通知设置 ──
  bool _pushEnabled = true;
  final Map<String, bool> _timeSlots = {
    'morning': true,    // 早上
    'noon': true,       // 中午
    'afternoon': true,  // 下午
    'evening': true,    // 晚上
    'night': false,     // 夜间
  };
  final Map<String, bool> _preferences = {
    'wellness_tips': true,    // 养生建议
    'solar_reminder': true,   // 节气提醒
    'follow_up': false,       // 跟进关怀
  };

  // ── 免打扰 ──
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  // ── 隐私 ──
  bool _aiMemoryEnabled = true;

  // ── 半球 ──
  String _hemisphere = 'north';

  // ── loading states ──
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  // ==================== 数据加载 ====================

  Future<void> _loadAllSettings() async {
    final client = ApiClient();
    await Future.wait([
      _loadNotificationSettings(client),
      _loadQuietHours(client),
      _loadMemorySettings(client),
    ]);
    _loadHemisphere();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHemisphere() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _hemisphere = prefs.getString('hemisphere') ?? 'north');
  }

  Future<void> _setHemisphere(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hemisphere', value);
    if (mounted) {
      setState(() => _hemisphere = value);
      context.go('/home');
    }
  }

  void _showHemisphereSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _textHint(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('选择所在半球', style: ShunshiTextStyles.heading.copyWith(color: _textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              '影响首页显示的季节内容',
              style: ShunshiTextStyles.caption.copyWith(color: _textHint(context)),
            ),
            const SizedBox(height: 20),
            _buildHemisphereOption(
              context,
              label: '北半球',
              desc: '北美、欧洲、亚洲（北部）',
              isSelected: _hemisphere == 'north',
              onTap: () { Navigator.pop(ctx); _setHemisphere('north'); },
            ),
            const SizedBox(height: 12),
            _buildHemisphereOption(
              context,
              label: '南半球',
              desc: '南美、澳大利亚、非洲（南部）',
              isSelected: _hemisphere == 'south',
              onTap: () { Navigator.pop(ctx); _setHemisphere('south'); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHemisphereOption(BuildContext context, {
    required String label,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = ShunshiColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primary : _textSecondary(context),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ShunshiTextStyles.body.copyWith(color: _textPrimary(context), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(desc, style: ShunshiTextStyles.caption.copyWith(color: _textSecondary(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotificationSettings(ApiClient client) async {
    try {
      final resp = await client.get('/api/v1/notifications/settings');
      if (resp.statusCode == 200 && resp.data != null) {
        final d = resp.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _pushEnabled = d['push_enabled'] as bool? ?? _pushEnabled;
            final slots = d['time_slots'] as Map<String, dynamic>?;
            if (slots != null) {
              slots.forEach((key, value) {
                if (_timeSlots.containsKey(key)) {
                  _timeSlots[key] = value as bool? ?? _timeSlots[key]!;
                }
              });
            }
            final prefs = d['preferences'] as Map<String, dynamic>?;
            if (prefs != null) {
              prefs.forEach((key, value) {
                if (_preferences.containsKey(key)) {
                  _preferences[key] = value as bool? ?? _preferences[key]!;
                }
              });
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadQuietHours(ApiClient client) async {
    try {
      final resp = await client.get('/api/v1/settings/quiet-hours');
      if (resp.statusCode == 200 && resp.data != null) {
        final d = resp.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _quietHoursEnabled = d['enabled'] as bool? ?? _quietHoursEnabled;
            final startStr = d['start_time'] as String?;
            final endStr = d['end_time'] as String?;
            if (startStr != null) {
              _quietStart = _parseTimeOfDay(startStr);
            }
            if (endStr != null) {
              _quietEnd = _parseTimeOfDay(endStr);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMemorySettings(ApiClient client) async {
    try {
      final resp = await client.get('/api/v1/settings/memory');
      if (resp.statusCode == 200 && resp.data != null) {
        final d = resp.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _aiMemoryEnabled = d['enabled'] as bool? ?? _aiMemoryEnabled;
          });
        }
      }
    } catch (_) {}
  }

  // ==================== 数据保存 ====================

  Future<void> _saveNotificationSettings() async {
    try {
      final client = ApiClient();
      await client.post(
        '/api/v1/notifications/settings',
        data: {
          'push_enabled': _pushEnabled,
          'time_slots': Map<String, dynamic>.from(_timeSlots),
          'preferences': Map<String, dynamic>.from(_preferences),
        },
      );
    } catch (_) {}
  }

  Future<void> _saveQuietHours() async {
    try {
      final client = ApiClient();
      await client.post(
        '/api/v1/settings/quiet-hours',
        data: {
          'enabled': _quietHoursEnabled,
          'start_time': _formatTimeOfDay(_quietStart),
          'end_time': _formatTimeOfDay(_quietEnd),
        },
      );
    } catch (_) {}
  }

  Future<void> _toggleAiMemory(bool value) async {
    setState(() => _aiMemoryEnabled = value);
    try {
      final client = ApiClient();
      await client.post(
        '/api/v1/settings/memory',
        data: {'enabled': value},
      );
    } catch (_) {
      if (mounted) setState(() => _aiMemoryEnabled = !value);
    }
  }

  // ==================== 操作 ====================

  Future<void> _exportData() async {
    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final resp = await client.post('/api/v1/auth/data/export');
      if (mounted) {
        final success = resp.statusCode == 200 || resp.statusCode == 201;
        _showSnackBar(success ? '数据导出请求已发送' : '导出失败，请稍后重试');
      }
    } catch (_) {
      if (mounted) _showSnackBar('网络错误，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearAiMemory() async {
    final confirmed = await _showConfirmDialog(
      title: '清除AI记忆',
      message: '确定要清除所有AI记忆吗？此操作不可撤销，AI将无法回忆之前的对话内容。',
      confirmText: '清除',
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      await client.delete('/api/v1/memory/all');
      if (mounted) _showSnackBar('AI记忆已清除');
    } catch (_) {
      if (mounted) _showSnackBar('清除失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetChatHistory() async {
    final confirmed = await _showConfirmDialog(
      title: '重置聊天记录',
      message: '确定要清除所有聊天记录吗？此操作不可撤销。',
      confirmText: '重置',
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      await client.delete('/api/v1/conversations');
      if (mounted) _showSnackBar('聊天记录已重置');
    } catch (_) {
      if (mounted) _showSnackBar('重置失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title: '注销账户',
      message: '注销后，您的所有数据将被永久删除，且无法恢复。确定要继续吗？',
      confirmText: '注销',
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      // 先取消可能存在的待删除状态，再执行删除
      await client.post('/api/v1/auth/account/cancel-delete');
      await client.delete('/api/v1/auth/account');
      if (mounted) _showSnackBar('账户已注销');
    } catch (_) {
      if (mounted) _showSnackBar('注销失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== 工具方法 ====================

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _displayTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? '上午' : '下午';
    return '$period ${h.toString()}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title, style: ShunshiTextStyles.heading),
        content: Text(
          message,
          style: ShunshiTextStyles.bodySecondary.copyWith(
            color: _textSecondary(ctx),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: ShunshiTextStyles.button.copyWith(
                color: _textSecondary(ctx),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmText,
              style: ShunshiTextStyles.button.copyWith(
                color: isDestructive ? _error(ctx) : ShunshiColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Theme helpers ====================

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.background : ShunshiColors.background;

  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;

  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;

  Color _textHint(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textHint : ShunshiColors.textHint;

  Color _divider(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.divider : ShunshiColors.divider;

  Color _surface(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surface : ShunshiColors.surface;

  Color _error(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.error : ShunshiColors.error;

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: _textPrimary(context)),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          '设置',
          style: ShunshiTextStyles.heading.copyWith(
            fontSize: 18,
            color: _textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ShunshiColors.primary,
                strokeWidth: 2,
              ),
            )
          : AbsorbPointer(
              absorbing: _isSaving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShunshiSpacing.pagePadding,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── 1. 通知设置 ──
                    _buildNotificationSection(context),
                    const SizedBox(height: 12),

                    // ── 2. 免打扰时间 ──
                    _buildQuietHoursSection(context),
                    const SizedBox(height: 12),

                    // ── 3. 隐私设置 ──
                    _buildPrivacySection(context),
                    const SizedBox(height: 12),

                    // ── 4. 账户管理 ──
                    _buildAccountSection(context),
                    const SizedBox(height: 12),

                    // ── 5. 关于 ──
                    _buildAboutSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    ),
    );
  }

  // ==================== 1. 通知设置 ====================

  Widget _buildNotificationSection(BuildContext context) {
    return _buildSectionCard(
      context,
      emoji: '🔔',
      title: '通知设置',
      children: [
        // 推送通知总开关
        _buildSwitchTile(
          context,
          label: '推送通知',
          value: _pushEnabled,
          onChanged: (v) {
            setState(() => _pushEnabled = v);
            _saveNotificationSettings();
          },
        ),
        if (_pushEnabled) ...[
          _buildDivider(context),
          // 时段开关
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '推送时段',
                style: ShunshiTextStyles.caption.copyWith(
                  color: _textSecondary(context),
                ),
              ),
            ),
          ),
          _buildTimeSlotTile(
            context,
            label: '早上',
            sublabel: '6:00 - 9:00',
            value: _timeSlots['morning']!,
            key: 'morning',
          ),
          _buildDivider(context, indent: 40),
          _buildTimeSlotTile(
            context,
            label: '中午',
            sublabel: '11:00 - 13:00',
            value: _timeSlots['noon']!,
            key: 'noon',
          ),
          _buildDivider(context, indent: 40),
          _buildTimeSlotTile(
            context,
            label: '下午',
            sublabel: '14:00 - 17:00',
            value: _timeSlots['afternoon']!,
            key: 'afternoon',
          ),
          _buildDivider(context, indent: 40),
          _buildTimeSlotTile(
            context,
            label: '晚上',
            sublabel: '18:00 - 21:00',
            value: _timeSlots['evening']!,
            key: 'evening',
          ),
          _buildDivider(context, indent: 40),
          _buildTimeSlotTile(
            context,
            label: '夜间',
            sublabel: '21:00 - 6:00',
            value: _timeSlots['night']!,
            key: 'night',
          ),
          _buildDivider(context),
          // 偏好选择
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '推送偏好',
                style: ShunshiTextStyles.caption.copyWith(
                  color: _textSecondary(context),
                ),
              ),
            ),
          ),
          _buildPreferenceTile(
            context,
            label: '养生建议',
            value: _preferences['wellness_tips']!,
            key: 'wellness_tips',
          ),
          _buildDivider(context, indent: 40),
          _buildPreferenceTile(
            context,
            label: '节气提醒',
            value: _preferences['solar_reminder']!,
            key: 'solar_reminder',
          ),
          _buildDivider(context, indent: 40),
          _buildPreferenceTile(
            context,
            label: '跟进关怀',
            value: _preferences['follow_up']!,
            key: 'follow_up',
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSlotTile(
    BuildContext context, {
    required String label,
    required String sublabel,
    required bool value,
    required String key,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ShunshiTextStyles.body.copyWith(fontSize: 15, height: 1.3, color: _textPrimary(context))),
                Text(sublabel, style: ShunshiTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: ShunshiColors.primary.withValues(alpha: 0.4),
            activeThumbColor: ShunshiColors.primary,
            onChanged: (v) {
              setState(() => _timeSlots[key] = v);
              _saveNotificationSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context, {
    required String label,
    required bool value,
    required String key,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: ShunshiTextStyles.body.copyWith(fontSize: 15, height: 1.3, color: _textPrimary(context))),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: ShunshiColors.primary.withValues(alpha: 0.4),
            activeThumbColor: ShunshiColors.primary,
            onChanged: (v) {
              setState(() => _preferences[key] = v);
              _saveNotificationSettings();
            },
          ),
        ],
      ),
    );
  }

  // ==================== 2. 免打扰时间 ====================

  Widget _buildQuietHoursSection(BuildContext context) {
    return _buildSectionCard(
      context,
      emoji: '🌙',
      title: '免打扰时间',
      children: [
        _buildSwitchTile(
          context,
          label: '开启免打扰',
          value: _quietHoursEnabled,
          onChanged: (v) {
            setState(() => _quietHoursEnabled = v);
            _saveQuietHours();
          },
        ),
        if (_quietHoursEnabled) ...[
          _buildDivider(context),
          _buildTimePickerTile(
            context,
            label: '开始时间',
            time: _quietStart,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _quietStart,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _quietStart = picked);
                _saveQuietHours();
              }
            },
          ),
          _buildDivider(context),
          _buildTimePickerTile(
            context,
            label: '结束时间',
            time: _quietEnd,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _quietEnd,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _quietEnd = picked);
                _saveQuietHours();
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTimePickerTile(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ShunshiTextStyles.body.copyWith(
                  fontSize: 15,
                  height: 1.3,
                  color: _textPrimary(context),
                ),
              ),
            ),
            Text(
              _displayTime(time),
              style: ShunshiTextStyles.body.copyWith(
                fontSize: 15,
                color: ShunshiColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: _textHint(context), size: 20),
          ],
        ),
      ),
    );
  }

  // ==================== 3. 隐私设置 ====================

  Widget _buildPrivacySection(BuildContext context) {
    return _buildSectionCard(
      context,
      emoji: '🔒',
      title: '隐私设置',
      children: [
        _buildSwitchTile(
          context,
          label: 'AI记忆',
          sublabel: '允许AI记住对话内容以提供个性化建议',
          value: _aiMemoryEnabled,
          onChanged: (v) => _toggleAiMemory(v),
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '所在半球',
          value: _hemisphere == 'north' ? '北半球' : '南半球',
          onTap: () => _showHemisphereSheet(context),
          icon: Icons.public,
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '导出我的数据',
          onTap: _isSaving ? null : _exportData,
          icon: Icons.download_outlined,
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '清除AI记忆',
          onTap: _isSaving ? null : _clearAiMemory,
          icon: Icons.delete_outline,
          isDanger: true,
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '重置聊天记录',
          onTap: _isSaving ? null : _resetChatHistory,
          icon: Icons.chat_bubble_outline,
          isDanger: true,
        ),
      ],
    );
  }

  // ==================== 4. 账户管理 ====================

  Widget _buildAccountSection(BuildContext context) {
    return _buildSectionCard(
      context,
      emoji: '👤',
      title: '账户管理',
      children: [
        _buildActionTile(
          context,
          label: '注销账户',
          onTap: _isSaving ? null : _deleteAccount,
          icon: Icons.person_remove_outlined,
          isDanger: true,
        ),
      ],
    );
  }

  // ==================== 5. 关于 ====================

  Widget _buildAboutSection(BuildContext context) {
    return _buildSectionCard(
      context,
      emoji: 'ℹ️',
      title: '关于',
      children: [
        _buildInfoTile(
          context,
          label: '版本',
          value: 'v1.0.0',
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '用户协议',
          onTap: () {},
          icon: Icons.description_outlined,
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '隐私政策',
          onTap: () {},
          icon: Icons.shield_outlined,
        ),
        _buildDivider(context),
        _buildActionTile(
          context,
          label: '顺时不是什么',
          onTap: () => context.go('/boundaries'),
          icon: Icons.warning_amber_outlined,
        ),
      ],
    );
  }

  // ==================== 通用组件 ====================

  /// 分组卡片容器
  Widget _buildSectionCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分组标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: ShunshiTextStyles.heading.copyWith(
                    fontSize: 16,
                    color: _textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: _divider(context)),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Switch 列表项
  Widget _buildSwitchTile(
    BuildContext context, {
    required String label,
    String? sublabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ShunshiTextStyles.body.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    color: _textPrimary(context),
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: ShunshiTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: ShunshiColors.primary.withValues(alpha: 0.4),
            activeThumbColor: ShunshiColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// 操作列表项
  Widget _buildActionTile(
    BuildContext context, {
    required String label,
    required VoidCallback? onTap,
    required IconData icon,
    bool isDanger = false,
    String? value,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDanger ? _error(context) : _textHint(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: ShunshiTextStyles.body.copyWith(
                  fontSize: 15,
                  height: 1.3,
                  color: isDanger ? _error(context) : _textPrimary(context),
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: ShunshiTextStyles.body.copyWith(
                  fontSize: 15,
                  color: ShunshiColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              color: _textHint(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 信息展示列表项
  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ShunshiTextStyles.body.copyWith(
                fontSize: 15,
                height: 1.3,
                color: _textPrimary(context),
              ),
            ),
          ),
          Text(
            value,
            style: ShunshiTextStyles.body.copyWith(
              fontSize: 15,
              color: _textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 分割线
  Widget _buildDivider(BuildContext context, {double indent = 16}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: 16),
      child: Divider(height: 1, color: _divider(context)),
    );
  }
}
