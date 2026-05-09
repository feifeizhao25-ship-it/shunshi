import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 消息缓存存储
class MessageStorage {
  static const String _keyMessages = 'cached_messages';
  static const String _keyConversations = 'conversations';
  static const int _maxMessages = 100; // Max cached messages
  
  final SharedPreferences _prefs;
  
  MessageStorage(this._prefs);
  
  /// Save消息到缓存
  Future<bool> saveMessage(Map<String, dynamic> message) async {
    final messages = getMessages();
    messages.add(message);
    
    // 超过限制时Delete旧消息
    while (messages.length > _maxMessages) {
      messages.removeAt(0);
    }
    
    return await _prefs.setString(_keyMessages, jsonEncode(messages));
  }
  
  /// 获取缓存的消息
  List<Map<String, dynamic>> getMessages() {
    final data = _prefs.getString(_keyMessages);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
  
  /// 获取特定对话的消息
  List<Map<String, dynamic>> getMessagesByConversation(String conversationId) {
    return getMessages().where((m) => m['conversation_id'] == conversationId).toList();
  }
  
  /// Save对话列表
  Future<bool> saveConversations(List<Map<String, dynamic>> conversations) async {
    return await _prefs.setString(_keyConversations, jsonEncode(conversations));
  }
  
  /// 获取对话列表
  List<Map<String, dynamic>> getConversations() {
    final data = _prefs.getString(_keyConversations);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
  
  /// 创建新对话
  Future<Map<String, dynamic>> createConversation(String title) async {
    final now = DateTime.now();
    final conversation = {
      'id': 'conv_${now.millisecondsSinceEpoch}',
      'title': title,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'message_count': 0,
    };
    
    final conversations = getConversations();
    conversations.insert(0, conversation);
    
    await saveConversations(conversations);
    return conversation;
  }
  
  /// 更新对话 (Latest消息时间)
  Future<bool> updateConversation(String conversationId) async {
    final conversations = getConversations();
    final index = conversations.indexWhere((c) => c['id'] == conversationId);
    
    if (index >= 0) {
      conversations[index]['updated_at'] = DateTime.now().toIso8601String();
      conversations[index]['message_count'] = getMessagesByConversation(conversationId).length;
      
      // 按更新时间排序
      conversations.sort((a, b) => 
        DateTime.parse(b['updated_at']).compareTo(DateTime.parse(a['updated_at']))
      );
      
      return await saveConversations(conversations);
    }
    return false;
  }
  
  /// Delete对话
  Future<bool> deleteConversation(String conversationId) async {
    final conversations = getConversations();
    conversations.removeWhere((c) => c['id'] == conversationId);
    await saveConversations(conversations);
    
    // 同时Delete对话中的消息
    final messages = getMessages();
    messages.removeWhere((m) => m['conversation_id'] == conversationId);
    await _prefs.setString(_keyMessages, jsonEncode(messages));
    
    return true;
  }
  
  /// 清除所有消息缓存
  Future<bool> clear() async {
    await _prefs.remove(_keyMessages);
    await _prefs.remove(_keyConversations);
    return true;
  }
  
  /// 获取缓存大小 (字节)
  int getCacheSize() {
    final messagesSize = _prefs.getString(_keyMessages)?.length ?? 0;
    final conversationsSize = _prefs.getString(_keyConversations)?.length ?? 0;
    return messagesSize + conversationsSize;
  }
}
