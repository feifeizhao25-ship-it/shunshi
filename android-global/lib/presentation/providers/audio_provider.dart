import '../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioItem {
  final String id;
  final String title;
  final String subtitle;
  final String useCase;
  final int durationMinutes;
  final String bestTime;
  final String type; // guided, soundscape
  final List<String> tags;
  final bool isPremium;
  final String? audioUrl;

  const AudioItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.useCase,
    required this.durationMinutes,
    required this.bestTime,
    required this.type,
    required this.tags,
    required this.isPremium,
    this.audioUrl,
  });

  factory AudioItem.fromJson(Map<String, dynamic> json) {
    return AudioItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      useCase: json['use_case'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 5,
      bestTime: json['best_time'] ?? 'any',
      type: json['type'] ?? 'guided',
      tags: List<String>.from(json['tags'] ?? []),
      isPremium: json['is_premium'] ?? false,
      audioUrl: json['audio_url'],
    );
  }
}

class AudioState {
  final List<AudioItem> breathing;
  final List<AudioItem> windDown;
  final List<AudioItem> soundscapes;
  final List<AudioItem> seasonal;
  final List<AudioItem> recommended;
  final bool isLoading;
  final String? error;

  const AudioState({
    this.breathing = const [],
    this.windDown = const [],
    this.soundscapes = const [],
    this.seasonal = const [],
    this.recommended = const [],
    this.isLoading = false,
    this.error,
  });

  AudioState copyWith({
    List<AudioItem>? breathing,
    List<AudioItem>? windDown,
    List<AudioItem>? soundscapes,
    List<AudioItem>? seasonal,
    List<AudioItem>? recommended,
    bool? isLoading,
    String? error,
  }) {
    return AudioState(
      breathing: breathing ?? this.breathing,
      windDown: windDown ?? this.windDown,
      soundscapes: soundscapes ?? this.soundscapes,
      seasonal: seasonal ?? this.seasonal,
      recommended: recommended ?? this.recommended,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final audioBaseUrlProvider = Provider<String>((ref) => AppConstants.baseUrl);

class AudioNotifier extends StateNotifier<AudioState> {
  final Dio _dio;

  AudioNotifier(this._baseUrl) : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )), super(const AudioState()) {
    loadAll();
  }

  final String _baseUrl;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load all audio categories in parallel
      final results = await Future.wait([
        _loadCategory('breathing'),
        _loadCategory('wind_down'),
        _loadCategory('soundscapes'),
        _loadCategory('seasonal'),
        _loadRecommended(),
      ]);

      state = state.copyWith(
        breathing: results[0],
        windDown: results[1],
        soundscapes: results[2],
        seasonal: results[3],
        recommended: results[4],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<AudioItem>> _loadCategory(String type) async {
    try {
      final response = await _dio.get(
        '/api/v1/seasons/audio/list',
        queryParameters: {'type': type, 'limit': 10},
      );
      return (response.data as List)
          .map((item) => AudioItem.fromJson(item))
          .toList();
    } catch (e) {
      return _fallbackAudio(type);
    }
  }

  Future<List<AudioItem>> _loadRecommended() async {
    try {
      final response = await _dio.get(
        '/api/v1/seasons/audio/recommended',
        queryParameters: {'time_of_day': 'evening', 'season': 'spring', 'limit': 3},
      );
      return (response.data as List)
          .map((item) => AudioItem.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<AudioItem> _fallbackAudio(String type) {
    final fallback = {
      'breathing': [
        const AudioItem(id: 'b1', title: '4-7-8 Breathing', subtitle: 'A calming breath', useCase: 'Before sleep', durationMinutes: 5, bestTime: 'evening', type: 'guided', tags: ['anxiety', 'sleep'], isPremium: false),
        const AudioItem(id: 'b2', title: 'Box Breathing', subtitle: 'Equal counts for balance', useCase: 'When overwhelmed', durationMinutes: 4, bestTime: 'any', type: 'guided', tags: ['focus'], isPremium: false),
      ],
      'wind_down': [
        const AudioItem(id: 'w1', title: 'Evening Wind-Down', subtitle: 'Gentle transition', useCase: 'Before bed', durationMinutes: 8, bestTime: 'evening', type: 'guided', tags: ['sleep'], isPremium: false),
      ],
      'soundscapes': [
        const AudioItem(id: 's1', title: 'Gentle Rain', subtitle: 'Steady rainfall', useCase: 'Focus or sleep', durationMinutes: 60, bestTime: 'any', type: 'soundscape', tags: ['focus', 'sleep'], isPremium: false),
      ],
      'seasonal': [
        const AudioItem(id: 'sp1', title: 'Spring Renewal', subtitle: 'Season of beginnings', useCase: 'Spring mornings', durationMinutes: 8, bestTime: 'morning', type: 'guided', tags: ['spring'], isPremium: true),
      ],
    };
    return fallback[type] ?? [];
  }
}

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final baseUrl = ref.watch(audioBaseUrlProvider);
  return AudioNotifier(baseUrl);
});
