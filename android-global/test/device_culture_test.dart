import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/culture/device_hints.dart';
import 'package:seasons/core/culture/opening_greeting.dart';
import 'package:seasons/core/day_part/day_part.dart';
import 'package:seasons/core/utils/hemisphere_service.dart';
import 'package:seasons/presentation/pages/settings/culture_settings_page.dart';

String allText(WidgetTester t) => t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? w.textSpan?.toPlainText() ?? '').join(' ');

void main() {
  group('hemisphere from the device', () {
    test('daylight saving in January means south, in July means north', () {
      expect(detectHemisphere(janOffset: 660, julOffset: 600), Hemisphere.south); // Sydney
      expect(detectHemisphere(janOffset: -180, julOffset: -240), Hemisphere.south); // Santiago, clocks forward in January
      expect(detectHemisphere(janOffset: -300, julOffset: -240), Hemisphere.north); // New York
      expect(detectHemisphere(janOffset: 60, julOffset: 120), Hemisphere.north); // Berlin
    });
    test('no daylight saving: region decides; equatorial or unknown regions stay undetected', () {
      expect(detectHemisphere(janOffset: 600, julOffset: 600, countryCode: 'AU'), Hemisphere.south); // Brisbane
      expect(detectHemisphere(janOffset: 120, julOffset: 120, countryCode: 'ZA'), Hemisphere.south);
      expect(detectHemisphere(janOffset: 540, julOffset: 540, countryCode: 'jp'), Hemisphere.north);
      expect(detectHemisphere(janOffset: 480, julOffset: 480, countryCode: 'SG'), isNull);
      expect(detectHemisphere(janOffset: 420, julOffset: 420, countryCode: 'ID'), isNull);
      expect(detectHemisphere(janOffset: 0, julOffset: 0), isNull);
      expect(detectHemisphere(janOffset: 0, julOffset: 0, countryCode: ''), isNull);
    });
    test('the time zone offset is minutes east of UTC', () {
      final h = readDeviceHints(now: DateTime.utc(2026, 10, 31), countryCode: 'US');
      expect(h.utcOffsetMinutes, DateTime.utc(2026, 10, 31).timeZoneOffset.inMinutes);
    });
  });

  group('resolver and sync', () {
    setUp(() {
      HemisphereResolver.reset();
      DeviceCultureSync.reset();
    });

    test('user/server value wins over the device guess; north is the last resort', () {
      expect(HemisphereResolver.current(deviceGuess: Hemisphere.south), Hemisphere.south);
      HemisphereResolver.rememberFromProfile({'hemisphere': 'north'});
      expect(HemisphereResolver.current(deviceGuess: Hemisphere.south), Hemisphere.north);
      HemisphereResolver.reset();
      HemisphereResolver.rememberFromProfile({'hemisphere': null});
      expect(HemisphereResolver.current(deviceGuess: null), anyOf(Hemisphere.north, Hemisphere.south));
    });

    test('sends the hints once per session, remembers what the server kept, force re-sends', () async {
      final calls = <Map<String, dynamic>>[];
      Future<Map<String, dynamic>> put(Map<String, dynamic> b) async {
        calls.add(b);
        return {'hemisphere': 'north', 'hemisphere_source': 'user'}; // the server kept the user's own choice
      }

      const hints = DeviceHints(hemisphere: Hemisphere.south, utcOffsetMinutes: 600);
      final first = await DeviceCultureSync.run(put, hints: hints);
      expect(calls.single, {'hemisphere': 'south', 'utc_offset_minutes': 600});
      expect(first!['hemisphere'], 'north');
      expect(HemisphereResolver.current(), Hemisphere.north);
      expect(await DeviceCultureSync.run(put, hints: hints), isNull);
      expect(calls.length, 1);
      await DeviceCultureSync.run(put, hints: hints, force: true);
      expect(calls.last, {'hemisphere': 'south', 'utc_offset_minutes': 600, 'force': true});
    });

    test('an undetected hemisphere is not sent; a failing call is silent and retried next time', () async {
      var n = 0;
      Future<Map<String, dynamic>> bad(Map<String, dynamic> b) async {
        n++;
        expect(b.containsKey('hemisphere'), isFalse);
        throw StateError('offline');
      }

      const hints = DeviceHints(hemisphere: null, utcOffsetMinutes: 480);
      expect(await DeviceCultureSync.run(bad, hints: hints), isNull);
      expect(await DeviceCultureSync.run(bad, hints: hints), isNull);
      expect(n, 2);
    });
  });

  group('opening card and home season line', () {
    const term = 'Frost Descent';
    const desc = 'Late autumn. Keep warm, sleep earlier and enjoy warm seasonal food.';

    test('north keeps the solar-term wording', () {
      final g = openingGreeting(termName: term, termDesc: desc, hemisphere: Hemisphere.north, now: DateTime(2026, 10, 31));
      expect(g.text, contains(term));
      expect(g.cardTitle, 'Now: Frost Descent');
      expect(g.cardSubtitle, desc);
    });

    test('south names the local season, never northern wording', () {
      final cases = {
        DateTime(2026, 10, 31): 'spring',
        DateTime(2026, 1, 15): 'summer',
        DateTime(2026, 4, 10): 'autumn',
        DateTime(2026, 7, 20): 'winter',
      };
      cases.forEach((date, season) {
        final g = openingGreeting(termName: term, termDesc: desc, hemisphere: Hemisphere.south, now: date);
        expect(g.text.toLowerCase(), contains("it's $season where you are"));
        expect(g.cardTitle.toLowerCase(), contains(season));
        expect(g.cardTitle, contains('southern hemisphere'));
        for (final s in [g.text, g.cardTitle, g.cardSubtitle]) {
          expect(s, isNot(contains(term)));
          expect(s.toLowerCase(), isNot(contains('late autumn')), reason: season);
        }
      });
    });

    test('home season line: table text for the north, local season and stage for the south', () {
      expect(homeSeasonPill(termName: term, northSeasonLabel: 'Late Autumn', hemisphere: Hemisphere.north, now: DateTime(2026, 10, 31)), 'Frost Descent \u00b7 Late Autumn');
      String south(DateTime d) => homeSeasonPill(termName: term, northSeasonLabel: 'Late Autumn', hemisphere: Hemisphere.south, now: d);
      expect(south(DateTime(2026, 9, 10)), 'Early Spring \u00b7 southern hemisphere');
      expect(south(DateTime(2026, 10, 31)), 'Mid Spring \u00b7 southern hemisphere');
      expect(south(DateTime(2026, 11, 30)), 'Late Spring \u00b7 southern hemisphere');
      expect(south(DateTime(2026, 12, 1)), 'Early Summer \u00b7 southern hemisphere');
      expect(south(DateTime(2026, 2, 28)), 'Late Summer \u00b7 southern hemisphere');
      expect(south(DateTime(2026, 7, 1)), 'Mid Winter \u00b7 southern hemisphere');
    });
  });

  group('time of day content replaces the two-hour clock', () {
    final tcm = RegExp(r'meridian|\bqi\b|yang|\byin\b|shichen|gallbladder|bladder|liver|spleen|kidney|intestine|lung|heart meridian|[\u3400-\u9fff]', caseSensitive: false);

    test('every hour of the day has exactly one part, in order', () {
      for (var h = 0; h < 24; h++) {
        final p = dayPartFor(DateTime(2026, 10, 31, h));
        final matches = dayParts.where((x) => identical(x, p)).length;
        expect(matches, 1, reason: 'hour $h');
      }
      expect(dayPartFor(DateTime(2026, 10, 31, 15)).name, 'Afternoon');
      expect(dayPartFor(DateTime(2026, 10, 31, 23)).name, 'Night');
      expect(dayPartFor(DateTime(2026, 10, 31, 2)).name, 'Night');
      expect(dayPartFor(DateTime(2026, 10, 31, 5)).name, 'Early morning');
      expect(dayPartFor(DateTime(2026, 10, 31, 12)).name, 'Midday');
    });

    test('display strings and no traditional-medicine terms anywhere', () {
      expect(dayPartFor(DateTime(2026, 10, 31, 15)).timeDisplay, '14:00 - 18:00');
      expect(dayPartFor(DateTime(2026, 10, 31, 23)).timeDisplay, '22:00 - 05:00');
      expect(dayPartFor(DateTime(2026, 10, 31, 15)).headline, 'Afternoon · Keep moving');
      for (final p in dayParts) {
        final text = [p.name, p.focus, p.principle, p.principleShort, p.wellnessPrinciple, p.aiQuote, for (final a in p.actions) ...[a.title, a.description]].join(' | ');
        expect(tcm.hasMatch(text), isFalse, reason: '${p.name}: ${tcm.firstMatch(text)?.group(0)}');
        expect(p.actions, isNotEmpty);
      }
    });
  });

  group('culture settings page: device-detected vs chosen hemisphere', () {
    Widget host(Future<Map<String, dynamic>> Function() load, Future<Map<String, dynamic>> Function(Map<String, dynamic>) save, {Future<Map<String, dynamic>> Function()? useDevice}) =>
        MaterialApp(home: CultureSettingsPage(load: load, save: save, useDevice: useDevice));

    void tall(WidgetTester t) {
      t.view.physicalSize = const Size(800, 2600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
    }

    testWidgets('a device value says so, and saving something else keeps it a device value', (t) async {
      tall(t);
      Map<String, dynamic>? sent;
      await t.pumpWidget(host(
        () async => {'diet': [], 'observances': [], 'units': null, 'hemisphere': 'south', 'hemisphere_source': 'device'},
        (b) async {
          sent = b;
          return {...b, 'hemisphere_source': 'device'};
        },
      ));
      await t.pumpAndSettle();
      expect(allText(t), contains('Detected from this device'));
      await t.tap(find.byKey(const Key('culture-diet-vegan')));
      await t.pump();
      await t.tap(find.byKey(const Key('culture-save')));
      await t.pumpAndSettle();
      expect(sent!['hemisphere'], 'south');
      expect(sent!['hemisphere_source'], 'device');
    });

    testWidgets('picking a hemisphere makes it the user\'s; a chosen one offers "Use my device setting"', (t) async {
      tall(t);
      Map<String, dynamic>? sent;
      var used = 0;
      await t.pumpWidget(host(
        () async => {'diet': [], 'observances': [], 'units': null, 'hemisphere': 'south', 'hemisphere_source': 'device'},
        (b) async {
          sent = b;
          return {...b, 'hemisphere_source': 'user'};
        },
        useDevice: () async {
          used++;
          return {'diet': [], 'observances': [], 'units': null, 'hemisphere': 'south', 'hemisphere_source': 'device'};
        },
      ));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('culture-use-device')), findsNothing, reason: 'already the device value');
      await t.tap(find.text('Northern'));
      await t.pump();
      await t.tap(find.byKey(const Key('culture-save')));
      await t.pumpAndSettle();
      expect(sent!.containsKey('hemisphere_source'), isFalse, reason: 'user choices carry no device marker');
      expect(allText(t), contains('You chose this'));
      await t.tap(find.byKey(const Key('culture-use-device')));
      await t.pumpAndSettle();
      expect(used, 1);
      expect(allText(t), contains('Detected from this device'));
      expect(find.byKey(const Key('culture-use-device')), findsNothing);
    });

    testWidgets('nothing set: says the device fills it in unless the user chooses', (t) async {
      tall(t);
      await t.pumpWidget(host(() async => {'diet': [], 'observances': [], 'units': null, 'hemisphere': null}, (b) async => b, useDevice: () async => {}));
      await t.pumpAndSettle();
      expect(allText(t), contains('Your device will fill it in automatically unless you choose'));
      expect(find.byKey(const Key('culture-use-device')), findsOneWidget);
    });
  });
}
