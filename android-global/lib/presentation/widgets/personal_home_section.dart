import 'dart:async';

import 'package:flutter/material.dart';

/// Per-user personalised home block.
///
/// One widget for every app of both products. It only draws what the backend sends:
/// a greeting, a short headline, up to four suggestion cards each with the reason it is shown,
/// and a one-tap switch to turn personalisation off (and back on). It has its own loading,
/// error, empty and "off" states so a slow or failing request never breaks the page around it.
///
/// Language is fixed per edition (the [PersonalHomeStrings] the page passes in); nothing here is translated at run time.
/// Everything the block says, in one language. One instance per edition: `personal_home_strings_zh.dart`
/// (domestic apps only) or `personal_home_strings_en.dart` (international apps only). This file holds no
/// user-visible text of its own, so neither edition ships the other one's language.
class PersonalHomeStrings {
  const PersonalHomeStrings({
    required this.heading,
    required this.why,
    required this.turnOff,
    required this.turnOn,
    required this.offTitle,
    required this.offBody,
    required this.confirmTitle,
    required this.confirmBody,
    required this.cancel,
    required this.confirm,
    required this.errorTitle,
    required this.errorBody,
    required this.retry,
    required this.emptyTitle,
    required this.emptyBody,
    required this.saveFailed,
    required this.loading,
    required this.letterSpacing,
    required this.minutes,
    required this.days,
    required this.weekHeading,
    required this.weekdays,
    required this.weekDone,
    required this.weekNone,
    required this.recallDismiss,
    required this.recallLabel,
  });

  final String heading;
  final String why;
  final String turnOff;
  final String turnOn;
  final String offTitle;
  final String offBody;
  final String confirmTitle;
  final String confirmBody;
  final String cancel;
  final String confirm;
  final String errorTitle;
  final String errorBody;
  final String retry;
  final String emptyTitle;
  final String emptyBody;
  final String saveFailed;
  final String loading;
  final double letterSpacing;
  final String Function(int n) minutes;
  final String Function(int n) days;
  final String weekHeading;
  final String weekdays;
  final String Function(String date) weekDone;
  final String Function(String date) weekNone;
  final String recallDismiss;
  final String recallLabel;
}

/// What the screen needs from the network; the page supplies the real calls, tests supply fakes.
class PersonalHomeApi {
  const PersonalHomeApi({required this.load, required this.setEnabled});

  /// Returns the dashboard JSON exactly as the backend sends it.
  final Future<Map<String, dynamic>> Function() load;

  /// Saves the on/off switch.
  final Future<void> Function(bool enabled) setEnabled;
}

class PersonalHomeCard {
  const PersonalHomeCard({required this.id, required this.title, required this.reason, required this.kind, this.body = '', this.minutes, this.href});

  final String id;
  final String title;
  final String body;
  final String reason;
  final String kind;
  final int? minutes;
  final String? href;
}

class WeekDay {
  const WeekDay({required this.date, required this.done, required this.today});
  final DateTime date;
  final bool done;
  final bool today;
}

class PersonalHomeData {
  const PersonalHomeData({
    required this.enabled,
    required this.greeting,
    required this.headline,
    required this.streakText,
    required this.note,
    required this.cards,
    this.week = const [],
    this.milestoneText = '',
    this.milestoneDay = 0,
    this.recallText = '',
    this.recallTier = '',
  });

  /// Last seven days, oldest first (from the backend; empty when it sends none).
  final List<WeekDay> week;

  /// Day-3 / day-7 message, only when the user really has that streak. [milestoneDay] is 3 or 7, else 0.
  final String milestoneText;
  final int milestoneDay;

  /// Gentle comeback message for someone away 3+ days. Shown inside the app only.
  final String recallText;
  final String recallTier;

  final bool enabled;
  final String greeting;
  final String headline;
  final String streakText;
  final String note;
  final List<PersonalHomeCard> cards;

  static String _s(dynamic v) => v is String ? v : '';

