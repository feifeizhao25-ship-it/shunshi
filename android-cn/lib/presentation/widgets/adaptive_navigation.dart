// Age-Adaptive Navigation
// Based on Ultimate UI Structure v1.0

import 'package:flutter/material.dart';

// ==================== Age Groups ====================

enum AgeGroup {
  youngAdult,    // 18-25
  adult,         // 25-40
  middleAge,     // 40-60
  senior,        // 60+
}

AgeGroup getAgeGroup(int age) {
  if (age < 25) return AgeGroup.youngAdult;
  if (age < 40) return AgeGroup.adult;
  if (age < 60) return AgeGroup.middleAge;
  return AgeGroup.senior;
}

// ==================== Life Stages ====================

enum LifeStage {
  stress,      // 压力期
  transition,  // 过渡期
  stable,      // 稳定期
  recovery,    // 恢复期
}

LifeStage getLifeStage(String stage) {
  switch (stage) {
    case 'stress_stage':
      return LifeStage.stress;
    case 'transition_phase':
      return LifeStage.transition;
    case 'stable_phase':
      return LifeStage.stable;
    case 'recovery_phase':
      return LifeStage.recovery;
    default:
      return LifeStage.stress;
  }
}

// ==================== Navigation Config ====================

class NavConfig {
  final List<NavItem> items;
  final int selectedIndex;
  final bool showLabels;
  final double iconSize;
  final double fontSize;
  
  const NavConfig({
    required this.items,
    this.selectedIndex = 0,
    this.showLabels = true,
    this.iconSize = 24,
    this.fontSize = 12,
  });
  
  // Factory for different age groups
  static NavConfig forAge(AgeGroup age, {int selectedIndex = 0}) {
    switch (age) {
      case AgeGroup.senior:
        // 60+: Larger icons, no labels (or show all), simpler
        return NavConfig(
          items: [
            NavItem(icon: Icons.home, label: '首页'),
            NavItem(icon: Icons.wb_sunny, label: '节气'),
            NavItem(icon: Icons.menu_book, label: '内容'),
            NavItem(icon: Icons.person, label: '我的'),
          ],
          selectedIndex: selectedIndex,
          showLabels: true,
          iconSize: 28,
          fontSize: 14,
        );
      case AgeGroup.middleAge:
        // 40-60: Standard with labels
        return NavConfig(
          items: [
            NavItem(icon: Icons.home, label: '首页'),
            NavItem(icon: Icons.wb_sunny, label: '节气'),
            NavItem(icon: Icons.menu_book, label: '内容'),
            NavItem(icon: Icons.person, label: '我的'),
          ],
          selectedIndex: selectedIndex,
          showLabels: true,
          iconSize: 24,
          fontSize: 12,
        );
      default:
        // 18-40: Compact
        return NavConfig(
          items: [
            NavItem(icon: Icons.home, label: '首页'),
            NavItem(icon: Icons.wb_sunny, label: '节气'),
            NavItem(icon: Icons.menu_book, label: '内容'),
            NavItem(icon: Icons.person, label: '我的'),
          ],
          selectedIndex: selectedIndex,
          showLabels: true,
          iconSize: 24,
          fontSize: 12,
        );
    }
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final String? badge;
  
  const NavItem({
    required this.icon,
    required this.label,
    this.badge,
  });
}

// ==================== Bottom Navigation ====================

class AdaptiveBottomNav extends StatelessWidget {
  final NavConfig config;
  final ValueChanged<int> onTap;
  
  const AdaptiveBottomNav({
    super.key,
    required this.config,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: config.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == config.selectedIndex;
              
              return _NavItem(
                icon: item.icon,
                label: item.label,
                badge: item.badge,
                isSelected: isSelected,
                iconSize: config.iconSize,
                fontSize: config.fontSize,
                showLabel: config.showLabels,
                onTap: () => onTap(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isSelected;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final VoidCallback onTap;
  
  const _NavItem({
    required this.icon,
    required this.label,
    this.badge,
    required this.isSelected,
    required this.iconSize,
    required this.fontSize,
    required this.showLabel,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF4CAF50) : const Color(0xFF757575);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: iconSize, color: color),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF44336),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== Main App Shell ====================

class ShunShiAppShell extends StatefulWidget {
  final int userAge;
  final String lifeStage;
  
  const ShunShiAppShell({
    super.key,
    this.userAge = 30,
    this.lifeStage = 'stress_stage',
  });
  
  @override
  State<ShunShiAppShell> createState() => _ShunShiAppShellState();
}

class _ShunShiAppShellState extends State<ShunShiAppShell> {
  late int _selectedIndex;
  late NavConfig _navConfig;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _updateNavConfig();
  }
  
  void _updateNavConfig() {
    final ageGroup = getAgeGroup(widget.userAge);
    _navConfig = NavConfig.forAge(ageGroup, selectedIndex: _selectedIndex);
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _navConfig = NavConfig.forAge(
        getAgeGroup(widget.userAge),
        selectedIndex: index,
      );
    });
  }
  
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        // Home - handled by parent
        return const SizedBox();
      case 1:
        // Solar Terms
        return const SolarTermPlaceholder();
      case 2:
        // Content
        return const ContentPlaceholder();
      case 3:
        // Profile
        return const ProfilePlaceholder();
      default:
        return const SizedBox();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    _updateNavConfig();
    
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: AdaptiveBottomNav(
        config: _navConfig,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholders
class SolarTermPlaceholder extends StatelessWidget {
  const SolarTermPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('节气页'));
  }
}

class ContentPlaceholder extends StatelessWidget {
  const ContentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('内容库'));
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('我的'));
  }
}
