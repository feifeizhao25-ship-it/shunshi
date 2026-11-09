import 'package:dio/dio.dart';

/// What the chat says when no reply came back. It never makes up a wellness reply: the message stays in the
/// input box and the user decides when to send it again. Same rule as the Chinese edition (chat_api.dart).
const seasonsOfflineChatNotice =
    "You're offline. SEASONS doesn't give wellness advice without a connection. Your message is still in the box; send it again when you're back online.";

bool isOfflineFailure(Object error) =>
    error is DioException && error.type == DioExceptionType.connectionError;

String chatFailureMessage(Object error) {
  if (isOfflineFailure(error)) return seasonsOfflineChatNotice;
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 401:
      case 403:
        return 'Your sign-in has expired or this account has no access. Sign in again, then retry.';
      case 429:
        return "You've reached the chat limit for now. Try again later or check your plan.";
      case 422:
        return "The message wasn't accepted. Check its length and format, then retry.";
    }
    if (error.type == DioExceptionType.receiveTimeout || error.type == DioExceptionType.connectionTimeout) {
      return "The reply timed out and we couldn't confirm it was received. Your message is still in the box; retry when you're ready.";
    }
    return "We couldn't get a reply. Your message is still in the box; check your connection and retry.";
  }
  return "The reply came back incomplete. Your message is still in the box; please retry.";
}