  /// Accepts both backends: the Shunshi / SEASONS one ({greeting, hero, suggestions, streak:{text}, personalization})
  /// and the Energy Intelligence one ({data:{hero:{greeting,headline,subtext}, cards, streak:int, note, personalized}}).
  factory PersonalHomeData.fromJson(Map<String, dynamic> raw, PersonalHomeStrings strings) {
    final root = raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : raw;
    final hero = root['hero'] is Map ? Map<String, dynamic>.from(root['hero'] as Map) : const <String, dynamic>{};
    final pers = root['personalization'] is Map ? Map<String, dynamic>.from(root['personalization'] as Map) : const <String, dynamic>{};
    final enabled = root.containsKey('personalized') ? root['personalized'] == true : (pers['enabled'] != false);
    final list = (root['cards'] ?? root['suggestions'] ?? root['gentle_suggestions']);
    final cards = <PersonalHomeCard>[];
    if (list is List) {
      for (final c in list) {
        if (c is! Map) continue;
        final title = _s(c['title']);
        if (title.isEmpty) continue;
        final body = _s(c['body']);
        final desc = _s(c['description']);
        cards.add(PersonalHomeCard(
          id: _s(c['id']).isEmpty ? 'card-${cards.length}' : _s(c['id']),
          title: title,
          body: body.isNotEmpty ? body : (desc == title ? '' : desc),
          reason: _s(c['reason']),
          kind: _s(c['kind']).isNotEmpty ? _s(c['kind']) : _s(c['category']),
          minutes: c['duration_min'] is num ? (c['duration_min'] as num).toInt() : null,
          href: _s(c['href']).isEmpty ? null : _s(c['href']),
        ));
      }
    }
    String streakText = '';
    final st = root['streak'];
    if (st is Map) {
      final days = st['days'] is num ? (st['days'] as num).toInt() : 0;
      streakText = _s(st['text']);
      if (st['kind'] == 'streak' && days >= 2 && streakText.isEmpty) streakText = strings.days(days);
    } else if (st is num && st >= 2) {
      streakText = strings.days(st.toInt());
    }
    final energyHeadline = _s(hero['headline']);
    final week = <WeekDay>[];
    if (root['week'] is List) {
      for (final w in root['week'] as List) {
        if (w is! Map) continue;
        final d = DateTime.tryParse(_s(w['date']));
        if (d != null) week.add(WeekDay(date: d, done: w['done'] == true, today: w['today'] == true));
      }
    }
    final ms = root['milestone'] is Map ? Map<String, dynamic>.from(root['milestone'] as Map) : const <String, dynamic>{};
    final rc = root['recall'] is Map ? Map<String, dynamic>.from(root['recall'] as Map) : const <String, dynamic>{};
    final reached = ms['reached'] is num ? (ms['reached'] as num).toInt() : 0;
    return PersonalHomeData(
      week: week.length == 7 ? week : const [],
      milestoneText: _s(ms['text']),
      milestoneDay: reached,
      recallText: _s(rc['text']),
      recallTier: _s(rc['tier']),
      enabled: enabled,
      greeting: _s(root['greeting']).isNotEmpty ? _s(root['greeting']) : _s(hero['greeting']),
      headline: energyHeadline,
      streakText: streakText.isNotEmpty ? streakText : _s(hero['subtext']),
      note: [_s(pers['note']).isNotEmpty ? _s(pers['note']) : _s(root['note']), _s(root['disclaimer'])].where((t) => t.isNotEmpty).join(' '),
      cards: cards,
    );
  }
}

enum _Phase { loading, ready, empty, off, error }

class PersonalHomeSection extends StatefulWidget {
  const PersonalHomeSection({super.key, required this.api, required this.strings, this.onOpen, this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8)});

  final PersonalHomeApi api;

  /// The edition's text (personal_home_strings_zh.dart or personal_home_strings_en.dart).
  final PersonalHomeStrings strings;

  /// Outer spacing; pages that already pad their content pass [EdgeInsets.zero].
  final EdgeInsets margin;

  /// Called with a card's in-app link (Energy Intelligence only) when the card is tapped.
  final void Function(PersonalHomeCard card)? onOpen;

  @override
  State<PersonalHomeSection> createState() => _PersonalHomeSectionState();
}

