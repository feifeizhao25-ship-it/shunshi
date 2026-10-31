import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/router/safe_pop.dart';
import '../../../core/safety/crisis_resources.dart';
import '../../../design_system/theme.dart';
import '../../widgets/seasons_visual.dart';

/// Mood check-in: pick how you feel, get one small, practical idea, and see where to find
/// human support. Wellness routine guidance only; this page never diagnoses.
class MoodPage extends StatefulWidget {
  const MoodPage({super.key, this.countryCode});

  /// Overrides the device locale's country (used by tests).
  final String? countryCode;

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _Mood {
  const _Mood(this.id, this.label, this.idea);
  final String id;
  final String label;
  final String idea;
}

const _moods = [
  _Mood('calm', 'Calm', 'Notice what is helping and repeat it tomorrow: a walk, a warm drink, or a regular bedtime.'),
  _Mood('stressed', 'Stressed', 'Try slow breathing for two minutes: in for 4 seconds, out for 6. Then write down the one next step.'),
  _Mood('low', 'Low', 'Get outside in daylight for 10 minutes if you can, and message one person you trust.'),
  _Mood('anxious', 'Anxious', 'Name five things you can see and four you can touch. Slow, steady breaths help your body settle.'),
  _Mood('tired', 'Tired', 'Keep your wake-up time steady, get morning light, and keep caffeine to the morning.'),
];

String _moodImage(String id) => 'assets/images/sgx_mood_$id.webp';

class _MoodPageState extends State<MoodPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final country = widget.countryCode ?? ui.PlatformDispatcher.instance.locale.countryCode;
    final selected = _moods.where((m) => m.id == _selected).firstOrNull;
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: BackButton(onPressed: () => safePop(context)),
        title: const Text('How are you feeling?'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SgHeroBanner(
            asset: 'assets/images/sgx_hero_mood.webp',
            title: 'Check in with yourself',
            subtitle: 'Pick the word that fits today.',
            height: 150,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final m in _moods)
                Expanded(
                  child: GestureDetector(
                    key: Key('mood_${m.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selected = m.id),
                    child: Semantics(
                      selected: _selected == m.id,
                      button: true,
                      label: m.label,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selected == m.id ? const Color(0xFF144227) : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Opacity(
                                opacity: _selected == null || _selected == m.id ? 1 : 0.55,
                                child: Image.asset(_moodImage(m.id), width: 56, height: 56, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selected == m.id ? FontWeight.w700 : FontWeight.w500,
                              color: ShunShiColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (selected != null)
            Container(
              key: const Key('mood_idea'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ShunShiColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(child: Image.asset(_moodImage(selected.id), width: 44, height: 44, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('A small idea for feeling ${selected.label.toLowerCase()}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(selected.idea, style: TextStyle(fontSize: 15, height: 1.45, color: ShunShiColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Container(
            key: const Key('mood_support_card'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: ShunShiColors.borderGhost),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(child: Image.asset('assets/images/sgx_mood_support.webp', width: 48, height: 48, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need to talk to someone?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                      const SizedBox(height: 8),
                      for (final line in CrisisResources.lines(country))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(line, style: TextStyle(fontSize: 14, height: 1.4, color: ShunShiColors.textSecondary)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'For wellness routine guidance only; not medical diagnosis or treatment.',
            style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
