// lib/core/utils/hemisphere_service.dart
// SEASONS Hemisphere Awareness Service
// Maps current month to the correct season based on hemisphere

/// Hemisphere type
enum Hemisphere {
  north, // Northern hemisphere — spring = Mar-May
  south, // Southern hemisphere — spring = Sep-Nov
}

/// Season
enum SeasonType {
  spring,
  summer,
  autumn,
  winter,
}

/// Hemisphere-aware season service
class HemisphereService {
  /// Get current season based on hemisphere
  static SeasonType getCurrentSeason({
    required Hemisphere hemisphere,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final month = now.month;

    if (hemisphere == Hemisphere.north) {
      return _northernSeason(month);
    } else {
      return _southernSeason(month);
    }
  }

  /// Northern hemisphere seasonal mapping
  static SeasonType _northernSeason(int month) {
    if (month >= 3 && month <= 5) return SeasonType.spring;
    if (month >= 6 && month <= 8) return SeasonType.summer;
    if (month >= 9 && month <= 11) return SeasonType.autumn;
    return SeasonType.winter; // Dec, Jan, Feb
  }

  /// Southern hemisphere seasonal mapping (inverted)
  static SeasonType _southernSeason(int month) {
    if (month >= 9 && month <= 11) return SeasonType.spring;
    if (month >= 12 || month <= 2) return SeasonType.summer;
    if (month >= 3 && month <= 5) return SeasonType.autumn;
    return SeasonType.winter; // Jun, Jul, Aug
  }

  /// Get season display name
  static String getSeasonName(SeasonType season) {
    switch (season) {
      case SeasonType.spring: return 'Spring';
      case SeasonType.summer: return 'Summer';
      case SeasonType.autumn: return 'Autumn';
      case SeasonType.winter: return 'Winter';
    }
  }

  /// Get season emoji
  static String getSeasonEmoji(SeasonType season) {
    switch (season) {
      case SeasonType.spring: return '🌸';
      case SeasonType.summer: return '☀️';
      case SeasonType.autumn: return '🍂';
      case SeasonType.winter: return '❄️';
    }
  }

  /// Get season greeting
  static String getSeasonGreeting(SeasonType season) {
    switch (season) {
      case SeasonType.spring:
        return 'Spring is a season of renewal. Let\'s grow together.';
      case SeasonType.summer:
        return 'Summer\'s energy invites presence and vitality.';
      case SeasonType.autumn:
        return 'Autumn asks us to let go and find stillness.';
      case SeasonType.winter:
        return 'Winter is for rest, reflection, and restoration.';
    }
  }

  /// Get API season string
  static String getApiSeasonString(SeasonType season) => season.name;

  /// Parse hemisphere from string
  static Hemisphere parseHemisphere(String value) {
    if (value.toLowerCase() == 'south') return Hemisphere.south;
    return Hemisphere.north;
  }

  /// Get hemisphere display name
  static String getHemisphereName(Hemisphere hemisphere) {
    return hemisphere == Hemisphere.north
        ? 'Northern Hemisphere'
        : 'Southern Hemisphere';
  }

  /// Determine likely hemisphere from country code (best-effort)
  static Hemisphere guessHemisphereFromCountry(String? countryCode) {
    const southernCountries = {
      'AU', 'NZ', 'ZA', 'AR', 'CL', 'BR', 'PE', 'BO', 'PY', 'UY',
      'ZW', 'ZM', 'TZ', 'MZ', 'MW', 'MG', 'BW', 'NA',
    };
    if (countryCode == null) return Hemisphere.north;
    return southernCountries.contains(countryCode.toUpperCase())
        ? Hemisphere.south
        : Hemisphere.north;
  }
}
