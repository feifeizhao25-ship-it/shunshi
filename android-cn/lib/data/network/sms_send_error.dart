import 'package:dio/dio.dart';

/// 把发验证码的失败收成登录页上的一句话。
///
/// 接口没配短信时返回 503，正文是「短信服务尚未配置」。以前这里一律写成
/// 「发送失败，请稍后重试」，用户看不出是服务没配，还是网络断了。
String smsSendError(Object error) {
  final text = _flatten(error is DioException ? error.response?.data : null);
  if (text.contains('短信服务尚未配置')) return '短信服务尚未配置';
  return '发送失败，请稍后重试';
}

String _flatten(dynamic data) {
  if (data == null) return '';
  if (data is String) return data;
  if (data is Map) return data.values.map(_flatten).join(' ');
  if (data is List) return data.map(_flatten).join(' ');
  return data.toString();
}
