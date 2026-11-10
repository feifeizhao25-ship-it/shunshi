import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

Future<WeatherSnapshot> fetchLiveWeather(String city) async {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final res = await dio.get('/api/v1/weather-wellness/live', queryParameters: {'city': city});
  final data = Map<String, dynamic>.from(res.data['data'] as Map);
  return WeatherSnapshot(
    city: '${data['city']}',
    source: '${data['source']}',
    updatedAt: '${data['updated_at']}',
    summary: '${data['summary']}',
  );
}

class WeatherSnapshot {
  final String city;
  final String source;
  final String updatedAt;
  final String summary;

  const WeatherSnapshot({
    required this.city,
    required this.source,
    required this.updatedAt,
    required this.summary,
  });
}

class WeatherBoard extends StatefulWidget {
  final Future<WeatherSnapshot> Function(String city) load;
  final List<String> cities;

  const WeatherBoard({
    super.key,
    required this.load,
    this.cities = const ['北京', '上海'],
  });

  @override
  State<WeatherBoard> createState() => _WeatherBoardState();
}

class _WeatherBoardState extends State<WeatherBoard> {
  late String _city = widget.cities.first;
  WeatherSnapshot? _snap;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final next = await widget.load(_city);
    if (!mounted) return;
    setState(() => _snap = next);
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          key: const Key('weather-city'),
          value: _city,
          items: [for (final city in widget.cities) DropdownMenuItem(value: city, child: Text(city))],
          onChanged: (city) {
            if (city == null || city == _city) return;
            setState(() => _city = city);
            _refresh();
          },
        ),
        if (snap != null) ...[
          Text(snap.summary, key: const Key('weather-summary')),
          Text('来源：${snap.source}', key: const Key('weather-source')),
          Text(snap.updatedAt, key: const Key('weather-updated')),
        ],
      ],
    );
  }
}
