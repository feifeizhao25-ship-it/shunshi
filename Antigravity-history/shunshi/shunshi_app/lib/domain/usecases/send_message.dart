import '../../data/models/ai_response.dart';
import '../../data/models/message.dart';
import '../../data/models/user_context.dart';
import '../repositories/ai_repository.dart';

class SendMessage {
  final AiRepository _repository;

  SendMessage(this._repository);

  /// 执行发送消息用例
  /// 返回 (AI响应, 转化后的消息对象)
  Future<(AiResponse, Message)> call({
    required String userId,
    required UserContext context,
    required String text,
    required String messageId,
  }) async {
    final response = await _repository.sendMessage(
      userId: userId,
      context: context,
      message: text,
    );

    final messageType = response.needsSafeMode
        ? MessageType.system
        : (response.cards?.isNotEmpty == true ? MessageType.card : MessageType.text);

    final msg = Message(
      id: messageId,
      type: messageType,
      sender: MessageSender.assistant,
      text: response.text,
      cards: response.cards
          ?.map((c) => MessageCard(
                type: c.type,
                contentId: c.contentId,
                title: c.title,
                media: c.media,
              ))
          .toList(),
      tone: response.tone,
      createdAt: DateTime.now(),
      isSafetyFlagged: response.needsSafeMode,
    );

    // 保存消息记录
    await _repository.saveMessage(userId, msg);

    return (response, msg);
  }
}
