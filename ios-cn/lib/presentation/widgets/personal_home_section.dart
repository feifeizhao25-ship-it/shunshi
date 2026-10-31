import 'dart:async';

import 'package:flutter/material.dart';

/// Per-user personalised home block ("今天为你准备的" / "Picked for you today").
///
/// One widget for every app of both products. It only draws what the backend sends:
/// a greeting, a short headline, up to four suggestion cards each with the reason it is shown,
/// and a one-tap switch to turn personalisation off (and back on). It has its own loading,
/// error, empty and "off" states so a slow or failing request never breaks the page around it.
///
/// Language is fixed per edition ([_zh]); nothing here is translated at run time.
const bool _zh = true;

class _S {
  const _S._();
  static const heading = '今天为你准备的';
  static const why = '为什么看到这个';
  static const turnOff = '关闭个性化';
  static const turnOn = '重新打开';
  static const offTitle = '个性化已关闭';
  static const offBody = '现在显示的是通用内容，你的记录没有被删除。';
  static const confirmTitle = '关闭个性化推荐？';
  static const confirmBody = '关闭后首页只显示通用内容，之前的记录不会被删除，随时可以重新打开。';
  static const cancel = '取消';
  static const confirm = '关闭';
  static const errorTitle = '暂时没能加载';
  static const errorBody = '请检查网络后再试一次。';
  static const retry = '重试';
  static const emptyTitle = '今天暂时没有新的建议';
  static const emptyBody = '晚点再来看看。';
  static const saveFailed = '没能保存设置，请稍后再试';
  static String minutes(int n) => '$n 分钟';
  static String days(int n) => '已连续 $n 天打开';
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

class PersonalHomeData {
  const PersonalHomeData({required this.enabled, required this.greeting, required this.headline, required this.streakText, required this.note, required this.cards});

  final bool enabled;
  final String greeting;
  final String headline;
  final String streakText;
  final String note;
  final List<PersonalHomeCard> cards;

  static String _s(dynamic v) => v is String ? v : '';

  /// Accepts both backends: 顺时 ({greeting, hero, suggestions, streak:{text}, personalization})
  /// and 新能源 ({data:{hero:{greeting,headline,subtext}, cards, streak:int, note, personalized}}).
  factory PersonalHomeData.fromJson(Map<String, dynamic> raw) {
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
      if (st['kind'] == 'streak' && days >= 2 && streakText.isEmpty) streakText = _S.days(days);
    } else if (st is num && st >= 2) {
      streakText = _S.days(st.toInt());
    }
    final energyHeadline = _s(hero['headline']);
    return PersonalHomeData(
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
  const PersonalHomeSection({super.key, required this.api, this.onOpen, this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8)});

  final PersonalHomeApi api;

  /// Outer spacing; pages that already pad their content pass [EdgeInsets.zero].
  final EdgeInsets margin;

  /// Called with a card's in-app link (新能源 only) when the card is tapped.
  final void Function(PersonalHomeCard card)? onOpen;

  @override
  State<PersonalHomeSection> createState() => _PersonalHomeSectionState();
}

class _PersonalHomeSectionState extends State<PersonalHomeSection> {
  _Phase _phase = _Phase.loading;
  PersonalHomeData? _data;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _phase = _Phase.loading);
    try {
      final data = PersonalHomeData.fromJson(await widget.api.load());
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
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text(_S.saveFailed)));
    }
  }

  Future<void> _askTurnOff() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(_S.confirmTitle),
        content: const Text(_S.confirmBody),
        actions: [
          TextButton(key: const Key('personal-home-cancel'), onPressed: () => Navigator.of(ctx).pop(false), child: const Text(_S.cancel)),
          FilledButton(key: const Key('personal-home-confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: const Text(_S.confirm)),
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
        return const _Skeleton();
      case _Phase.error:
        return _Message(
          key: const Key('personal-home-error'),
          icon: Icons.cloud_off_rounded,
          title: _S.errorTitle,
          body: _S.errorBody,
          action: TextButton(key: const Key('personal-home-retry'), onPressed: _load, child: const Text(_S.retry)),
        );
      case _Phase.off:
        return _Message(
          key: const Key('personal-home-off'),
          icon: Icons.tune_rounded,
          title: _S.offTitle,
          body: _S.offBody,
          action: FilledButton.tonal(key: const Key('personal-home-turn-on'), onPressed: _saving ? null : () => _toggle(true), child: const Text(_S.turnOn)),
        );
      case _Phase.empty:
        return _Message(key: const Key('personal-home-empty'), icon: Icons.spa_outlined, title: _S.emptyTitle, body: _S.emptyBody, action: _offButton());
      case _Phase.ready:
        return _content(context, _data!);
    }
  }

  Widget _offButton() => TextButton.icon(
        key: const Key('personal-home-turn-off'),
        onPressed: _saving ? null : _askTurnOff,
        icon: const Icon(Icons.tune_rounded, size: 16),
        label: const Text(_S.turnOff),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      );

  Widget _content(BuildContext context, PersonalHomeData d) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_S.heading, style: text.labelMedium?.copyWith(color: scheme.primary, letterSpacing: _zh ? 1 : 0.4, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (d.greeting.isNotEmpty) Text(d.greeting, key: const Key('personal-home-greeting'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (d.headline.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(d.headline, key: const Key('personal-home-headline'), style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        if (d.streakText.isNotEmpty) ...[
          const SizedBox(height: 8),
          _StreakChip(text: d.streakText),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < d.cards.length; i++) ...[
          _CardTile(card: d.cards[i], featured: i == 0, onTap: widget.onOpen == null || d.cards[i].href == null ? null : () => widget.onOpen!(d.cards[i])),
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

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.featured, this.onTap});
  final PersonalHomeCard card;
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(_iconFor(card.kind), size: 20, color: scheme.primary),
        ),
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
              Text(_S.minutes(card.minutes!), style: text.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
            ],
            if (card.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${_S.why}  ', style: const TextStyle(fontWeight: FontWeight.w600)),
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
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    Widget bar(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)));
    return Semantics(
      label: '加载中',
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
