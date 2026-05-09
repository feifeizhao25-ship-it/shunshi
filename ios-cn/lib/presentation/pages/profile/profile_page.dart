import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _pushEnabled = true;
  bool _elderMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Avatar + Name
              _buildProfileHeader(),
              const SizedBox(height: 24),
              // SVIP Card
              _buildSvipCard(),
              const SizedBox(height: 20),
              // Feature List
              _buildFeatureList(),
              const SizedBox(height: 16),
              // Settings
              _buildSettingsSection(),
              const SizedBox(height: 24),
              Text(
                'v1.0.0',
                style: TextStyle(
                  color: ShunShiColors.textTertiary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ShunShiColors.surface,
            border: Border.all(color: ShunShiColors.primary, width: 2),
          ),
          child: const Icon(Icons.person, size: 40, color: ShunShiColors.primary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '云水禅心',
              style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SVIP',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'shunshi_2024',
          style: TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSvipCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push('/subscription'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF144227), Color(0xFF2D7A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: ShunShiColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '顺时SVIP尊享',
                    style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '有效期至 2026-12-31',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final items = [
      _MenuItem(Icons.favorite_rounded, '养生记录', '/records'),
      _MenuItem(Icons.family_restroom, '家庭管理', '/family'),
      _MenuItem(Icons.assignment, '体质测试', '/constitution'),
      _MenuItem(Icons.emoji_events, '成就勋章', '/achievements'),
      _MenuItem(Icons.bookmark, '收藏内容', null),
      _MenuItem(Icons.group_add, '邀请家人', null),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Icon(item.icon, color: ShunShiColors.primary),
                  title: Text(item.title, style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 15)),
                  trailing: Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 20),
                  onTap: () {
                    if (item.route != null) {
                      context.push(item.route!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title}功能开发中'), duration: const Duration(seconds: 1)));
                    }
                  },
                ),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: ShunShiColors.borderGhost),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('消息推送', style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 15)),
              value: _pushEnabled,
              activeThumbColor: ShunShiColors.primary,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            Divider(height: 1, color: ShunShiColors.borderGhost, indent: 16),
            SwitchListTile(
              title: Text('老年模式', style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 15)),
              value: _elderMode,
              activeThumbColor: ShunShiColors.primary,
              onChanged: (v) => setState(() => _elderMode = v),
            ),
            Divider(height: 1, color: ShunShiColors.borderGhost, indent: 16),
            ListTile(
              leading: const Icon(Icons.settings, color: ShunShiColors.secondary),
              title: Text('设置', style: TextStyle(color: ShunShiColors.textPrimary, fontSize: 15)),
              trailing: Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 20),
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? route;
  const _MenuItem(this.icon, this.title, this.route);
}
