import 'package:flutter/foundation.dart';

/// Analytics Service for SEASONS
/// Tracks user events for product improvement

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  
  bool _enabled = !kDebugMode;
  final List<Map<String, dynamic>> _events = [];
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  // ===================
  // User Events
  // ===================
  
  void userSignUp(String userId, String method) {
    _track('user_sign_up', {
      'user_id': userId,
      'method': method,
    });
  }
  
  void userSignIn(String userId, String method) {
    _track('user_sign_in', {
      'user_id': userId,
      'method': method,
    });
  }
  
  void userSignOut(String userId) {
    _track('user_sign_out', {
      'user_id': userId,
    });
  }
  
  void userSubscriptionChange(String userId, String fromTier, String toTier) {
    _track('subscription_change', {
      'user_id': userId,
      'from_tier': fromTier,
      'to_tier': toTier,
    });
  }
  
  // ===================
  // Page Events
  // ===================
  
  void pageView(String pageName, {String? userId}) {
    _track('page_view', {
      'page_name': pageName,
      if (userId != null) 'user_id': userId,
    });
  }
  
  // ===================
  // Home Events
  // ===================
  
  void homeViewed(String userId) {
    _track('home_viewed', {'user_id': userId});
  }
  
  void dailyInsightViewed(String userId, String insightId) {
    _track('daily_insight_viewed', {
      'user_id': userId,
      'insight_id': insightId,
    });
  }
  
  void suggestionClicked(String userId, String suggestionId) {
    _track('suggestion_clicked', {
      'user_id': userId,
      'suggestion_id': suggestionId,
    });
  }
  
  void suggestionCompleted(String userId, String suggestionId) {
    _track('suggestion_completed', {
      'user_id': userId,
      'suggestion_id': suggestionId,
    });
  }
  
  // ===================
  // Chat Events
  // ===================
  
  void chatStarted(String userId, String conversationId) {
    _track('chat_started', {
      'user_id': userId,
      'conversation_id': conversationId,
    });
  }
  
  void chatMessageSent(String userId, String conversationId, int messageIndex) {
    _track('chat_message_sent', {
      'user_id': userId,
      'conversation_id': conversationId,
      'message_index': messageIndex,
    });
  }
  
  void chatMessageReceived(String userId, String conversationId, String model) {
    _track('chat_message_received', {
      'user_id': userId,
      'conversation_id': conversationId,
      'model': model,
    });
  }
  
  void quickQuestionClicked(String userId, String question) {
    _track('quick_question_clicked', {
      'user_id': userId,
      'question': question,
    });
  }
  
  void chatEnded(String userId, String conversationId, int messageCount, int durationSeconds) {
    _track('chat_ended', {
      'user_id': userId,
      'conversation_id': conversationId,
      'message_count': messageCount,
      'duration_seconds': durationSeconds,
    });
  }
  
  // ===================
  // Seasons Events
  // ===================
  
  void seasonsViewed(String userId) {
    _track('seasons_viewed', {'user_id': userId});
  }
  
  void seasonViewed(String userId, String season) {
    _track('season_viewed', {
      'user_id': userId,
      'season': season,
    });
  }
  
  void seasonalRitualClicked(String userId, String season, String ritual) {
    _track('seasonal_ritual_clicked', {
      'user_id': userId,
      'season': season,
      'ritual': ritual,
    });
  }
  
  // ===================
  // Library Events
  // ===================
  
  void libraryViewed(String userId, {String? category}) {
    _track('library_viewed', {
      'user_id': userId,
      if (category != null) 'category': category,
    });
  }
  
  void contentViewed(String userId, String contentId, String contentType) {
    _track('content_viewed', {
      'user_id': userId,
      'content_id': contentId,
      'content_type': contentType,
    });
  }
  
  void contentStarted(String userId, String contentId) {
    _track('content_started', {
      'user_id': userId,
      'content_id': contentId,
    });
  }
  
  void contentCompleted(String userId, String contentId, int durationSeconds) {
    _track('content_completed', {
      'user_id': userId,
      'content_id': contentId,
      'duration_seconds': durationSeconds,
    });
  }
  
  void contentSearched(String userId, String query) {
    _track('content_searched', {
      'user_id': userId,
      'query': query,
    });
  }
  
  void contentFavorited(String userId, String contentId) {
    _track('content_favorited', {
      'user_id': userId,
      'content_id': contentId,
    });
  }
  
  // ===================
  // Reflection Events
  // ===================
  
  void reflectionViewed(String userId) {
    _track('reflection_viewed', {'user_id': userId});
  }
  
  void reflectionStarted(String userId) {
    _track('reflection_started', {'user_id': userId});
  }
  
  void reflectionCompleted(String userId, String mood, String energy, String sleep) {
    _track('reflection_completed', {
      'user_id': userId,
      'mood': mood,
      'energy': energy,
      'sleep': sleep,
    });
  }
  
  void weeklyReflectionViewed(String userId) {
    _track('weekly_reflection_viewed', {'user_id': userId});
  }
  
  // ===================
  // Subscription Events
  // ===================
  
  void subscriptionPageViewed(String userId) {
    _track('subscription_page_viewed', {'user_id': userId});
  }
  
  void subscriptionClicked(String userId, String tier) {
    _track('subscription_clicked', {
      'user_id': userId,
      'tier': tier,
    });
  }
  
  void subscriptionPurchased(String userId, String tier, String store) {
    _track('subscription_purchased', {
      'user_id': userId,
      'tier': tier,
      'store': store,
    });
  }
  
  void subscriptionRestored(String userId, String tier) {
    _track('subscription_restored', {
      'user_id': userId,
      'tier': tier,
    });
  }
  
  // ===================
  // Error Events
  // ===================
  
  void error(String errorType, String message, {String? userId, Map<String, dynamic>? context}) {
    _track('error', {
      'error_type': errorType,
      'message': message,
      if (userId != null) 'user_id': userId,
      if (context != null) ...context,
    });
  }
  
  void apiError(String endpoint, int statusCode, {String? userId}) {
    _track('api_error', {
      'endpoint': endpoint,
      'status_code': statusCode,
      if (userId != null) 'user_id': userId,
    });
  }
  
  void aiError(String model, String error, {String? userId}) {
    _track('ai_error', {
      'model': model,
      'error': error,
      if (userId != null) 'user_id': userId,
    });
  }
  
  // ===================
  // Core
  // ===================
  
  void _track(String eventName, Map<String, dynamic> properties) {
    if (!_enabled) return;
    
    final event = {
      'event': eventName,
      'timestamp': DateTime.now().toIso8601String(),
      'properties': properties,
    };
    
    _events.add(event);
    
    if (kDebugMode) {
      print('[Analytics] $eventName: $properties');
    }
    
    // In production, send to analytics service
    // _sendToAnalytics(event);
  }
  
  List<Map<String, dynamic>> getEvents() => List.unmodifiable(_events);
  
  void clearEvents() => _events.clear();
  
  // For testing
  @visibleForTesting
  int get eventCount => _events.length;
}

/// Analytics provider helper
class AnalyticsProvider {
  final AnalyticsService analytics;
  
  AnalyticsProvider({AnalyticsService? analytics})
      : analytics = analytics ?? AnalyticsService();
  
  // Convenience methods
  void trackPageView(String pageName, {String? userId}) {
    analytics.pageView(pageName, userId: userId);
  }
  
  void trackError(String errorType, String message, {String? userId}) {
    analytics.error(errorType, message, userId: userId);
  }
}
