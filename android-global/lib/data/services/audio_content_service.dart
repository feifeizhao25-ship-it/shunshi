// lib/data/services/audio_content_service.dart
// SEASONS Audio Content Service — fetches audio catalog from backend

import '../models/content_item.dart';
import '../../core/network/api_client.dart';

/// Audio duration categories (minutes)
enum AudioDuration {
  short3(3),
  short5(5),
  medium8(8),
  long15(15),
  any(0);

  final int minutes;
  const AudioDuration(this.minutes);
}

/// Audio category type
enum AudioCategory {
  breathing,   // Breathing exercises
  windDown,    // Wind-down / sleep prep
  soundscape,  // Ambient soundscapes
  seasonal,    // Seasonal meditations
  guided,      // Guided meditations
}

/// Audio recommendation request
class AudioRecommendationRequest {
  final String userId;
  final String hemisphere;
  final String? currentSeason;
  final String? timeOfDay; // morning / afternoon / evening / night
  final AudioDuration? preferredDuration;
  final List<AudioCategory>? preferredCategories;

  const AudioRecommendationRequest({
    required this.userId,
    required this.hemisphere,
    this.currentSeason,
    this.timeOfDay,
    this.preferredDuration,
    this.preferredCategories,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      'user_id': userId,
      'hemisphere': hemisphere,
      if (currentSeason != null) 'season': currentSeason,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (preferredDuration != null && preferredDuration!.minutes > 0)
        'duration_minutes': preferredDuration!.minutes,
      if (preferredCategories != null)
        'categories': preferredCategories!.map((c) => c.name).join(','),
      'limit': 10,
    };
  }
}

/// Audio content service
class AudioContentService {
  final ApiClient _api;

  AudioContentService({ApiClient? api}) : _api = api ?? ApiClient();

  /// Fetch audio library by category
  Future<Map<AudioCategory, List<ContentItem>>> fetchAudioLibrary({
    required String hemisphere,
    String? season,
  }) async {
    try {
      final response = await _api.get(
        '/api/v1/audio/library',
        queryParameters: {
          'hemisphere': hemisphere,
          if (season != null) 'season': season,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final result = <AudioCategory, List<ContentItem>>{};

        for (final category in AudioCategory.values) {
          final items = data[category.name] as List<dynamic>? ?? [];
          result[category] =
              items.map((e) => ContentItem.fromJson(e as Map<String, dynamic>)).toList();
        }

        return result;
      }
    } catch (e) {
      // Return empty on error — UI handles empty state
    }
    return {for (final c in AudioCategory.values) c: []};
  }

  /// Fetch recommended audio for user
  Future<List<ContentItem>> fetchRecommended(
    AudioRecommendationRequest request,
  ) async {
    try {
      final response = await _api.get(
        '/api/v1/audio/recommended',
        queryParameters: request.toQueryParams(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch audio items by duration
  Future<List<ContentItem>> fetchByDuration({
    required AudioDuration duration,
    required String hemisphere,
    String? season,
  }) async {
    try {
      final response = await _api.get(
        '/api/v1/audio/contents',
        queryParameters: {
          'duration_minutes': duration.minutes,
          'hemisphere': hemisphere,
          if (season != null) 'season': season,
          'limit': 20,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get presigned audio stream URL
  Future<String?> getAudioStreamUrl(String audioItemId) async {
    try {
      final response = await _api.get('/api/v1/audio/$audioItemId/stream');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Record audio play event (for analytics)
  Future<void> recordPlay({
    required String userId,
    required String audioItemId,
    required int durationPlayedSeconds,
    required bool completed,
  }) async {
    try {
      await _api.post('/api/v1/audio/plays', data: {
        'user_id': userId,
        'audio_item_id': audioItemId,
        'duration_played_seconds': durationPlayedSeconds,
        'completed': completed,
        'played_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
