/// Global Profile — 参考 profile_settings
/// "Digital Sanctuary" brand, English UI
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class GlobalProfilePage extends StatefulWidget {
  const GlobalProfilePage({super.key});

  @override
  State<GlobalProfilePage> createState() => _GlobalProfilePageState();
}

class _GlobalProfilePageState extends State<GlobalProfilePage> {
  String _hemisphere = 'Northern';
  String _units = 'Metric';
  String _language = 'English (Global)';
  final _diets = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  const Icon(Icons.menu, color: ShunShiColors.primary),
                  const Spacer(),
                  Text('Digital Sanctuary', style: TextStyle(
                    fontFamily: ShunShiTypography.serifFamily,
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: ShunShiColors.primary,
                  )),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.edit, size: 20, color: ShunShiColors.textSecondary), onPressed: () {}),
                ]),
              ),
            ),
          ),

          // Avatar + Name
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                    boxShadow: [BoxShadow(color: Color(0xFF533afd).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.spa, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text('Seeker of Calm', style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 22, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
                )),
                const SizedBox(height: 4),
                Text('Spring Equinox Member since 2023', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
                const SizedBox(height: 12),
                // Badges
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildBadge(Icons.park, 'Nature Guide'),
                  const SizedBox(width: 12),
                  _buildBadge(Icons.restaurant, 'Mindful Eater'),
                ]),
              ]),
            ),
          ),

          // Global Preferences
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('Global Preferences', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary,
              )),
            ),
          ),

          // Hemisphere
          SliverToBoxAdapter(child: _buildPreferenceCard(
            icon: Icons.public,
            title: 'Hemisphere',
            subtitle: 'Influences seasonal rituals and content',
            child: Row(children: [
              _buildChip('Northern', _hemisphere == 'Northern', () => setState(() => _hemisphere = 'Northern')),
              const SizedBox(width: 8),
              _buildChip('Southern', _hemisphere == 'Southern', () => setState(() => _hemisphere = 'Southern')),
            ]),
          )),

          // Units
          SliverToBoxAdapter(child: _buildPreferenceCard(
            icon: Icons.straighten,
            title: 'Measurement Units',
            subtitle: 'Weight, distance, and temperature',
            child: Row(children: [
              _buildChip('Metric (kg, km, °C)', _units == 'Metric', () => setState(() => _units = 'Metric')),
              const SizedBox(width: 8),
              _buildChip('Imperial', _units == 'Imperial', () => setState(() => _units = 'Imperial')),
            ]),
          )),

          // Language
          SliverToBoxAlternate(child: _buildPreferenceCard(
            icon: Icons.language,
            title: 'Language & Locale',
            subtitle: 'Select your primary dialect',
            child: Wrap(spacing: 8, children: ['English (Global)', 'Español', 'Français', '日本語'].map((l) =>
              _buildChip(l, _language == l, () => setState(() => _language = l)),
            ).toList()),
          )),

          // Dietary Preferences
          SliverToBoxAlternate(child: _buildPreferenceCard(
            icon: Icons.restaurant_menu,
            title: 'Nourishment Logic',
            subtitle: 'Personalize your recipe discovery experience',
            child: Wrap(spacing: 8, children: ['Vegan', 'Halal', 'Gluten Free', 'Dairy Free', 'Nut Free', 'Kosher'].map((d) =>
              _buildChip(d, _diets.contains(d), () => setState(() => _diets.contains(d) ? _diets.remove(d) : _diets.add(d))),
            ).toList()),
          )),

          // Actions
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(children: [
              TextButton(onPressed: () {}, child: Text('Sign Out of Sanctuary', style: TextStyle(color: ShunShiColors.textTertiary))),
              TextButton(onPressed: () {}, child: Text('Deactivate Calm Account', style: TextStyle(color: Colors.red[400], fontSize: 13))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF533afd).withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Color(0xFF533afd)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF533afd), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPreferenceCard({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: Color(0xFF533afd), size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Color(0xFF533afd).withOpacity(0.1) : ShunShiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Color(0xFF533afd) : ShunShiColors.borderGhost),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: selected ? Color(0xFF533afd) : ShunShiColors.textSecondary,
        )),
      ),
    );
  }
}

// Helper to avoid duplicate SliverToBoxAdapter
class SliverToBoxAlternate extends SliverToBoxAdapter {
  const SliverToBoxAlternate({super.key, required Widget child}) : super(child: child);
}