class _PersonalHomeSectionState extends State<PersonalHomeSection> {
  PersonalHomeStrings get _t => widget.strings;
  _Phase _phase = _Phase.loading;
  PersonalHomeData? _data;
  bool _saving = false;
  bool _recallDismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _phase = _Phase.loading);
    try {
      final data = PersonalHomeData.fromJson(await widget.api.load(), widget.strings);
      if (!mounted) return;
      setState(() {
        _data = data;
        _phase = !data.enabled ? _Phase.off : (data.cards.isEmpty ? _Phase.empty : _Phase.ready);
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  Future<void> _toggle(bool enabled) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.api.setEnabled(enabled);
      if (!mounted) return;
      setState(() => _saving = false);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(_t.saveFailed)));
    }
  }

  Future<void> _askTurnOff() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t.confirmTitle),
        content: Text(_t.confirmBody),
        actions: [
          TextButton(key: const Key('personal-home-cancel'), onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t.cancel)),
          FilledButton(key: const Key('personal-home-confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t.confirm)),
        ],
      ),
    );
    if (ok == true) await _toggle(false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('personal-home'),
      margin: widget.margin,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(_phase), child: _body(context)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return _Skeleton(label: _t.loading);
      case _Phase.error:
        return _Message(
          key: const Key('personal-home-error'),
          icon: Icons.cloud_off_rounded,
          title: _t.errorTitle,
          body: _t.errorBody,
          action: TextButton(key: const Key('personal-home-retry'), onPressed: _load, child: Text(_t.retry)),
        );
      case _Phase.off:
        return _Message(
          key: const Key('personal-home-off'),
          icon: Icons.tune_rounded,
          title: _t.offTitle,
          body: _t.offBody,
          action: FilledButton.tonal(key: const Key('personal-home-turn-on'), onPressed: _saving ? null : () => _toggle(true), child: Text(_t.turnOn)),
        );
      case _Phase.empty:
        return _Message(key: const Key('personal-home-empty'), icon: Icons.spa_outlined, title: _t.emptyTitle, body: _t.emptyBody, action: _offButton());
      case _Phase.ready:
        return _content(context, _data!);
    }
  }

  Widget _offButton() => TextButton.icon(
        key: const Key('personal-home-turn-off'),
        onPressed: _saving ? null : _askTurnOff,
        icon: const Icon(Icons.tune_rounded, size: 16),
        label: Text(_t.turnOff),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      );

  Widget _content(BuildContext context, PersonalHomeData d) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_t.heading, style: text.labelMedium?.copyWith(color: scheme.primary, letterSpacing: _t.letterSpacing, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (d.greeting.isNotEmpty) Text(d.greeting, key: const Key('personal-home-greeting'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (d.headline.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(d.headline, key: const Key('personal-home-headline'), style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        if (d.recallText.isNotEmpty && !_recallDismissed) ...[
          const SizedBox(height: 10),
          _RecallCard(strings: _t, text: d.recallText, onDismiss: () => setState(() => _recallDismissed = true)),
        ] else if (d.streakText.isNotEmpty) ...[
          const SizedBox(height: 8),
          _StreakChip(text: d.streakText),
        ],
        if (d.milestoneDay > 0 && d.milestoneText.isNotEmpty) ...[
          const SizedBox(height: 6),
          _MilestoneChip(day: d.milestoneDay, text: d.milestoneText),
        ],
        if (d.week.any((w) => w.done)) ...[
          const SizedBox(height: 10),
          _WeekStrip(strings: _t, days: d.week),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < d.cards.length; i++) ...[
          _CardTile(card: d.cards[i], strings: _t, featured: i == 0, onTap: widget.onOpen == null || d.cards[i].href == null ? null : () => widget.onOpen!(d.cards[i])),
          const SizedBox(height: 8),
        ],
        const Divider(height: 16),
        if (d.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(d.note, key: const Key('personal-home-note'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        Align(alignment: AlignmentDirectional.centerEnd, child: _offButton()),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.day, required this.text});
  final int day;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('personal-home-milestone'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: scheme.tertiaryContainer.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(day >= 7 ? Icons.emoji_events_outlined : Icons.star_outline_rounded, size: 16, color: scheme.onTertiaryContainer),
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onTertiaryContainer))),
      ]),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.strings, required this.days});
  final PersonalHomeStrings strings;
  final List<WeekDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    String fmt(DateTime d) => '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Column(key: const Key('personal-home-week'), crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(strings.weekHeading, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final d in days)
          Semantics(
            label: d.done ? strings.weekDone(fmt(d.date)) : strings.weekNone(fmt(d.date)),
            excludeSemantics: true,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                key: Key('personal-home-week-${fmt(d.date)}'),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d.done ? scheme.primary : Colors.transparent,
                  border: Border.all(color: d.today ? scheme.primary : scheme.outlineVariant, width: d.today ? 2 : 1),
                ),
                child: d.done ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary) : null,
              ),
              const SizedBox(height: 2),
              Text(strings.weekdays[(d.date.weekday - 1) % 7], style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
      ]),
    ]);
  }
}

class _RecallCard extends StatelessWidget {
  const _RecallCard({required this.strings, required this.text, required this.onDismiss});
  final PersonalHomeStrings strings;
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      key: const Key('personal-home-recall'),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.waving_hand_outlined, size: 18, color: scheme.onSecondaryContainer),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(strings.recallLabel, style: t.labelMedium?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(text, style: t.bodyMedium?.copyWith(color: scheme.onSecondaryContainer, height: 1.3)),
          ]),
        ),
        TextButton(key: const Key('personal-home-recall-dismiss'), onPressed: onDismiss, child: Text(strings.recallDismiss)),
      ]),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('personal-home-streak'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department_rounded, size: 14, color: scheme.onSecondaryContainer),
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSecondaryContainer))),
      ]),
    );
  }
}

