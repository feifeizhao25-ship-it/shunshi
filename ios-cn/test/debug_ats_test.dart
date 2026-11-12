import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug Info.plist allows localhost cleartext and release does not', () {
    final release = File('ios/Runner/Info.plist').readAsStringSync();
    final debug = File('ios/Runner/Info-Debug.plist').readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(release.contains('NSAppTransportSecurity'), isFalse);
    expect(release.contains('NSAllowsArbitraryLoads'), isFalse);
    expect(release.contains('NSAllowsLocalNetworking'), isFalse);

    expect(
      RegExp(r'<key>NSAllowsArbitraryLoads</key>\s*<false/>').hasMatch(debug),
      isTrue,
    );
    expect(debug.contains('<key>NSAllowsLocalNetworking</key>'), isTrue);
    expect(
      RegExp(r'<key>NSAllowsLocalNetworking</key>\s*<true/>').hasMatch(debug),
      isTrue,
    );
    expect(debug.contains('<key>localhost</key>'), isTrue);
    expect(debug.contains('<key>NSExceptionAllowsInsecureHTTPLoads</key>'), isTrue);

    final debugBlock = project
        .split('97C147061CF9000F007C117D /* Debug */ = {')[1]
        .split('name = Debug;')
        .first;
    final releaseBlock = project
        .split('97C147071CF9000F007C117D /* Release */ = {')[1]
        .split('name = Release;')
        .first;
    expect(debugBlock.contains('INFOPLIST_FILE = Runner/Info-Debug.plist;'), isTrue);
    expect(debugBlock.contains('INFOPLIST_FILE = Runner/Info.plist;'), isFalse);
    expect(releaseBlock.contains('INFOPLIST_FILE = Runner/Info.plist;'), isTrue);
    expect(releaseBlock.contains('Info-Debug.plist'), isFalse);
  });
}
