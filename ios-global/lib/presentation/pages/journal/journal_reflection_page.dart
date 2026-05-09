/// Journal Reflection Page — Reference: journal_reflection
/// "Harvesting the Light" — Late Summer Phase
///
/// Structure:
/// 1. Phase header
/// 2. Internal Climate selector (Rising Sun / Calm Water / Stormy Wind / Mist)
/// 3. Daily Gratitude (two prompts)
/// 4. Seasonal Reflection text area
/// 5. Save
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class JournalReflectionPage extends StatefulWidget {
  const JournalReflectionPage({super.key});

  @override
  State<JournalReflectionPage> createState() => _JournalReflectionPageState();
}

class _JournalReflectionPageState extends State<JournalReflectionPage> {
  int _climateIndex = -1;
  final _gratitude1 = TextEditingController();
  final _gratitude2 = TextEditingController();
  final _reflection = TextEditingController();

  static const _climates = [
    _Climate('Rising Sun', Icons.wb_sunny, Color(0xFFF59E0B)),
    _Climate('Calm Water', Icons.water_drop, Color(0xFF3B82F6)),
    _Climate('Stormy Wind', Icons.air, Color(0xFF8B5CF6)),
    _Climate('Mist', Icons.filter_drama, Color(0xFF64748B)),
  ];

  @override
  void dispose() {
    _gratitude1.dispose();
    _gratitude2.dispose();
    _reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Late Summer Phase', style: TextStyle(
              fontSize: 13, color: ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
            Text('Harvesting the Light', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 8),
            Text(
              'Take a moment to center yourself. The earth is slowing, and so may you.',
              style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6, fontFamily: ShunShiTypography.sansFamily),
            ),
            const SizedBox(height: 28),

            // ── Internal Climate ──
            Text('Current Internal Climate', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_climates.length, (i) {
                final c = _climates[i];
                final selected = i == _climateIndex;
                return GestureDetector(
                  onTap: () => setState(() => _climateIndex = i),
                  child: Column(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: selected ? c.color.withValues(alpha: 0.15) : ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(c.icon, size: 24, color: selected ? c.color : ShunShiColors.textTertiary),
                      ),
                      const SizedBox(height: 6),
                      Text(c.name, style: TextStyle(
                        fontSize: 11,
                        color: selected ? c.color : ShunShiColors.textTertiary,
                        fontFamily: ShunShiTypography.sansFamily,
                      )),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // ── Daily Gratitude ──
            Text('Daily Gratitude', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 16),
            _gratitudeField(_gratitude1, Icons.restore, 'A small thing today...'),
            const SizedBox(height: 12),
            _gratitudeField(_gratitude2, Icons.person_outline, 'A person I cherish...'),
            const SizedBox(height: 28),

            // ── Seasonal Reflection ──
            Text('Seasonal Reflection', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 12),
            TextField(
              controller: _reflection,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'How does this season feel in your body...',
                hintStyle: TextStyle(color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily),
                filled: true,
                fillColor: ShunShiColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily, height: 1.6),
            ),
            const SizedBox(height: 24),

            // ── Save ──
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reflection saved'), duration: Duration(seconds: 2)));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Reflection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _gratitudeField(TextEditingController controller, IconData icon, String hint) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Icon(icon, size: 20, color: ShunShiColors.textTertiary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily),
              filled: true,
              fillColor: ShunShiColors.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: TextStyle(fontSize: 14, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily),
          ),
        ),
      ],
    );
  }
}

class _Climate {
  final String name;
  final IconData icon;
  final Color color;
  const _Climate(this.name, this.icon, this.color);
}
