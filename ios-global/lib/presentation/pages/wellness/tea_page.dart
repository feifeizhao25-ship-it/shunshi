import 'package:flutter/material.dart';

import '../../../core/router/safe_pop.dart';
import '../../../design_system/theme.dart';

/// Seasonal warm drinks: a short, plain list of everyday drinks by season.
/// No health claims; herbal products can interact with medicines, so the page says so.
class TeaPage extends StatefulWidget {
  const TeaPage({super.key});

  @override
  State<TeaPage> createState() => _TeaPageState();
}

class _Drink {
  const _Drink(this.name, this.note);
  final String name;
  final String note;
}

const Map<String, List<_Drink>> _drinksBySeason = {
  'Spring': [
    _Drink('Green tea', 'Light and fresh. Contains caffeine, so keep it to the morning.'),
    _Drink('Peppermint infusion', 'Caffeine-free and refreshing, easy to drink after meals.'),
  ],
  'Summer': [
    _Drink('Iced herbal infusion', 'Unsweetened, caffeine-free, and good with citrus slices.'),
    _Drink('Cold-brewed tea', 'Smooth and less bitter. Keep an eye on the caffeine.'),
  ],
  'Autumn': [
    _Drink('Ginger and lemon', 'A warming drink for cooler evenings.'),
    _Drink('Chamomile', 'Caffeine-free and a comfortable part of a wind-down routine.'),
  ],
  'Winter': [
    _Drink('Warm spiced tea', 'Cinnamon and cardamom make a cosy afternoon drink.'),
    _Drink('Hot water with honey', 'Simple and soothing. Skip honey for children under one year.'),
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
          Wrap(
            spacing: 8,
            children: [
              for (final s in _drinksBySeason.keys)
                ChoiceChip(
                  key: Key('season_$s'),
                  label: Text(s),
                  selected: _season == s,
                  onSelected: (_) => setState(() => _season = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final d in drinks)
            Container(
              key: Key('drink_${d.name}'),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(d.note, style: TextStyle(fontSize: 14, height: 1.4, color: ShunShiColors.textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Herbal teas and supplements can interact with medicines. If you take any, check with your pharmacist first. '
            'For wellness routine guidance only; not medical diagnosis or treatment.',
            style: TextStyle(fontSize: 12, height: 1.4, color: ShunShiColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
