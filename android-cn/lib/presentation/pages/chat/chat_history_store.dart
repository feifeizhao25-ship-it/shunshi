import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_history_codec.dart';
import 'chat_models.dart';

/// JWT subject is used only to partition local cache, never to authorize an API.
/// Do not infer an owner from stale user_info or unowned legacy history.
String? chatCacheOwner(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final subject = payload['sub'];
    return subject is String && subject.trim().isNotEmpty ? subject : null;
  } catch (_) {
    return null;
  }
}

class StoredChat {
  final String? conversationId;
  final List<ChatMessage> messages;
  StoredChat(this.conversationId, this.messages);
}

class ChatHistoryStore {
  final SharedPreferences prefs;
  final String token;
  ChatHistoryStore(this.prefs, this.token);

  String _key(String owner, String kind, [String? conversation]) =>
      'chat_v2_${base64Url.encode(utf8.encode(jsonEncode([owner, kind, conversation])))}'; // zh-gate:allow 存储键，不显示

  bool get _current =>
      token.isNotEmpty && prefs.getString('auth_token') == token;

  StoredChat load({String? conversationId}) {
    final owner = chatCacheOwner(token);
    if (!_current || owner == null) return StoredChat(conversationId, []);
    final selected = conversationId ?? prefs.getString(_key(owner, 'latest'));
    final id = selected == '' ? null : selected;
    return StoredChat(
      id,
      decodeChatHistory(prefs.getString(_key(owner, 'messages', id))),
    );
  }

  Future<void> save(List<ChatMessage> messages, String? conversationId) async {
    final owner = chatCacheOwner(token);
    if (!_current || owner == null) return;
    final saved = await prefs.setString(
      _key(owner, 'messages', conversationId),
      encodeChatHistory(messages),
    );
    if (!saved) throw StateError('聊天记录保存失败');
    if (!_current) return;
    if (!await prefs.setString(_key(owner, 'latest'), conversationId ?? '')) {
      throw StateError('聊天记录索引保存失败');
    }
  }
}
