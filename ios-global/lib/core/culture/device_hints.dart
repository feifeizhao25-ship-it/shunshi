/// What the device says about where the user is, used only to pre-fill the hemisphere and the time zone offset.
///
/// No location permission and no network: the hemisphere is read from the device time zone (daylight saving
/// observed in January means southern hemisphere, in July means northern) and, when the zone has no daylight
/// saving, from the device region. The user can always override it in Culture & units.
library;

import 'package:flutter/widgets.dart';
import '../utils/hemisphere_service.dart';

/// Regions that lie (almost) entirely south of the equator.
const _southRegions = {
  'AU', 'NZ', 'ZA', 'AR', 'CL', 'UY', 'PY', 'BO', 'PE', 'BR', 'ZW', 'ZM', 'MZ', 'MW', 'MG', 'BW', 'NA', 'LS', 'SZ',
  'AO', 'FJ', 'TO', 'WS', 'VU', 'NC', 'PF', 'RE', 'MU', 'SC', 'KM', 'TL',
};

/// Regions on or very near the equator, where the hemisphere cannot be told from the region alone.
const _equatorRegions = {
  'ID', 'KE', 'EC', 'CO', 'SG', 'MY', 'UG', 'CD', 'CG', 'GA', 'ST', 'SO', 'MV', 'PG', 'TZ', 'RW', 'BI', 'GQ',
};

class DeviceHints {
  const DeviceHints({required this.hemisphere, required this.utcOffsetMinutes});

  /// null when it cannot be told (no daylight saving and an equatorial or unknown region).
  final Hemisphere? hemisphere;

  /// Minutes east of UTC right now.
  final int utcOffsetMinutes;
}

/// [janOffset] / [julOffset]: the device UTC offset on 15 January / 15 July of the same year, in minutes.
Hemisphere? detectHemisphere({required int janOffset, required int julOffset, String? countryCode}) {
  if (janOffset > julOffset) return Hemisphere.south; // clocks are forward in January
  if (janOffset < julOffset) return Hemisphere.north; // clocks are forward in July
  final code = countryCode?.toUpperCase();
  if (code == null || code.isEmpty || _equatorRegions.contains(code)) return null;
  return _southRegions.contains(code) ? Hemisphere.south : Hemisphere.north;
}

DeviceHints readDeviceHints({DateTime? now, String? countryCode}) {
  final t = now ?? DateTime.now();
  final jan = DateTime(t.year, 1, 15, 12).timeZoneOffset.inMinutes;
  final jul = DateTime(t.year, 7, 15, 12).timeZoneOffset.inMinutes;
  final region = countryCode ?? WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  return DeviceHints(
    hemisphere: detectHemisphere(janOffset: jan, julOffset: jul, countryCode: region),
    utcOffsetMinutes: t.timeZoneOffset.inMinutes,
  );
}

/// Remembers the hemisphere for this session so screens that cannot wait for the network (home, chat opening card)
/// use the user's own choice when it is known and the device guess otherwise. North is the last resort, which is
/// also what the server assumes.
class HemisphereResolver {
  HemisphereResolver._();

  static Hemisphere? _known;

  @visibleForTesting
  static void reset() => _known = null;

  static void remember(Hemisphere? hemisphere) {
    if (hemisphere != null) _known = hemisphere;
  }

  static void rememberFromProfile(Map<String, dynamic>? profile) {
    final h = profile?['hemisphere'];
    if (h == 'north' || h == 'south') _known = HemisphereService.parseHemisphere('$h');
  }

  static Hemisphere current({Hemisphere? deviceGuess}) =>
      _known ?? deviceGuess ?? readDeviceHints().hemisphere ?? Hemisphere.north;
}

/// Sends the device hints once per app session; the server decides what to keep (it never replaces a hemisphere
/// the user chose). Failures are silent: this is a convenience, not a requirement.
class DeviceCultureSync {
  DeviceCultureSync._();

  static bool _done = false;

  @visibleForTesting
  static void reset() => _done = false;

  static Future<Map<String, dynamic>?> run(
    Future<Map<String, dynamic>> Function(Map<String, dynamic> body) put, {
    DeviceHints? hints,
    bool force = false,
  }) async {
    if (_done && !force) return null;
    final h = hints ?? readDeviceHints();
    try {
      final profile = await put({
        if (h.hemisphere != null) 'hemisphere': h.hemisphere!.name,
        'utc_offset_minutes': h.utcOffsetMinutes,
        if (force) 'force': true,
      });
      _done = true;
      HemisphereResolver.rememberFromProfile(profile);
      return profile;
    } catch (_) {
      return null;
    }
  }
}
