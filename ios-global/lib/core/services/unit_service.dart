import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit system preference: metric (default) or imperial
/// Singleton pattern for use across the app
class UnitService {
  static const _key = 'unit_system';

  static final UnitService instance = UnitService._();
  UnitService._();

  bool _isMetric = true;
  bool get isMetric => _isMetric;

  final _notifier = ValueNotifier<bool>(true);
  ValueNotifier<bool> get notifier => _notifier;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isMetric = prefs.getString(_key) != 'imperial';
    _notifier.value = _isMetric;
  }

  Future<void> setMetric(bool metric) async {
    _isMetric = metric;
    _notifier.value = metric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, metric ? 'metric' : 'imperial');
  }

  // ── Temperature ──
  String temp(double celsius) {
    if (_isMetric) return '${celsius.round()}°C';
    return '${(celsius * 9 / 5 + 32).round()}°F';
  }

  // ── Weight ──
  String weight(double kg) {
    if (_isMetric) return '${kg.toStringAsFixed(1)} kg';
    return '${(kg * 2.20462).toStringAsFixed(1)} lb';
  }

  // ── Height / Length ──
  String height(double cm) {
    if (_isMetric) return '${cm.round()} cm';
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return "$feet'$inches\"";
  }

  // ── Distance ──
  String distance(double km) {
    if (_isMetric) return '${km.toStringAsFixed(1)} km';
    return '${(km * 0.621371).toStringAsFixed(1)} mi';
  }
}
