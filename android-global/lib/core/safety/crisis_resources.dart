/// Crisis helplines for the international edition, by region.
///
/// Mirrors backend/app/safety/crisis_resources.py (the single source of truth;
/// backend/tests/test_crisis_resources_clients.py fails if the two drift apart).
/// Every entry was checked against the operator's own page on 2026-10-31.
/// Regions we have not verified get the findahelpline.com directory plus
/// "your local emergency number" - we never guess a number.
library;

class CrisisResource {
  const CrisisResource({
    required this.region,
    required this.name,
    required this.contact,
    required this.emergency,
    required this.sourceUrl,
  });

  final String region;
  final String name;
  final String contact;
  final String emergency;
  final String sourceUrl;
}

class CrisisResources {
  const CrisisResources._();

  static const directoryUrl = 'https://findahelpline.com';
  static const genericEmergency = 'your local emergency number';

  static const Map<String, CrisisResource> byRegion = {
    'US': CrisisResource(
      region: 'US',
      name: '988 Suicide & Crisis Lifeline',
      contact: 'call or text 988, or chat at 988lifeline.org',
      emergency: '911',
      sourceUrl: 'https://988lifeline.org/get-help/',
    ),
    'CA': CrisisResource(
      region: 'CA',
      name: '9-8-8 Suicide Crisis Helpline',
      contact: 'call or text 9-8-8',
      emergency: '911',
      sourceUrl: 'https://988.ca/',
    ),
    'GB': CrisisResource(
      region: 'GB',
      name: 'Samaritans',
      contact: 'call 116 123 (free from any phone)',
      emergency: '999',
      sourceUrl: 'https://www.samaritans.org/how-we-can-help/contact-samaritan/talk-us-phone/',
    ),
    'IE': CrisisResource(
      region: 'IE',
      name: 'Samaritans Ireland',
      contact: 'call 116 123 (free)',
      emergency: '112 or 999',
      sourceUrl: 'https://www.samaritans.org/samaritans-ireland/',
    ),
    'AU': CrisisResource(
      region: 'AU',
      name: 'Lifeline Australia',
      contact: 'call 13 11 14, or text 0477 13 11 14',
      emergency: '000',
      sourceUrl: 'https://www.lifeline.org.au/131114',
    ),
    'NZ': CrisisResource(
      region: 'NZ',
      name: '1737, Need to talk?',
      contact: 'call or text 1737 (free)',
      emergency: '111',
      sourceUrl: 'https://www.1737.org.nz/how-1737-works',
    ),
  };

  /// [countryCode] is the device locale's country (for example `Locale.countryCode`).
  static CrisisResource? forRegion(String? countryCode) =>
      byRegion[(countryCode ?? '').toUpperCase()];

  /// Lines to show a user in that region. Unknown region: directory + local emergency number.
  static List<String> lines(String? countryCode) {
    final r = forRegion(countryCode);
    if (r == null) {
      return [
        'Free, confidential helplines by country: $directoryUrl',
        'In immediate danger, call $genericEmergency.',
      ];
    }
    return [
      '${r.name}: ${r.contact}',
      'In immediate danger, call ${r.emergency}.',
    ];
  }
}
