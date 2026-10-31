// 顺时·官方资料库：药食同源、运动、睡眠、节气、消费避坑等，每条都对照官方文件整理。
// 数据：assets/library/reference_entries_v1.json；审核门禁和页面实现见 reference_library_page.dart。
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/network/api_client.dart';
import 'library_live.dart';
import 'library_strings_zh.dart';
import 'reference_library_page.dart';

const String kShunshiLibraryAsset = 'assets/library/reference_entries_v1.json';

final LibraryStrings kShunshiLibraryStrings = libraryStringsZh(
  title: '官方资料库',
  intro: '药食同源、运动、睡眠、节气、消费避坑……每一条都对照官方文件整理，写明出处、文号和读取日期，点进去可以看原文。',
  footer: '这里是科普整理，不是诊断或治疗建议；身体不舒服请及时就医。未经审核的条目不会出现，也不会被 AI 当作依据。',
);

Future<void> _openInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// 资料库的后端接口（条目带展示规则、个性化推荐、关注/关闭、来访记录）。
LibraryLiveApi shunshiLibraryLive([ApiClient? client]) {
  final api = client ?? ApiClient();
  Map<String, dynamic> body(dynamic data) => Map<String, dynamic>.from(data as Map);
  return LibraryLiveApi(
    entries: () async => body((await api.get('/library/entries')).data),
    feed: () async => body((await api.get('/library/feed')).data),
    setPrefs: (b) async {
      await api.put('/library/preferences', data: b);
    },
    visit: () async {
      await api.post('/library/visit');
    },
    opened: (id) async {
      await api.post('/library/opened/$id');
    },
  );
}

class ShunshiReferenceLibraryPage extends StatelessWidget {
  const ShunshiReferenceLibraryPage({super.key, this.live});

  /// 测试用：注入假的接口；不传就用真实后端。
  final LibraryLiveApi? live;

  @override
  Widget build(BuildContext context) => ReferenceLibraryPage(
        strings: kShunshiLibraryStrings,
        assetPath: kShunshiLibraryAsset,
        openUrl: _openInBrowser,
        fontFamily: 'NotoSansSC',
        live: live ?? shunshiLibraryLive(),
      );
}

/// 养生馆里的入口卡片；没有已审核条目时不显示。
class ShunshiReferenceLibraryTile extends StatelessWidget {
  const ShunshiReferenceLibraryTile({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ReferenceLibraryEntryTile(
        strings: kShunshiLibraryStrings,
        assetPath: kShunshiLibraryAsset,
        title: '官方资料库',
        subtitle: '对照官方文件整理，写明出处与日期',
        onTap: onTap,
      );
}
