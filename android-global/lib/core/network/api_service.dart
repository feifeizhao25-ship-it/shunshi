import '../constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API Service for SEASONS
/// Handles all backend communication with retry logic, caching, and error handling

class ApiService {
  late final Dio _dio;
  final String baseUrl;
  final String? authToken;
  
  ApiService({
    this.baseUrl = AppConstants.baseUrl,
    this.authToken,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );
    
    // Add interceptors
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _RetryInterceptor(this),
    ]);
  }
  
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  // ===================
  // Health
  // ===================
  
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data;
  }
  
  // ===================
  // Chat
  // ===================
  
  Future<ChatResponse> sendChat({
    required String prompt,
    String? conversationId,
    String? userId,
    String? model,
  }) async {
    final response = await _dio.post(
      '/ai/chat',
      data: {
        'prompt': prompt,
        if (conversationId != null) 'conversation_id': conversationId,
        if (userId != null) 'user_id': userId,
        if (model != null) 'model': model,
      },
    );
    return ChatResponse.fromJson(response.data);
  }
  
  Stream<String> streamChat(String prompt, {String? conversationId}) async* {
    final response = await _dio.post<ResponseBody>(
      '/ai/chat/stream',
      data: {
        'prompt': prompt,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      options: Options(responseType: ResponseType.stream),
    );
    
    final stream = response.data?.stream;
    if (stream != null) {
      await for (final chunk in stream) {
        yield String.fromCharCodes(chunk);
      }
    }
  }
  
  // ===================
  // Daily Insight
  // ===================
  
  Future<DailyInsightResponse> getDailyInsight({
    required String userId,
    required String season,
  }) async {
    final response = await _dio.post(
      '/ai/daily-insight',
      queryParameters: {
        'user_id': userId,
        'season': season,
      },
    );
    return DailyInsightResponse.fromJson(response.data);
  }
  
  // ===================
  // Reflection
  // ===================
  
  Future<void> submitReflection({
    required String userId,
    required String mood,
    required String energy,
    required String sleep,
    String? notes,
  }) async {
    await _dio.post(
      '/api/v1/seasons/reflection/submit',
      data: {
        'user_id': userId,
        'mood': mood,
        'energy': energy,
        'sleep': sleep,
        if (notes != null) 'notes': notes,
      },
    );
  }
  
  Future<List<ReflectionResponse>> getReflections(String userId) async {
    final response = await _dio.get(
      '/api/v1/seasons/reflection/list',
      queryParameters: {'user_id': userId},
    );
    return (response.data as List)
        .map((e) => ReflectionResponse.fromJson(e))
        .toList();
  }
  
  Future<WeeklyReflectionResponse> getWeeklyReflection({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final response = await _dio.post(
      '/api/v1/seasons/reflection/weekly',
      data: {
        'user_id': userId,
        'week_start': weekStart.toIso8601String(),
        'week_end': weekEnd.toIso8601String(),
      },
    );
    return WeeklyReflectionResponse.fromJson(response.data);
  }
  
  // ===================
  // Content
  // ===================
  
  Future<List<ContentResponse>> getContentList({
    String? type,
    String? season,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/seasons/content/list',
      queryParameters: {
        if (type != null) 'type': type,
        if (season != null) 'season': season,
        'page': page,
        'limit': limit,
      },
    );
    return (response.data as List)
        .map((e) => ContentResponse.fromJson(e))
        .toList();
  }
  
  Future<ContentResponse> getContentDetail(String contentId) async {
    final response = await _dio.get('/api/v1/seasons/content/$contentId');
    return ContentResponse.fromJson(response.data);
  }
  
  // ===================
  // Seasons
  // ===================
  
  Future<SeasonResponse> getCurrentSeason(String userId) async {
    final response = await _dio.get(
      '/api/v1/seasons/season/current',
      queryParameters: {'user_id': userId},
    );
    return SeasonResponse.fromJson(response.data);
  }
  
  Future<List<SeasonResponse>> getSeasons() async {
    final response = await _dio.get('/api/v1/seasons/season/list');
    return (response.data as List)
        .map((e) => SeasonResponse.fromJson(e))
        .toList();
  }
  
  // ===================
  // User
  // ===================
  
  Future<UserResponse> getUserProfile(String userId) async {
    final response = await _dio.get('/api/v1/seasons/user/$userId');
    return UserResponse.fromJson(response.data);
  }
  
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    await _dio.put(
      '/api/v1/seasons/user/$userId',
      data: {
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (preferences != null) 'preferences': preferences,
      },
    );
  }
  
  // ===================
  // Models
  // ===================
  
  Future<List<ModelInfo>> listModels() async {
    final response = await _dio.get('/models');
    return (response.data as List)
        .map((e) => ModelInfo.fromJson(e))
        .toList();
  }
}

