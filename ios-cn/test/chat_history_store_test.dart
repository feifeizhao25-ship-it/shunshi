import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/chat/chat_history_store.dart';
import 'package:shunshi/presentation/pages/chat/chat_models.dart';
import 'package:shunshi/data/storage/user_storage.dart';

String token(String owner, [String nonce = 'one']) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': owner, 'jti': nonce})))}.signature';
List<ChatMessage> message(String text) => [
  ChatMessage(role: 'ai', text: text, time: '12:00'),
];
void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  test(
    'account switch and same conversation id cannot expose another account',
    () async {
      await prefs.setString('auth_token', token('A'));
      await ChatHistoryStore(prefs, token('A')).save(message('甲的私密内容'), 'same');
      await prefs.setString('auth_token', token('B'));
      expect(
        ChatHistoryStore(
          prefs,
          token('B'),
        ).load(conversationId: 'same').messages,
        isEmpty,
      );
      await ChatHistoryStore(prefs, token('B')).save(message('乙的内容'), 'same');
      await prefs.setString('auth_token', token('A', 'refreshed'));
      expect(
        ChatHistoryStore(
          prefs,
          token('A', 'refreshed'),
        ).load().messages.single.text,
        '甲的私密内容',
      );
    },
  );
  test(
    'explicit conversation wins over latest and missing conversation stays empty',
    () async {
      final auth = token('A');
      await prefs.setString('auth_token', auth);
      final store = ChatHistoryStore(prefs, auth);
      await store.save(message('第一段\n完整正文'), 'first');
      await store.save(message('第二个会话'), 'second');
      expect(store.load().conversationId, 'second');
      expect(
        store.load(conversationId: 'first').messages.single.text,
        '第一段\n完整正文',
      );
      expect(store.load(conversationId: 'missing').messages, isEmpty);
      expect(store.load(conversationId: 'missing').conversationId, 'missing');
    },
  );
  test(
    'late response from old account cannot save or load after account switch',
    () async {
      await prefs.setString('auth_token', token('A'));
      final old = ChatHistoryStore(prefs, token('A'));
      await prefs.setString('auth_token', token('B'));
      await old.save(message('迟到回复'), 'late');
      expect(old.load().messages, isEmpty);
      await prefs.setString('auth_token', token('A'));
      expect(old.load().messages, isEmpty);
    },
  );
  test(
    'unowned legacy history is preserved but never assigned to current user',
    () async {
      await prefs.setString('auth_token', token('B'));
      await prefs.setString('chat_history', 'ai|未知归属的私密内容');
      await prefs.setString('conversation_id', 'someone-else');
      expect(ChatHistoryStore(prefs, token('B')).load().messages, isEmpty);
      expect(ChatHistoryStore(prefs, token('B')).load().conversationId, isNull);
      expect(prefs.getString('chat_history'), isNotNull);
    },
  );
  test('invalid or absent identity does not load or persist history', () async {
    for (final auth in ['', 'invalid', 'a.e30=.b']) {
      await prefs.setString('auth_token', auth);
      final store = ChatHistoryStore(prefs, auth);
      await store.save(message('无归属'), 'one');
      expect(store.load().messages, isEmpty);
      expect(
        prefs.getKeys().where((key) => key.startsWith('chat_v2_')),
        isEmpty,
      );
    }
  });
  test(
    'logout clears scoped and legacy caches while preserving settings',
    () async {
      await prefs.setString('auth_token', token('A'));
      await ChatHistoryStore(prefs, token('A')).save(message('私密内容'), 'one');
      await prefs.setString('chat_history', 'legacy');
      await prefs.setString('conversation_id', 'legacy');
      await prefs.setString('theme_mode', 'dark');
      await UserStorage(prefs).clear();
      expect(prefs.getKeys(), {'theme_mode'});
    },
  );
}
