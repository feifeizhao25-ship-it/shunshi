// SSE Chat Service — UX_API_SPEC §7
// Client for Server-Sent Events streaming chat
// Events: start, token, card, done, error

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

class SSEMessage {
  final String id;
  final String role;
  String content;
  String status; // 'streaming' | 'completed' | 'error'
  List<SSECard> cards;
  String? model;
  int? totalTokens;
  int? durationMs;

  SSEMessage({
    required this.id,
    required this.role,
    this.content = '',
    this.status = 'streaming',
    this.cards = const [],
    this.model,
    this.totalTokens,
    this.durationMs,
  });
}

class SSECard {
  final String type;
  final String? slug;
  final String title;
  final String? reason;

  SSECard({required this.type, this.slug, required this.title, this.reason});
}

class SSEChatService {
  final Dio _dio;
  final String baseUrl;

  SSEChatService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// Send a message and receive SSE stream
  Stream<SSEEvent> sendMessage({
    required String message,
    required String userId,
    String? conversationId,
    String hemisphere = 'north',
  }) async* {
    final queryParams = {
      'message': message,
      'user_id': userId,
      'hemisphere': hemisphere,
      if (conversationId != null) 'conversation_id': conversationId,
    };

    try {
      final response = await _dio.post(
        '/chat/stream',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data as ResponseBody;
      String buffer = '';

      await for (final chunk in stream.stream) {
        final decoded = utf8.decode(chunk);
        buffer += decoded;
        // Parse SSE events from buffer
        while (buffer.contains('\n\n')) {
          final idx = buffer.indexOf('\n\n');
          final raw = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);

          final event = _parseSSE(raw);
          if (event != null) yield event;
        }
      }
    } on DioException catch (e) {
      yield SSEEvent(
        type: 'error',
        data: {'code': 'NETWORK_ERROR', 'message': e.message ?? 'Connection failed'},
      );
    }
  }

  SSEEvent? _parseSSE(String raw) {
    String? eventType;
    String? dataStr;

    for (final line in raw.split('\n')) {
      if (line.startsWith('event: ')) {
        eventType = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        dataStr = line.substring(6).trim();
      }
    }

    if (eventType == null || dataStr == null) return null;

    try {
      return SSEEvent(
        type: eventType,
        data: jsonDecode(dataStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

class SSEEvent {
  final String type; // start, token, card, done, error
  final Map<String, dynamic> data;

  SSEEvent({required this.type, required this.data});
}
