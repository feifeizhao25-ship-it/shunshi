import 'package:flutter/material.dart';

import '../../../core/router/safe_pop.dart';
import '../../../design_system/theme.dart';
import '../../widgets/seasons_visual.dart';

/// Seasonal warm drinks: a short, plain list of everyday drinks by season.
/// No health claims; herbal products can interact with medicines, so the page says so.
class TeaPage extends StatefulWidget {
  const TeaPage({super.key});

  @override
  State<TeaPage> createState() => _TeaPageState();
}

class _Drink {
  const _Drink(this.name, this.note, this.image);
  final String name;
  final String note;
  final String image;
}


const Map<String, IconData> _seasonIcons = {
  'Spring': Icons.local_florist_outlined,
  'Summer': Icons.wb_sunny_outlined,
  'Autumn': Icons.eco_outlined,
  'Winter': Icons.ac_unit,
};

const Map<String, String> _seasonPhotos = {
  'Spring': 'assets/images/sg_season_spring.webp',
  'Summer': 'assets/images/sg_season_summer.webp',
  'Autumn': 'assets/images/sg_season_autumn.webp',
  'Winter': 'assets/images/sg_season_winter.webp',
};

const Map<String, List<_Drink>> _drinksBySeason = {
  'Spring': [
    _Drink('Green tea', 'Light and fresh. Contains caffeine, so keep it to the morning.', 'assets/images/sgx_drink_green.webp'),
    _Drink('Peppermint infusion', 'Caffeine-free and refreshing, easy to drink after meals.', 'assets/images/sgx_drink_peppermint.webp'),
  ],
  'Summer': [
    _Drink('Iced herbal infusion', 'Unsweetened, caffeine-free, and good with citrus slices.', 'assets/images/sgx_drink_iced.webp'),
    _Drink('Cold-brewed tea', 'Smooth and less bitter. Keep an eye on the caffeine.', 'assets/images/sgx_drink_coldbrew.webp'),
  ],
  'Autumn': [
    _Drink('Ginger and lemon', 'A warming drink for cooler evenings.', 'assets/images/sgx_drink_ginger.webp'),
    _Drink('Chamomile', 'Caffeine-free and a comfortable part of a wind-down routine.', 'assets/images/sgx_drink_chamomile.webp'),
  ],
  'Winter': [
    _Drink('Warm spiced tea', 'Cinnamon and cardamom make a cosy afternoon drink.', 'assets/images/sgx_drink_spiced.webp'),
    _Drink('Hot water with honey', 'Simple and soothing. Skip honey for children under one year.', 'assets/images/sgx_drink_honey.webp'),
  ],
};

class _TeaPageState extends State<TeaPage> {
  String _season = 'Autumn';

  @override
  Widget build(BuildContext context) {
    final drinks = _drinksBySeason[_season]!;
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: BackButton(onPressed: () => safePop(context)),
        title: const Text('Seasonal drinks'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SgHeroBanner(
            key: ValueKey('tea_hero_$_season'),
            asset: _seasonPhotos[_season]!,
            title: '$_season in a cup',
            subtitle: '${drinks.length} everyday drinks for this season',
            height: 150,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final s in _drinksBySeason.keys)
                ChoiceChip(
                  key: Key('season_$s'),
                  avatar: Icon(_seasonIcons[s], size: 18, color: _season == s ? Colors.white : ShunShiColors.textSecondary),
                  label: Text(s),
                  selected: _season == s,
                  showCheckmark: false,
                  selectedColor: ShunShiColors.textPrimary,
                  labelStyle: TextStyle(color: _season == s ? Colors.white : ShunShiColors.textPrimary, fontSize: 14),
                  onSelected: (_) => setState(() => _season = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final d in drinks)
            Container(
              key: Key('drink_${d.name}'),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SgThumb(asset: d.image, size: 84),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(d.note, style: TextStyle(fontSize: 14, height: 1.4, color: ShunShiColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF6E0), borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF8A6A1E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Herbal teas and supplements can interact with medicines. If you take any, check with your pharmacist first. '
                    'For wellness routine guidance only; not medical diagnosis or treatment.',
                    style: TextStyle(fontSize: 13, height: 1.45, color: ShunShiColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
