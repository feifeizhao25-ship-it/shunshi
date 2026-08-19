import '../../domain/entities/ai_response.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/solar_term.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/ai_router_datasource.dart';
import '../datasources/local/chat_local_datasource.dart';

/// ChatRepository 实现
class ChatRepositoryImpl implements ChatRepository {
  final AIRouterDatasource _remote;
  final ChatLocalDatasource _local;

  ChatRepositoryImpl({
    required AIRouterDatasource remote,
    required ChatLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<AIResponse> sendMessage({
    required String sessionId,
    required String message,
    required UserContext userContext,
    required Map<String, String> promptVersions,
  }) async {
    return _remote.sendMessage(
      sessionId: sessionId,
      message: message,
      userContext: userContext,
      promptVersions: promptVersions,
    );
  }

  @override
  Future<DailyPlan> generateDailyPlan({
    required UserContext userContext,
    required Map<String, String> promptVersions,
  }) async {
    // 先查缓存
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cached = await _local.getDailyPlan(today);
    if (cached != null) return cached;

    // 请求 AI Router
    final plan = await _remote.generateDailyPlan(
      userContext: userContext,
      promptVersions: promptVersions,
    );

    // 缓存
    await _local.saveDailyPlan(plan);
    return plan;
  }

  @override
  Future<List<Conversation>> getConversations() async {
    // TODO: Implement with remote + local merge
    return [];
  }

  @override
  Future<List<Message>> getMessages(String sessionId) async {
    return _local.getMessages(sessionId);
  }

  @override
  Future<Conversation> createConversation() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return Conversation(id: id, createdAt: DateTime.now());
  }

  @override
  Future<void> saveMessageLocally(String sessionId, Message message) async {
    await _local.saveMessage(sessionId, message);
  }
}
