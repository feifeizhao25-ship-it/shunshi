import '../../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seasons/core/theme/seasons_colors.dart';
import 'package:seasons/core/theme/seasons_spacing.dart';
import 'package:seasons/core/theme/seasons_text_styles.dart';
import 'package:share_plus/share_plus.dart';

const _baseUrl = AppConstants.baseUrl;

/// Family Page — SEASONS Global
/// Shows family members, shared wellness overview, and seasonal rituals
class FamilyPage extends ConsumerStatefulWidget {
  const FamilyPage({super.key});

  @override
  ConsumerState<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends ConsumerState<FamilyPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _familyData;
  String? _familyId;
  String? _inviteLink;

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
  ));

  @override
  void initState() {
    super.initState();
    _loadOrCreateFamily();
  }

  Future<void> _loadOrCreateFamily() async {
    setState(() => _loading = true);

    // Try to create a family for the current user
    // In production, we'd check if user already has a family first
    try {
      final createResponse = await _dio.post(
        '/api/v1/seasons/family',
        data: {'name': 'My Family', 'owner_id': 'seasons-user'},
      );

      if (createResponse.statusCode == 200 || createResponse.data['family'] != null) {
        _familyId = createResponse.data['family']['id'];
        await _loadFamilyOverview();
      }
    } catch (e) {
      // If family already exists, try to get overview with default ID
      setState(() {
        _loading = false;
        _error = 'Unable to load family. Please try again.';
      });
    }
  }

  Future<void> _loadFamilyOverview() async {
    if (_familyId == null) return;

    try {
      final response = await _dio.get('/api/v1/seasons/family/$_familyId/overview');
      setState(() {
        _familyData = response.data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unable to load family data';
      });
    }
  }

  Future<void> _generateInvite() async {
    if (_familyId == null) return;

    try {
      final response = await _dio.post('/api/v1/seasons/family/$_familyId/invite');
      final code = response.data['invite_code'] ?? '';
      final link = response.data['invite_link'] ?? '';
      setState(() => _inviteLink = '$code\n$link');
      if (mounted) _showInviteDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to generate invite')),
        );
      }
    }
  }

  void _showInviteDialog() {
    if (_inviteLink == null) return;
    final parts = _inviteLink!.split('\n');
    final code = parts.isNotEmpty ? parts[0] : '';
    final link = parts.length > 1 ? parts[1] : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SeasonsColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Invite Family Member',
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
              'Share this code or link with your family member:',
              style: SeasonsTextStyles.bodySmall.copyWith(
                color: SeasonsColors.textSecondary,
              ),
            ),
            const SizedBox(height: SeasonsSpacing.md),
            Container(
              padding: const EdgeInsets.all(SeasonsSpacing.md),
              decoration: BoxDecoration(
                color: SeasonsColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SeasonsColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code:',
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: SeasonsTextStyles.body.copyWith(
                            color: SeasonsColors.primary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                        color: SeasonsColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: SeasonsSpacing.md),
                  Text(
                    'Link:',
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: link)),
                    child: Text(
                      link,
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Share.share(
                'Join my SEASONS family! Use code $code or tap: $link',
                subject: 'Join SEASONS Family',
              );
            },
            child: Text(
              'Share',
              style: SeasonsTextStyles.body.copyWith(color: SeasonsColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Done',
              style: SeasonsTextStyles.body.copyWith(color: SeasonsColors.textTertiary),
            ),
          ),
        ],
      ),
    );
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
          'Family',
          style: SeasonsTextStyles.bodyMedium.copyWith(
            color: SeasonsColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, size: 22),
            onPressed: _generateInvite,
            color: SeasonsColors.primary,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: SeasonsColors.primary,
                strokeWidth: 2,
              ),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SeasonsSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 48)),
            const SizedBox(height: SeasonsSpacing.md),
            Text(
              _error ?? 'Something went wrong',
              style: SeasonsTextStyles.body.copyWith(
                color: SeasonsColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SeasonsSpacing.lg),
            TextButton(
              onPressed: _loadOrCreateFamily,
              child: Text(
                'Try Again',
                style: SeasonsTextStyles.body.copyWith(
                  color: SeasonsColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _familyData;
    if (data == null) return const SizedBox.shrink();

    final members = (data['members'] as List?) ?? [];
    final wellnessLevel = data['wellness_level'] ?? 'beginning';
    final currentSeason = data['current_season'] ?? 'spring';
    final sharedRitual = data['shared_ritual_suggestion'] ?? {};
    final totalMembers = data['total_members'] ?? 0;
    final maxMembers = data['max_members'] ?? 4;
    final activeToday = data['active_today'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadFamilyOverview,
      color: SeasonsColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
        children: [
          // ── Family Header ──
          _buildFamilyHeader(
            familyName: data['family_name'] ?? 'My Family',
            wellnessLevel: wellnessLevel,
            season: currentSeason,
            activeToday: activeToday,
            totalMembers: totalMembers,
            maxMembers: maxMembers,
          ),
          const SizedBox(height: SeasonsSpacing.xl),

          // ── Shared Ritual ──
          if (sharedRitual.isNotEmpty) ...[
            _buildSectionHeader('THIS WEEK\'S FAMILY RITUAL'),
            const SizedBox(height: SeasonsSpacing.md),
            _buildSharedRitualCard(
              season: sharedRitual['season'] ?? 'spring',
              ritual: sharedRitual['ritual'] ?? '',
              duration: sharedRitual['duration_minutes'] ?? 5,
              bestTime: sharedRitual['best_time'] ?? 'evening',
            ),
            const SizedBox(height: SeasonsSpacing.xl),
          ],

          // ── Members ──
          _buildSectionHeader('MEMBERS'),
          const SizedBox(height: SeasonsSpacing.md),
          ...members.map((m) => _buildMemberCard(m as Map<String, dynamic>)),
          const SizedBox(height: SeasonsSpacing.lg),

          // ── Invite CTA ──
          if (totalMembers < maxMembers)
            _buildInviteCta(),

          const SizedBox(height: SeasonsSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: SeasonsTextStyles.caption.copyWith(
        color: SeasonsColors.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFamilyHeader({
    required String familyName,
    required String wellnessLevel,
    required String season,
    required int activeToday,
    required int totalMembers,
    required int maxMembers,
  }) {
    final seasonEmoji = _seasonEmoji(season);
    final wellnessColor = _wellnessColor(wellnessLevel);
    final wellnessLabel = _wellnessLabel(wellnessLevel);

    return Container(
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SeasonsColors.primary.withValues(alpha: 0.12),
            SeasonsColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
        border: Border.all(
          color: SeasonsColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(seasonEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: SeasonsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      familyName,
                      style: SeasonsTextStyles.bodyMedium.copyWith(
                        color: SeasonsColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$activeToday of $totalMembers active today',
                      style: SeasonsTextStyles.caption.copyWith(
                        color: SeasonsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SeasonsSpacing.md,
                  vertical: SeasonsSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: wellnessColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  wellnessLabel,
                  style: SeasonsTextStyles.caption.copyWith(
                    color: wellnessColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Row(
            children: List.generate(
              maxMembers,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < maxMembers - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < totalMembers
                        ? SeasonsColors.primary
                        : SeasonsColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.sm),
          Text(
            '$totalMembers / $maxMembers members',
            style: SeasonsTextStyles.caption.copyWith(
              color: SeasonsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedRitualCard({
    required String season,
    required String ritual,
    required int duration,
    required String bestTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      decoration: BoxDecoration(
        color: SeasonsColors.surface,
        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
        border: Border.all(color: SeasonsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SeasonsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(_seasonEmoji(season), style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ritual,
                  style: SeasonsTextStyles.body.copyWith(
                    color: SeasonsColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$duration min · best $bestTime · ${season.capitalize()}',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: SeasonsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              Share.share(
                'Our family ritual this week: $ritual — $duration min ${bestTime}. Shared from SEASONS 🌿',
              );
            },
            color: SeasonsColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member['name'] ?? 'Member';
    final emoji = member['avatar_emoji'] ?? '🌿';
    final streak = member['streak_days'] ?? 0;
    final reflections = member['reflections_count'] ?? 0;
    final isActive = member['is_active_today'] ?? false;
    final role = member['role'] ?? 'member';

    return Container(
      margin: const EdgeInsets.only(bottom: SeasonsSpacing.sm),
      padding: const EdgeInsets.all(SeasonsSpacing.md),
      decoration: BoxDecoration(
        color: SeasonsColors.surface,
        borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
        border: Border.all(color: SeasonsColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SeasonsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              if (isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: SeasonsColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: SeasonsTextStyles.body.copyWith(
                        color: SeasonsColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (role == 'owner') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: SeasonsColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Owner',
                          style: SeasonsTextStyles.caption.copyWith(
                            color: SeasonsColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'Active today' : 'Not active today',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: isActive
                        ? Colors.green.shade600
                        : SeasonsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 2),
                  Text(
                    '$streak',
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 2),
                  Text(
                    '$reflections',
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCta() {
    return GestureDetector(
      onTap: _generateInvite,
      child: Container(
        padding: const EdgeInsets.all(SeasonsSpacing.lg),
        decoration: BoxDecoration(
          color: SeasonsColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(SeasonsSpacing.radiusLarge),
          border: Border.all(
            color: SeasonsColors.primary.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SeasonsColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('+', style: TextStyle(fontSize: 24, color: SeasonsColors.primary)),
              ),
            ),
            const SizedBox(width: SeasonsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite a family member',
                    style: SeasonsTextStyles.body.copyWith(
                      color: SeasonsColors.primary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Share SEASONS with your household',
                    style: SeasonsTextStyles.caption.copyWith(
                      color: SeasonsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: SeasonsColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _seasonEmoji(String season) {
    switch (season.toLowerCase()) {
      case 'spring': return '🌱';
      case 'summer': return '☀️';
      case 'autumn': return '🍂';
      case 'winter': return '❄️';
      default: return '🌿';
    }
  }

  Color _wellnessColor(String level) {
    switch (level.toLowerCase()) {
      case 'thriving': return Colors.green;
      case 'engaging': return SeasonsColors.primary;
      case 'starting': return Colors.orange;
      default: return SeasonsColors.textTertiary;
    }
  }

  String _wellnessLabel(String level) {
    switch (level.toLowerCase()) {
      case 'thriving': return '🌟 Thriving';
      case 'engaging': return '🌿 Engaging';
      case 'starting': return '🌱 Starting';
      default: return '• Beginning';
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
