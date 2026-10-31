import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/network/api_client.dart';
import '../../../widgets/personal_home_section.dart';
import '../../../widgets/personal_home_strings_zh.dart';

/// Connects the personalised-home block to this app's authenticated API client.
class PersonalHomeBinding {
  const PersonalHomeBinding._();

  /// This edition's text; the shared widget carries no language of its own.
  static const PersonalHomeStrings strings = kPersonalHomeStringsZh;

  static PersonalHomeApi api() => PersonalHomeApi(
        load: () async {
          final res = await ApiClient().get('/api/v1/seasons/home/dashboard');
          final data = res.data;
          if (data is! Map) throw StateError('unexpected response');
          return Map<String, dynamic>.from(data);
        },
        setEnabled: (enabled) async {
          await ApiClient().post('/api/v1/seasons/profile/preferences', data: {'personalization_enabled': enabled});
        },
      );

  /// 首页卡片带站内路径（目前只有资料库那张：/reference-library）时跳转；只接受 app 内路径，不接受外链。
  static void open(BuildContext context, PersonalHomeCard card) {
    final href = card.href;
    if (href == null || !href.startsWith('/') || href.startsWith('//')) return;
    GoRouter.of(context).push(href);
  }
}
