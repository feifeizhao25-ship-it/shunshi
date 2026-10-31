import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "Plan & usage": what the plan includes and how much was used today.
/// Everything comes from the backend ([load]); an unreadable counter is shown as unavailable, never as zero.
class PlanUsagePage extends StatefulWidget {
  const PlanUsagePage({super.key, required this.load, this.onUpgrade});

  final Future<Map<String, dynamic>> Function() load;

  /// Opens the plans screen; the button only shows on the free plan.
  final VoidCallback? onUpgrade;

  @override
  State<PlanUsagePage> createState() => _PlanUsagePageState();
}

/// "Daily limits reset today at 11:00 PM." in the device's own time zone (English only). The server counts days in
/// Beijing time, so it sends the exact reset instant (`resets_at`, UTC) and the app shows when that is *for you*.
/// Returns null when the instant is missing or unreadable (the caller then falls back to the server's note).
@visibleForTesting
String? planResetLine(Object? resetsAt, {DateTime? now}) {
  final at = DateTime.tryParse('${resetsAt ?? ''}')?.toLocal();
  if (at == null) return null;
  final today = (now ?? DateTime.now()).toLocal();
  final time = DateFormat.jm('en_US').format(at);
  final dayDiff = DateTime(at.year, at.month, at.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (dayDiff <= 0) return 'Daily limits reset today at $time.';
  if (dayDiff == 1) return 'Daily limits reset tomorrow at $time.';
  return 'Daily limits reset on ${DateFormat.MMMd('en_US').format(at)} at $time.';
}

class _S {
  const _S._();
  static const title = 'Plan & usage';
  static const plan = 'Your plan';
  static String until(String d) => 'Active until $d';
  static const free = 'You are on the free plan';
  static const upgrade = 'See plans';
  static const today = 'Today\'s usage';
  static const unlimited = 'Unlimited';
  static String used(int u, int l) => '$u of $l used';
  static String limitOnly(int l) => 'Up to $l per day';
  static String left(int n) => '$n left';
  static const unknown = 'Usage unavailable right now';
  static const errorTitle = 'Could not load your plan';
  static const errorBody = 'Check your connection and try again.';
  static const retry = 'Try again';
  static String label(String key) {
    switch (key) {
      case 'chat_messages':
        return 'AI chat messages today';
      case 'reflections':
        return 'Journal entries today';
      case 'audio_minutes':
        return 'Audio minutes today';
    }
    return key;
  }
}

class _PlanUsagePageState extends State<PlanUsagePage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  static String _date(dynamic epochSeconds) {
    if (epochSeconds is! num) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(epochSeconds.toInt() * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_S.title)),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(key: Key('plan-usage-loading')));
    }
    final d = _data;
    if (_error || d == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(key: const Key('plan-usage-error'), mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 36, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(_S.errorTitle, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(_S.errorBody, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton.tonal(key: const Key('plan-usage-retry'), onPressed: _fetch, child: const Text(_S.retry)),
          ]),
        ),
      );
    }
    final active = d['active'] == true;
    final items = (d['items'] is List ? d['items'] as List : const []).whereType<Map>().toList();
    final until = _date(d['expires_at']);
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            key: const Key('plan-usage-plan'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(active ? Icons.workspace_premium_outlined : Icons.spa_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_S.plan, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  Text('${d['plan_name'] ?? ''}', key: const Key('plan-usage-name'), style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(active && until.isNotEmpty ? _S.until(until) : (active ? '' : _S.free), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ),
              if (!active && widget.onUpgrade != null) FilledButton(key: const Key('plan-usage-upgrade'), onPressed: widget.onUpgrade, child: const Text(_S.upgrade)),
            ]),
          ),
          const SizedBox(height: 20),
          Text(_S.today, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final it in items) _UsageRow(item: Map<String, dynamic>.from(it)),
          if ((planResetLine(d['resets_at']) ?? '${d['reset_note'] ?? ''}').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(planResetLine(d['resets_at']) ?? '${d['reset_note']}', key: const Key('plan-usage-reset'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final key = '${item['key']}';
    final unlimited = item['unlimited'] == true;
    final limit = item['limit'] is num ? (item['limit'] as num).toInt() : null;
    final used = item['used_known'] == true && item['used'] is num ? (item['used'] as num).toInt() : null;
    final remaining = item['remaining'] is num ? (item['remaining'] as num).toInt() : null;
    String summary;
    double? fraction;
    if (unlimited) {
      summary = _S.unlimited;
    } else if (limit == null) {
      summary = _S.unknown;
    } else if (used == null) {
      summary = _S.limitOnly(limit);
    } else {
      summary = _S.used(used, limit);
      fraction = limit == 0 ? 1 : (used / limit).clamp(0.0, 1.0);
    }
    final label = _S.label(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        container: true,
        label: '$label. $summary',
        child: ExcludeSemantics(
          child: Column(key: Key('plan-usage-row-$key'), crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label, style: text.bodyLarge)),
              Text(summary, key: Key('plan-usage-summary-$key'), style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: unlimited ? 0 : (fraction ?? 0), minHeight: 8, backgroundColor: scheme.surfaceContainerHighest), // never indeterminate: unknown is an empty bar, not a spinner
            ),
            if (remaining != null && !unlimited)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(_S.left(remaining), key: Key('plan-usage-left-$key'), style: text.bodySmall?.copyWith(color: scheme.primary))),
            if (!unlimited && limit != null && used == null)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(_S.unknown, key: Key('plan-usage-unknown-$key'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          ]),
        ),
      ),
    );
  }
}
