import 'package:dio/dio.dart';

String parseGuestToken(dynamic body) {
  final token = body is Map ? body['access_token'] : null;
  if (token is! String || token.trim().isEmpty) {
    throw const FormatException('未取得有效登录凭证');
  }
  return token;
}

class ChatReply {
  final String text;
  final List<String> sources;
  final String? usageReminder;
  ChatReply(this.text, this.sources, {this.usageReminder});
}

Future<ChatReply> sendChat(Dio client, String token, String text) async {
  final response = await client.post(
    '/api/v1/chat/send',
    data: {'message': text},
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
      receiveTimeout: const Duration(seconds: 75),
    ),
  );
  final body = response.data;
  final content = body is Map ? body['text'] : null;
  if (content is! String || content.trim().isEmpty) {
    throw const FormatException('服务未返回有效回复');
  }
  final sources = body['sources'];
  if (sources != null &&
      (sources is! List || sources.any((s) => s is! String))) {
    throw const FormatException('回复来源格式错误');
  }
  String? reminder;
  final rawReminder = body['usage_reminder'];
  if (rawReminder is Map && rawReminder['text'] is String) {
    final text = (rawReminder['text'] as String).trim();
    if (text.isNotEmpty) reminder = text;
  }
  return ChatReply(
    content,
    sources == null ? [] : List<String>.from(sources),
    usageReminder: reminder,
  );
}

/// 设备没有网络、请求根本没发出去（区别于超时：超时时服务端可能已处理）。
bool isOfflineFailure(Object error) =>
    error is DioException && error.type == DioExceptionType.connectionError;

String chatFailureMessage(Object error) {
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 401:
      case 403:
        return '登录状态已失效或没有访问权限，请重新登录后重试。';
      case 429:
        return '当前对话额度或服务频率已达上限，请稍后重试或查看会员权益。';
      case 422:
        return '消息未被接受，请检查内容长度和格式后重试。';
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionTimeout) {
      return '等待回复超时，尚未确认服务端结果。输入已保留，请稍后检查再决定是否重试。';
    }
    return '暂时无法取得回复，输入已保留，请检查网络或稍后重试。';
  }
  return '服务未返回完整有效的回复，输入已保留，请稍后重试。';
}
