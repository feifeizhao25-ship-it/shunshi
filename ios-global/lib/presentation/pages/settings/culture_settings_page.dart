import 'package:flutter/material.dart';

/// Optional "Culture & units" preferences for the international edition.
///
/// What it saves: diet pattern, observances, units and hemisphere, chosen from fixed lists. Nothing is inferred and
/// nothing is set until the user saves. The backend gives them to the assistant as reference so advice respects them
/// (for example no snacking suggestions during daylight hours when fasting), and uses the hemisphere for the seasons
/// on the home page. All of it can be cleared with one button.
class CultureSettingsPage extends StatefulWidget {
  const CultureSettingsPage({super.key, required this.load, required this.save});

  /// GET /api/v1/profile/culture
  final Future<Map<String, dynamic>> Function() load;

  /// PUT /api/v1/profile/culture with {diet, observances, units, hemisphere}; returns the saved profile.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body) save;

  @override
  State<CultureSettingsPage> createState() => _CultureSettingsPageState();
}

const _dietLabels = <String, String>{
  'halal': 'Halal',
  'kosher': 'Kosher',
  'vegetarian': 'Vegetarian',
  'vegan': 'Vegan',
  'pescatarian': 'Pescatarian',
  'gluten_free': 'Gluten-free',
  'dairy_free': 'Dairy-free',
  'no_alcohol': 'No alcohol',
};
const _observanceLabels = <String, String>{
  'ramadan_fasting': 'Ramadan fasting',
  'lent_fasting': 'Lent fasting',
  'sabbath_rest': 'Weekly Sabbath rest',
};

class _CultureSettingsPageState extends State<CultureSettingsPage> {
  bool _loading = true;
  bool _error = false;
  bool _saving = false;
  Set<String> _diet = {};
  Set<String> _observances = {};
  String? _units;
  String? _hemisphere;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _apply(Map<String, dynamic> d) {
    _diet = {for (final v in (d['diet'] is List ? d['diet'] as List : const [])) '$v'}.intersection(_dietLabels.keys.toSet());
    _observances = {for (final v in (d['observances'] is List ? d['observances'] as List : const [])) '$v'}.intersection(_observanceLabels.keys.toSet());
    _units = d['units'] == 'metric' || d['units'] == 'imperial' ? d['units'] as String : null;
    _hemisphere = d['hemisphere'] == 'north' || d['hemisphere'] == 'south' ? d['hemisphere'] as String : null;
    _dirty = false;
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
        _apply(d);
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

  Map<String, dynamic> _body() => {
        'diet': _diet.toList()..sort(),
        'observances': _observances.toList()..sort(),
        'units': _units,
        'hemisphere': _hemisphere,
      };

  Future<void> _submit(Map<String, dynamic> body, String done) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.save(body);
      if (!mounted) return;
      setState(() {
        _apply(saved);
        _saving = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Could not save. Please try again.')));
    }
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear these preferences?'),
        content: const Text('The assistant will stop using them. You can set them again any time.'),
        actions: [
          TextButton(key: const Key('culture-clear-cancel'), onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(key: const Key('culture-clear-confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) await _submit({'diet': [], 'observances': [], 'units': null, 'hemisphere': null}, 'Preferences cleared');
  }

  bool get _hasAny => _diet.isNotEmpty || _observances.isNotEmpty || _units != null || _hemisphere != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Culture & units')),
      body: SafeArea(child: _body2(context)),
    );
  }

  Widget _body2(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (_loading) return const Center(child: CircularProgressIndicator(key: Key('culture-loading')));
    if (_error) {
      return Center(
        child: Column(key: const Key('culture-error'), mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          const Text('Could not load your preferences'),
          const SizedBox(height: 12),
          FilledButton.tonal(key: const Key('culture-retry'), onPressed: _fetch, child: const Text('Try again')),
        ]),
      );
    }
    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ]),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          key: const Key('culture-note'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
          child: Text(
            'Optional. These choices are only used to make wellness suggestions fit you. Nothing is set unless you save it, and you can clear everything below.',
            style: text.bodyMedium?.copyWith(color: scheme.onSecondaryContainer, height: 1.35),
          ),
        ),
        section(
          'Eating pattern',
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in _dietLabels.entries)
              FilterChip(
                key: Key('culture-diet-${e.key}'),
                label: Text(e.value),
                selected: _diet.contains(e.key),
                onSelected: (v) => setState(() {
                  v ? _diet.add(e.key) : _diet.remove(e.key);
                  _dirty = true;
                }),
              ),
          ]),
        ),
        section(
          'Observances',
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in _observanceLabels.entries)
              FilterChip(
                key: Key('culture-observance-${e.key}'),
                label: Text(e.value),
                selected: _observances.contains(e.key),
                onSelected: (v) => setState(() {
                  v ? _observances.add(e.key) : _observances.remove(e.key);
                  _dirty = true;
                }),
              ),
          ]),
        ),
        section(
          'Units',
          SegmentedButton<String>(
            key: const Key('culture-units'),
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 'metric', label: Text('Metric')),
              ButtonSegment(value: 'imperial', label: Text('Imperial')),
            ],
            selected: {if (_units != null) _units!},
            onSelectionChanged: (s) => setState(() {
              _units = s.isEmpty ? null : s.first;
              _dirty = true;
            }),
          ),
        ),
        section(
          'Hemisphere (for the seasons on your home page)',
          SegmentedButton<String>(
            key: const Key('culture-hemisphere'),
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 'north', label: Text('Northern')),
              ButtonSegment(value: 'south', label: Text('Southern')),
            ],
            selected: {if (_hemisphere != null) _hemisphere!},
            onSelectionChanged: (s) => setState(() {
              _hemisphere = s.isEmpty ? null : s.first;
              _dirty = true;
            }),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('culture-save'),
          onPressed: (_dirty && !_saving) ? () => _submit(_body(), 'Preferences saved') : null,
          child: const Text('Save'),
        ),
        const SizedBox(height: 8),
        TextButton(key: const Key('culture-clear'), onPressed: (_hasAny && !_saving) ? _clear : null, child: const Text('Clear all preferences')),
      ],
    );
  }
}
