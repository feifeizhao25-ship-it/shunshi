// lib/core/utils/metrics_service.dart
// SEASONS Metrics & Analytics Service
// Tracks user behavior events for product improvement

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Event types
enum MetricEvent {
  // App lifecycle
  appOpen,
  appBackground,
  appCrash,

  // Onboarding
  onboardingStarted,
  onboardingStepCompleted,
  onboardingCompleted,
  onboardingSkipped,

  // Auth
  signUpStarted,
  signUpCompleted,
  loginCompleted,
  logoutCompleted,

  // Chat
  chatMessageSent,
  chatResponseReceived,
  chatSafetyBlocked,

  // Audio
  audioPlayStarted,
  audioPlayCompleted,
  audioPlayAbandoned,

  // Content
  contentViewed,
  contentShared,

  // Subscription
  paywallShown,
  subscriptionStarted,
  subscriptionCompleted,
  subscriptionCancelled,
  trialStarted,

  // Settings
  hemisphereChanged,
  notificationToggled,
  themeChanged,

  // Reflection
  reflectionCreated,
  reflectionViewed,
}

/// Metric event payload
class MetricPayload {
  final MetricEvent event;
  final String? userId;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  MetricPayload({
    required this.event,
    this.userId,
    this.properties = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'event': event.name,
    'user_id': userId,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
    'platform': defaultTargetPlatform.name,
  };
}

/// Metrics service (singleton)
class MetricsService {
  static final MetricsService _instance = MetricsService._internal();
  factory MetricsService() => _instance;
  MetricsService._internal();

  String? _userId;
  String? _hemisphere;
  bool _enabled = true;

  // Event queue for batching
  final List<MetricPayload> _queue = [];
  static const int _batchSize = 10;

  late Dio _dio;

  void init({required String apiBaseUrl, String? userId, String? hemisphere}) {
    _userId = userId;
    _hemisphere = hemisphere;
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setUser(String userId) => _userId = userId;
  void setHemisphere(String hemisphere) => _hemisphere = hemisphere;
  void setEnabled(bool enabled) => _enabled = enabled;

  /// Track a single event
  void track(
    MetricEvent event, {
    Map<String, dynamic>? properties,
  }) {
    if (!_enabled) return;

    final payload = MetricPayload(
      event: event,
      userId: _userId,
      properties: {
        if (_hemisphere != null) 'hemisphere': _hemisphere,
        ...?properties,
      },
    );

    _queue.add(payload);

    if (kDebugMode) {
      debugPrint('[Metrics] ${event.name}: ${payload.properties}');
    }

    // Auto-flush when batch is full
    if (_queue.length >= _batchSize) {
      _flush();
    }
  }

  /// Track onboarding step
  void trackOnboardingStep(int step, String stepName) {
    track(MetricEvent.onboardingStepCompleted, properties: {
      'step': step,
      'step_name': stepName,
    });
  }

  /// Track audio play
  void trackAudioPlay({
    required String audioId,
    required String audioTitle,
    required int durationMinutes,
    required bool completed,
    int? secondsPlayed,
  }) {
    track(
      completed ? MetricEvent.audioPlayCompleted : MetricEvent.audioPlayAbandoned,
      properties: {
        'audio_id': audioId,
        'audio_title': audioTitle,
        'duration_minutes': durationMinutes,
        'seconds_played': secondsPlayed,
      },
    );
  }

  /// Track subscription event
  void trackSubscription({
    required MetricEvent event,
    required String tier,
    String? plan,
    double? price,
  }) {
    track(event, properties: {
      'tier': tier,
      if (plan != null) 'plan': plan,
      if (price != null) 'price': price,
    });
  }

  /// Flush pending events to backend
  Future<void> _flush() async {
    if (_queue.isEmpty) return;

    final batch = List<MetricPayload>.from(_queue);
    _queue.clear();

    try {
      await _dio.post('/api/v1/metrics/batch', data: {
        'events': batch.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      // Re-queue on failure (up to max queue size)
      if (_queue.length < 100) {
        _queue.insertAll(0, batch);
      }
      if (kDebugMode) {
        debugPrint('[Metrics] Flush failed: $e');
      }
    }
  }

  /// Force flush (call on app background/exit)
  Future<void> flush() => _flush();
}

// Global singleton accessor
final metrics = MetricsService();
