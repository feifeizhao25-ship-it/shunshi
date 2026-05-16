// 聊天分页服务
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// 消息模型
class ChatMessage {
  final String id;
  final String role; // user / assistant / system
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    role: json['role'],
    content: json['content'],
    timestamp: DateTime.tryParse(json['created_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
    metadata: json['metadata'],
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

/// 聊天分页状态
class ChatPaginationState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final String? cursor; // 用于游标分页
  
  const ChatPaginationState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
    this.cursor,
  });
  
  ChatPaginationState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    String? cursor,
  }) {
    return ChatPaginationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      cursor: cursor ?? this.cursor,
    );
  }
}

/// 聊天分页 Provider
class ChatPaginationNotifier extends StateNotifier<ChatPaginationState> {
  final Dio _dio;
  final String conversationId;
  
  static const int _pageSize = 20;
  
  ChatPaginationNotifier({
    required this.conversationId,
    Dio? dio,
  }) : _dio = dio ?? Dio(), 
       super(const ChatPaginationState());
  
  /// 加载历史消息
  Future<void> loadHistory({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!state.hasMore && !refresh) return;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
    );
    
    try {
      final response = await _dio.get(
        '/api/v1/chat/history/$conversationId',
        queryParameters: {
          'limit': _pageSize,
          if (!refresh) 'offset': (state.currentPage - 1) * _pageSize,
          if (state.cursor != null && !refresh) 'before': state.cursor,
        },
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final items = (data['items'] as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        
        // 后端返回 has_more 字段
        final hasMore = data['has_more'] ?? (items.length >= _pageSize);
        final newCursor = items.isNotEmpty ? items.last.id : null;
        
        // 如果是刷新，先清空
        final newMessages = refresh 
            ? items 
            : [...state.messages, ...items];
        
        // 去重
        final uniqueMessages = <String, ChatMessage>{};
        for (var msg in newMessages) {
          uniqueMessages[msg.id] = msg;
        }
        
        state = state.copyWith(
          messages: uniqueMessages.values.toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
          isLoading: false,
          hasMore: hasMore,
          currentPage: refresh ? 1 : state.currentPage + 1,
          cursor: newCursor,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 加载更多 (用于无限滚动)
  Future<void> loadMore() async {
    await loadHistory();
  }
  
  /// 刷新
  Future<void> refresh() async {
    await loadHistory(refresh: true);
  }
  
  /// 添加新消息
  void addMessage(ChatMessage message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }
  
  /// 发送消息
  Future<ChatMessage?> sendMessage(String content) async {
    try {
      final response = await _dio.post(
        '/api/v1/chat',
        data: {
          'message': content,
          'conversation_id': conversationId,
        },
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        final message = ChatMessage(
          id: data['message_id'],
          role: 'assistant',
          content: data['text'],
          timestamp: DateTime.now(),
          metadata: {
            'tone': data['tone'],
            'care_status': data['care_status'],
            'follow_up': data['follow_up'],
          },
        );
        
        addMessage(message);
        return message;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return null;
  }
}

/// 聊天分页 Provider 工厂
final chatPaginationProvider = StateNotifierProvider.family<
    ChatPaginationNotifier, 
    ChatPaginationState, 
    String
>((ref, conversationId) {
  return ChatPaginationNotifier(conversationId: conversationId);
});

/// 聊天滚动控制器 Mixin
mixin ChatScrollMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late ScrollController scrollController;
  
  void initScrollController() {
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }
  
  void disposeScrollController() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }
  
  void _onScroll() {
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent - 200) {
      // 接近底部，加载更多
      // TODO: 调用 loadMore()
    }
  }
  
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}

/// 消息时间分割组件
class MessageDateDivider extends StatelessWidget {
  final DateTime date;
  
  const MessageDateDivider({super.key, required this.date});
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String text;
    if (messageDate == today) {
      text = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      text = 'Yesterday';
    } else if (messageDate == today.subtract(const Duration(days: 2))) {
      text = '2 days ago';
    } else {
      text = '${date.month}/${date.day}';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
