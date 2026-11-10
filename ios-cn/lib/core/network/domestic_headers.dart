/// 国内客户端的请求边界。
///
/// `X-App-Market: cn` 让英文浏览器语言也不会把国内包切成国际版。
/// 测试时钟头只在编译开关打开时出现，正式包不会发送。
Map<String, String> domesticRequestHeaders() {
  final headers = <String, String>{'X-App-Market': 'cn'};
  const clock = bool.fromEnvironment('SHUNSHI_TEST_CLOCK');
  if (!clock) return headers;
  final raw = Uri.base.queryParameters['test_now'];
  if (raw != null && raw.isNotEmpty) {
    headers['X-Shunshi-Test-Now'] = raw;
  }
  return headers;
}