/// Response Models

class ChatResponse {
  final String text;
  final String tone;
  final List<String> suggestions;
  final FollowUp? followUp;
  final String safetyFlag;
  final String model;
  final int tokensUsed;
  final int latencyMs;
  
  ChatResponse.fromJson(Map<String, dynamic> json)
      : text = json['text'] ?? '',
        tone = json['tone'] ?? 'calm',
        suggestions = (json['suggestions'] as List?)?.cast<String>() ?? [],
        followUp = json['follow_up'] != null 
            ? FollowUp.fromJson(json['follow_up']) 
            : null,
        safetyFlag = json['safety_flag'] ?? 'none',
        model = json['model'] ?? '',
        tokensUsed = json['tokens_used'] ?? 0,
        latencyMs = json['latency_ms'] ?? 0;
}

class FollowUp {
  final int inDays;
  final String intent;
  
  FollowUp.fromJson(Map<String, dynamic> json)
      : inDays = json['in_days'] ?? 2,
        intent = json['intent'] ?? '';
}

class DailyInsightResponse {
  final String text;
  final String season;
  final DateTime generatedAt;
  
  DailyInsightResponse.fromJson(Map<String, dynamic> json)
      : text = json['text'] ?? '',
        season = json['season'] ?? '',
        generatedAt = DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now();
}

class ReflectionResponse {
  final String id;
  final DateTime date;
  final String mood;
  final String energy;
  final String sleep;
  final String? notes;
  
  ReflectionResponse.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        date = DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        mood = json['mood'] ?? '',
        energy = json['energy'] ?? '',
        sleep = json['sleep'] ?? '',
        notes = json['notes'];
}

class WeeklyReflectionResponse {
  final String aiSummary;
  final String aiInsight;
  final List<String> moodTrend;
  final String averageEnergy;
  final String averageSleep;
  final int streakDays;
  
  WeeklyReflectionResponse.fromJson(Map<String, dynamic> json)
      : aiSummary = json['ai_summary'] ?? '',
        aiInsight = json['ai_insight'] ?? '',
        moodTrend = (json['mood_trend'] as List?)?.cast<String>() ?? [],
        averageEnergy = json['average_energy'] ?? 'medium',
        averageSleep = json['average_sleep'] ?? 'good',
        streakDays = json['streak_days'] ?? 0;
}

class ContentResponse {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? videoUrl;
  final String? imageUrl;
  final String? audioUrl;
  final int? durationSeconds;
  final List<String> tags;
  final bool isPremium;
  
  ContentResponse.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        title = json['title'] ?? '',
        description = json['description'] ?? '',
        type = json['type'] ?? '',
        videoUrl = json['video_url'],
        imageUrl = json['image_url'],
        audioUrl = json['audio_url'],
        durationSeconds = json['duration_seconds'],
        tags = (json['tags'] as List?)?.cast<String>() ?? [],
        isPremium = json['is_premium'] ?? false;
}

class SeasonResponse {
  final String name;
  final String insight;
  final List<String> foodSuggestions;
  final List<String> stretchRoutines;
  final List<String> sleepRituals;
  
  SeasonResponse.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        insight = json['insight'] ?? '',
        foodSuggestions = (json['food_suggestions'] as List?)?.cast<String>() ?? [],
        stretchRoutines = (json['stretch_routines'] as List?)?.cast<String>() ?? [],
        sleepRituals = (json['sleep_rituals'] as List?)?.cast<String>() ?? [];
}

class UserResponse {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? country;
  final String subscription;
  final DateTime createdAt;
  
  UserResponse.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        email = json['email'] ?? '',
        name = json['name'],
        avatarUrl = json['avatar_url'],
        country = json['country'],
        subscription = json['subscription'] ?? 'free',
        createdAt = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
}

class ModelInfo {
  final String id;
  final String provider;
  final String cost;
  final String speed;
  
  ModelInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        provider = json['provider'] ?? '',
        cost = json['cost'] ?? 'medium',
        speed = json['speed'] ?? 'medium';
}

/// Interceptors

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('API Request: ${options.method} ${options.path}');
    }
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('API Response: ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('API Error: ${err.message} ${err.requestOptions.path}');
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final ApiService _apiService;
  final int _maxRetries;
  
  _RetryInterceptor(this._apiService, {int maxRetries = 3}) : _maxRetries = maxRetries;
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      for (int i = 0; i < _maxRetries; i++) {
        try {
          await Future.delayed(Duration(seconds: i + 1));
          final response = await _apiService._dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          continue;
        }
      }
    }
    handler.next(err);
  }
  
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
