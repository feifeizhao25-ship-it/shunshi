import '../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';

/// SEASONS Analytics — Event Taxonomy & Tracking
/// Based on PRD metrics requirements

enum AnalyticsEvent {
  // ── Onboarding ──
  onboarding_started,
  onboarding_step_completed,
  onboarding_completed,
  onboarding_skipped,

  // ── Home ──
  home_viewed,
  daily_insight_viewed,
  suggestion_viewed,
  suggestion_completed,
  season_card_viewed,

  // ── AI Chat ──
  chat_opened,
  chat_message_sent,
  chat_message_received,
  chat_completed,
  chat_safety_flag_triggered,

  // ── Content ──
  content_list_viewed,
  content_detail_viewed,
  content_started,
  content_completed,
  audio_started,
  audio_completed,

  // ── Reflection ──
  reflection_started,
  reflection_submitted,
  weekly_reflection_viewed,
  reflection_shared,

  // ── Seasons ──
  season_page_viewed,
  season_ritual_viewed,

  // ── Subscription ──
  subscription_page_viewed,
  trial_started,
  subscription_purchased,
  subscription_expired,
  subscription_restored,
  paywall_shown,
  paywall_dismissed,

  // ── Retention ──
  app_opened,
  app_backgrounded,
  day1_retention,
  day7_retention,
  streak_incremented,
  streak_broken,

  // ── Safety ──
  crisis_mode_triggered,
  crisis_resource_viewed,
  safety_notice_shown,

  // ── Settings ──
  memory_toggled,
  memory_cleared,
  data_export_requested,
  account_deleted,
  notification_toggled,
}

/// Analytics Service — SEASONS Global
/// Tracks all events defined in PRD metrics section
///
/// Metrics tracked:
/// - onboarding completion rate
/// - day 1/7 activation
/// - reflection completion
/// - trial conversion
/// - yearly subscription conversion
/// - AI cost per retained user
/// - crisis trigger rate
/// - safe-mode resolution rate

class AnalyticsService {
  final Dio _dio;
  final String _baseUrl;

  AnalyticsService({String baseUrl = AppConstants.baseUrl})
      : _baseUrl = baseUrl,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

  // In-memory event queue (simplified — no persistent queue)
  final List<Map<String, dynamic>> _eventQueue = [];

  // ── Core Track Method ──────────────────────────────────

  Future<void> track(
    AnalyticsEvent event, {
    Map<String, dynamic>? properties,
    String? userId,
  }) async {
    final payload = {
      'event': event.name,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': userId ?? 'anonymous',
      'properties': properties ?? {},
      'session_id': _sessionId,
    };

    // Add to queue
    _eventQueue.add(payload);

    // Log locally for debugging
    _logEvent(event, properties);

    // Send to backend (fire-and-forget)
    _sendAsync(payload);
  }

  // ── Convenience Methods ──────────────────────────────────

  Future<void> trackOnboardingStep({
    required int step,
    required String stepName,
  }) async {
    await track(
      AnalyticsEvent.onboarding_step_completed,
      properties: {
        'step': step,
        'step_name': stepName,
      },
    );
  }

  Future<void> trackHomeViewed({required String season}) async {
    await track(
      AnalyticsEvent.home_viewed,
      properties: {'season': season},
    );
  }

  Future<void> trackSuggestionCompleted({
    required String suggestionId,
    required String category,
  }) async {
    await track(
      AnalyticsEvent.suggestion_completed,
      properties: {
        'suggestion_id': suggestionId,
        'category': category,
      },
    );
  }

  Future<void> trackChatMessage({
    required bool isUser,
    required int messageLength,
  }) async {
    await track(
      isUser ? AnalyticsEvent.chat_message_sent : AnalyticsEvent.chat_message_received,
      properties: {
        'message_length': messageLength,
      },
    );
  }

  Future<void> trackReflectionSubmitted({
    required String mood,
    required String energy,
    required String sleep,
    required bool hasNote,
  }) async {
    await track(
      AnalyticsEvent.reflection_submitted,
      properties: {
        'mood': mood,
        'energy': energy,
        'sleep': sleep,
        'has_note': hasNote,
      },
    );
  }

  Future<void> trackContentStarted({
    required String contentId,
    required String contentType,
    required int durationMinutes,
  }) async {
    await track(
      AnalyticsEvent.content_started,
      properties: {
        'content_id': contentId,
        'content_type': contentType,
        'duration_minutes': durationMinutes,
      },
    );
  }

  Future<void> trackAudioStarted({
    required String audioId,
    required String audioType,
    required int durationMinutes,
  }) async {
    await track(
      AnalyticsEvent.audio_started,
      properties: {
        'audio_id': audioId,
        'audio_type': audioType,
        'duration_minutes': durationMinutes,
      },
    );
  }

  Future<void> trackSubscriptionEvent({
    required String event,
    required String tier,
    String? trialId,
  }) async {
    await track(
      AnalyticsEvent.subscription_purchased,
      properties: {
        'tier': tier,
        'trial_id': trialId,
        'subscription_event': event,
      },
    );
  }

  Future<void> trackCrisisTriggered({
    required String triggerType,
    required String responseType,
  }) async {
    await track(
      AnalyticsEvent.crisis_mode_triggered,
      properties: {
        'trigger_type': triggerType,
        'response_type': responseType,
      },
    );
  }

  Future<void> trackStreak({required int currentStreak}) async {
    await track(
      AnalyticsEvent.streak_incremented,
      properties: {
        'current_streak': currentStreak,
      },
    );
  }

  Future<void> trackRetention({required int day}) async {
    await track(
      day == 1
          ? AnalyticsEvent.day1_retention
          : AnalyticsEvent.day7_retention,
      properties: {'day': day},
    );
  }

  // ── Private Helpers ──────────────────────────────────────

  String get _sessionId {
    // Generate a simple session ID based on timestamp
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _logEvent(AnalyticsEvent event, Map<String, dynamic>? properties) {
    // Debug logging — can be disabled in release builds
    assert(() {
      print('[Analytics] ${event.name} ${properties ?? ""}');
      return true;
    }());
  }

  Future<void> _sendAsync(Map<String, dynamic> payload) async {
    try {
      await _dio.post(
        '/api/v1/analytics/event',
        data: payload,
      );
    } catch (e) {
      // Silently fail — analytics should never crash the app
    }
  }

  // ── Analytics Summary ────────────────────────────────────

  /// Get a summary of tracked events (for debugging/settings)
  Map<String, int> getEventSummary() {
    final summary = <String, int>{};
    for (final event in _eventQueue) {
      final name = event['event'] as String;
      summary[name] = (summary[name] ?? 0) + 1;
    }
    return summary;
  }

  /// Clear all tracked events (e.g., after logout)
  void clearEvents() {
    _eventQueue.clear();
  }
}

// Global instance
final analytics = AnalyticsService();
