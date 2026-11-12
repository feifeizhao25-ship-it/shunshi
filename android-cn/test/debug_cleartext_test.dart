import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug cleartext is limited to the local backend hosts', () {
    final mainManifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final debugManifest = File('android/app/src/debug/AndroidManifest.xml').readAsStringSync();
    final config = File('android/app/src/debug/res/xml/network_security_config.xml').readAsStringSync();
    final releaseConfig = File('android/app/src/main/res/xml/network_security_config.xml');

    expect(mainManifest.contains('android:usesCleartextTraffic="false"'), isTrue);
    expect(mainManifest.contains('networkSecurityConfig'), isFalse);
    expect(mainManifest.contains('usesCleartextTraffic="true"'), isFalse);
    expect(debugManifest.contains('android:networkSecurityConfig="@xml/network_security_config"'), isTrue);
    expect(debugManifest.contains('usesCleartextTraffic="true"'), isFalse);
    expect(releaseConfig.existsSync(), isFalse);

    expect(config.contains('<base-config cleartextTrafficPermitted="false" />'), isTrue);
    expect(config.contains('<domain-config cleartextTrafficPermitted="true">'), isTrue);
    for (final host in ['10.0.2.2', '127.0.0.1', 'localhost']) {
      expect(config.contains('<domain includeSubdomains="false">$host</domain>'), isTrue);
    }
  });
}
