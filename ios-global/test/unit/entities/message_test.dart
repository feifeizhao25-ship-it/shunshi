import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/message.dart';

void main() {
  group('Message', () {
    test('creates a user message with correct fields', () {
      final timestamp = DateTime.now();
      final message = Message(
        id: 'msg_001',
        conversationId: 'conv_001',
        content: 'Hello, how are you?',
        role: MessageRole.user,
        timestamp: timestamp,
      );

      expect(message.id, 'msg_001');
      expect(message.conversationId, 'conv_001');
      expect(message.content, 'Hello, how are you?');
      expect(message.role, MessageRole.user);
      expect(message.timestamp, timestamp);
      expect(message.audioUrl, isNull);
      expect(message.imageUrl, isNull);
      expect(message.metadata, isEmpty);
    });

    test('creates an assistant message with optional media', () {
      final message = Message(
        id: 'msg_002',
        conversationId: 'conv_001',
        content: 'Here is a breathing exercise for you.',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        audioUrl: 'https://cdn.example.com/breathing.mp3',
        imageUrl: 'https://cdn.example.com/breathing.png',
        metadata: {'skill': 'breathing'},
      );

      expect(message.role, MessageRole.assistant);
      expect(message.audioUrl, 'https://cdn.example.com/breathing.mp3');
      expect(message.imageUrl, 'https://cdn.example.com/breathing.png');
      expect(message.metadata['skill'], 'breathing');
    });

    test('MessageRole enum has correct values', () {
      expect(MessageRole.values, contains(MessageRole.user));
      expect(MessageRole.values, contains(MessageRole.assistant));
      expect(MessageRole.values, contains(MessageRole.system));
    });
  });

  group('Conversation', () {
    test('creates a conversation with messages', () {
      final now = DateTime.now();
      final messages = [
        Message(
          id: 'msg_001',
          conversationId: 'conv_001',
          content: 'Hi',
          role: MessageRole.user,
          timestamp: now,
        ),
        Message(
          id: 'msg_002',
          conversationId: 'conv_001',
          content: 'Hello!',
          role: MessageRole.assistant,
          timestamp: now,
        ),
      ];

      final conversation = Conversation(
        id: 'conv_001',
        userId: 'usr_001',
        title: 'Wellness Check',
        createdAt: now,
        lastMessageAt: now,
        messages: messages,
      );

      expect(conversation.id, 'conv_001');
      expect(conversation.title, 'Wellness Check');
      expect(conversation.messages.length, 2);
      expect(conversation.messages.first.role, MessageRole.user);
      expect(conversation.messages.last.role, MessageRole.assistant);
    });

    test('creates a conversation without messages (empty list)', () {
      final conversation = Conversation(
        id: 'conv_002',
        userId: 'usr_001',
        title: 'New Chat',
        createdAt: DateTime.now(),
      );

      expect(conversation.messages, isEmpty);
      expect(conversation.lastMessageAt, isNull);
    });
  });
}
