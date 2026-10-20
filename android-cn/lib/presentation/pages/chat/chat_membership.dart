/// Only verified membership fields grant a paid badge. Quotas are enforced by
/// the chat API; the membership response does not contain a remaining count.
bool parseChatMembership(dynamic body) {
  if (body is! Map || body['success'] != true || body['data'] is! Map) {
    throw const FormatException('会员状态响应无效');
  }
  final data = body['data'] as Map;
  final plan = data['plan'];
  final active = data['is_active'];
  if (active is! bool ||
      !['free', 'yangxin', 'yiyang', 'jiahe'].contains(plan)) {
    throw const FormatException('会员状态不完整');
  }
  if (active != (plan != 'free')) {
    throw const FormatException('会员状态不一致');
  }
  return active;
}
