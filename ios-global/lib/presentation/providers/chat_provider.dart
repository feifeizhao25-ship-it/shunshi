import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_service.dart';
import '../../../domain/entities/message.dart';

class ChatState {
  final List<Message> messages;
  final String? conversationId;
  final bool isLoading;
  final String? error;
  
  const ChatState({
    this.messages = const [],
    this.conversationId,
    this.isLoading = false,
    this.error,
  });
  
  ChatState copyWith({
    List<Message>? messages,
    String? conversationId,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());
  
  final _uuid = const Uuid();
  
  Future<void> sendMessage(String text) async {
    // Add user message
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: state.conversationId ?? _uuid.v4(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      conversationId: userMessage.conversationId,
      isLoading: true,
      error: null,
    );
    
    try {
      // Call real SEASONS AI backend
      final response = await ApiService.instance.dio.post(
        '/ai/chat',
        data: {
          'message': text,
          'conversation_id': state.conversationId ?? userMessage.conversationId,
          'user_id': 'seasons_user',
          'hemisphere': 'north',
        },
      );
      
      final data = response.data;
      final aiText = data['text'] as String? ?? 'I\'m here with you.';
      
      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: state.conversationId!,
        content: aiText,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      // Fallback on network error
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to reach AI. Please check your connection.',
      );
    }
  }
  
  void clearConversation() {
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
