import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/config/app_config.dart';
import 'package:shunshi/core/network/api_client.dart';

void main() {
  const bases = <String>[
    'http://10.0.2.2:4000',
    'http://10.0.2.2:4000/',
    'http://10.0.2.2:4000/api/v1',
    'http://10.0.2.2:4000/api/v1/',
  ];
  const paths = <String>[
    '/solar-wellness/daily-advice',
    '/seasons/home/dashboard',
    '/contents/recommend',
    'contents/recommend',
    '/api/v1/auth/sms/verify',
    '/api/v1/auth/sms/send',
  ];

  test('versioned join is idempotent with or without /api/v1 and a trailing slash', () {
    for (final base in bases) {
      for (final path in paths) {
        final url = resolveVersionedApiUrl(base, path);
        expect(url, isNot(contains('/api/v1/api/v1')), reason: '$base + $path');
        expect(url.startsWith('http://10.0.2.2:4000/api/v1/'), isTrue, reason: url);
      }
    }

    expect(
      resolveVersionedApiUrl('http://10.0.2.2:4000/api/v1', '/solar-wellness/daily-advice'),
      'http://10.0.2.2:4000/api/v1/solar-wellness/daily-advice',
    );
    expect(
      resolveVersionedApiUrl('http://10.0.2.2:4000/', '/seasons/home/dashboard'),
      'http://10.0.2.2:4000/api/v1/seasons/home/dashboard',
    );
    expect(
      resolveVersionedApiUrl('http://10.0.2.2:4000/api/v1/', '/contents/recommend'),
      'http://10.0.2.2:4000/api/v1/contents/recommend',
    );
    expect(
      resolveVersionedApiUrl('http://10.0.2.2:4000', '/api/v1/auth/sms/verify'),
      'http://10.0.2.2:4000/api/v1/auth/sms/verify',
    );
    expect(
      resolveVersionedApiUrl('http://10.0.2.2:4000/api/v1/', '/api/v1/auth/sms/send'),
      'http://10.0.2.2:4000/api/v1/auth/sms/send',
    );
  });

  test('ApiClient stores an origin so a versioned path is not prefixed twice', () {
    for (final base in bases) {
      final client = ApiClient(baseUrl: base);
      expect(client.resolvedBaseUrl, 'http://10.0.2.2:4000');
      expect(
        resolveVersionedApiUrl(client.resolvedBaseUrl, '/solar-wellness/daily-advice'),
        'http://10.0.2.2:4000/api/v1/solar-wellness/daily-advice',
      );
      expect(
        resolveVersionedApiUrl(client.resolvedBaseUrl, '/api/v1/auth/sms/verify'),
        'http://10.0.2.2:4000/api/v1/auth/sms/verify',
      );
    }
  });
}