IconData _iconFor(String kind) {
  final k = kind.toLowerCase();
  const table = <String, IconData>{
    'sleep': Icons.bedtime_outlined,
    'breath': Icons.air_rounded,
    'exercise': Icons.directions_walk_rounded,
    'food': Icons.restaurant_outlined,
    'mood': Icons.sentiment_satisfied_alt_rounded,
    'family': Icons.groups_2_outlined,
    'season': Icons.eco_outlined,
    'rest': Icons.self_improvement_rounded,
    'setup': Icons.flag_outlined,
    'analysis': Icons.calculate_outlined,
    'report': Icons.description_outlined,
    'review': Icons.fact_check_outlined,
    'ops': Icons.build_circle_outlined,
    'alarm': Icons.notifications_active_outlined,
    'pipeline': Icons.timeline_rounded,
    'learn': Icons.menu_book_outlined,
    'policy': Icons.gavel_rounded,
    'market': Icons.public_rounded,
    'rhythm': Icons.schedule_rounded,
    'perf': Icons.show_chart_rounded,
    'safety': Icons.health_and_safety_outlined,
  };
  for (final e in table.entries) {
    if (k.contains(e.key)) return e.value;
  }
  return Icons.lightbulb_outline_rounded;
}

/// Existing wellness photos for the suggestion categories the SEASONS backend sends.
/// A stable pick by card id keeps a card's picture the same across reloads.
String? _photoFor(String kind, String id) {
  const table = <String, List<String>>{
    'sleep': ['sleep_pillow_moon', 'sleep_quality', 'sleep_herbal_pillow'],
    'breath': ['exercise_sleep_relax', 'emotion_meditation'],
    'exercise': ['exercise_morning_stretch', 'exercise_walking', 'exercise_yoga_nature', 'exercise_taichi'],
    'food': ['food_spring_salad', 'food_lotus_soup', 'food_red_bean_porridge', 'food_yam_porridge', 'food_winter_stew'],
    'mood': ['emotion_journal_writing', 'emotion_meditation_bowl'],
    'rest': ['emotion_meditation_bowl', 'sleep_quality'],
    'family': ['wellness_seasonal', 'exercise_walking'],
    'season': ['wellness_seasonal', 'wellness_herbs'],
  };
  final k = kind.toLowerCase();
  for (final e in table.entries) {
    if (k.contains(e.key)) {
      var h = 0;
      for (final c in id.codeUnits) {
        h = (h * 31 + c) & 0x7fffffff;
      }
      return 'assets/images/wellness/${e.value[h % e.value.length]}.jpg';
    }
  }
  return null;
}

class _CardLead extends StatelessWidget {
  const _CardLead({required this.card, required this.scheme});
  final PersonalHomeCard card;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(_iconFor(card.kind), size: 20, color: scheme.primary),
    );
    final photo = _photoFor(card.kind, card.id);
    if (photo == null) return icon;
    return ClipRRect(
      key: Key('personal-home-photo-${card.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(photo, width: 56, height: 56, fit: BoxFit.cover, cacheWidth: 168, errorBuilder: (_, __, ___) => icon),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.strings, required this.featured, this.onTap});
  final PersonalHomeCard card;
  final PersonalHomeStrings strings;
  final bool featured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tile = Container(
      key: Key('personal-home-card-${card.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: featured ? scheme.primaryContainer.withValues(alpha: 0.55) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: featured ? null : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLead(card: card, scheme: scheme),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
            if (card.body.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(card.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (card.minutes != null) ...[
              const SizedBox(height: 6),
              Text(strings.minutes(card.minutes!), style: text.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
            ],
            if (card.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${strings.why}  ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: card.reason),
                    ]),
                    key: Key('personal-home-why-${card.id}'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.3),
                  ),
                ),
              ]),
            ],
          ]),
        ),
        if (onTap != null) Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      ]),
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: tile),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.title, required this.body, required this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 28, color: scheme.onSurfaceVariant),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(body, textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        action,
      ]),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    Widget bar(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)));
    return Semantics(
      label: label,
      child: Column(key: const Key('personal-home-loading'), crossAxisAlignment: CrossAxisAlignment.start, children: [
        bar(96, 12),
        const SizedBox(height: 10),
        bar(190, 18),
        const SizedBox(height: 14),
        for (var i = 0; i < 3; i++) ...[
          Container(height: 64, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: c.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16))),
        ],
      ]),
    );
  }
}
