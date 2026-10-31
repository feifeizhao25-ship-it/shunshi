import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/router/safe_pop.dart';
import '../../../core/safety/crisis_resources.dart';
import '../../../design_system/theme.dart';

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _moods)
                ChoiceChip(
                  key: Key('mood_${m.id}'),
                  label: Text(m.label),
                  selected: _selected == m.id,
                  onSelected: (_) => setState(() => _selected = m.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (selected != null)
            Container(
              key: const Key('mood_idea'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(selected.idea, style: TextStyle(fontSize: 15, height: 1.45, color: ShunShiColors.textPrimary)),
            ),
          const SizedBox(height: 24),
          Container(
            key: const Key('mood_support_card'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: ShunShiColors.borderGhost),
              borderRadius: BorderRadius.circular(14),
            ),
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
