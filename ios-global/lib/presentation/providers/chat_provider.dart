import '../../core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/message.dart';
import '../../../core/network/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: AppConstants.baseUrl);
});

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
  final ApiService _api;
  ChatNotifier(this._api) : super(const ChatState());
  
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
      final response = await _api.sendChat(
        prompt: text,
        conversationId: state.conversationId,
        userId: 'seasons-user',
      );
      
      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: state.conversationId!,
        content: response.text,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get response. Please try again.',
      );
    }
  }
  
  void clearConversation() {
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ChatNotifier(api);
});
