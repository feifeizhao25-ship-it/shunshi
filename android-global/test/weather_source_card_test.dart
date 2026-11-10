import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/weather_source_card.dart';

void main() {
  testWidgets('changing city reloads the card with source and updated time', (tester) async {
    final seen = <String>[];
    Future<WeatherSnapshot> load(String city) async {
      seen.add(city);
      return WeatherSnapshot(
        city: city,
        source: 'Open-Meteo',
        updatedAt: city == 'Beijing' ? '2026-11-10T08:00' : '2026-11-10T09:00',
        summary: '$city ${city == 'Beijing' ? 21 : 16}°C',
      );
    }

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WeatherBoard(load: load))));
    await tester.pumpAndSettle();
    expect(find.text('Source: Open-Meteo'), findsOneWidget);
    expect(find.text('2026-11-10T08:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('weather-city')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shanghai').last);
    await tester.pumpAndSettle();

    expect(seen, ['Beijing', 'Shanghai']);
    expect(find.text('Shanghai 16°C'), findsOneWidget);
    expect(find.text('2026-11-10T09:00'), findsOneWidget);
    expect(find.text('Source: Open-Meteo'), findsOneWidget);
  });
}
