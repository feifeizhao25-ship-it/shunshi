/// 分享工具 — 调用后端生成分享卡片 + 系统分享
library;

import 'package:dio/dio.dart';
import '../../data/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 后端 POST /api/v1/share/card 返回的分享卡片（文案 + 链接）。
class ShareCard {
  final String shareId;
  final String title;
  final String text;
  final String shareUrl;
  final List<String> hashtags;

  const ShareCard({
    required this.shareId,
    required this.title,
    required this.text,
    required this.shareUrl,
    this.hashtags = const [],
  });

  factory ShareCard.fromJson(Map<String, dynamic> json) => ShareCard(
        shareId: (json['share_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        text: (json['text'] ?? '').toString(),
        shareUrl: (json['share_url'] ?? '').toString(),
        hashtags: ((json['hashtags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

typedef SharePoster = Future<Response> Function(String path, {dynamic data});

class ShareUtil {
  /// 后端 custom_message 上限 200 字。
  static const int maxMessageLength = 200;
  static const String cardPath = '/api/v1/share/card';

  /// 测试用：替换发请求的函数。默认走应用统一的 ApiClient（自动带 Authorization，401 时刷新令牌）。
  static SharePoster? poster;

  static Future<Response> _post(Map<String, dynamic> body) {
    final send = poster ?? ApiClient().post;
    return send(cardPath, data: body);
  }

  static String _clip(String text) =>
      text.length <= maxMessageLength ? text : text.substring(0, maxMessageLength);

  /// 节气卡片的请求体。身份由登录令牌决定，不再带 user_id。
  static Map<String, dynamic> solarTermRequest({
    required String termName,
    required String principle,
    String quote = '',
  }) =>
      {
        'type': 'solar_term',
        'content': termName,
        'platform': 'wechat',
        'custom_message': _clip([principle, quote].where((e) => e.trim().isNotEmpty).join(' ')),
      };

  /// 体质报告卡片的请求体：体质名 + 得分最高的三项。
  static Map<String, dynamic> constitutionRequest({
    required String typeName,
    required Map<String, dynamic> scores,
  }) {
    final top = scores.entries.where((e) => e.value is num).toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final lead = top.take(3).map((e) => '${e.key} ${(e.value as num).round()}').join('、');
    return {
      'type': 'constitution',
      'content': typeName,
      'platform': 'wechat',
      'custom_message': _clip(lead.isEmpty ? typeName : '$typeName，主要倾向：$lead'),
    };
  }

  static ShareCard? parseCard(Response res) {
    final data = res.data;
    if (res.statusCode == 200 && data is Map && data['data'] is Map && data['data']['card'] is Map) {
      return ShareCard.fromJson(Map<String, dynamic>.from(data['data']['card'] as Map));
    }
    return null;
  }

  static Future<ShareCard?> _create(Map<String, dynamic> body) async {
    try {
      return parseCard(await _post(body));
    } catch (_) {
      return null; // 未登录(401)、文案被拦(422)或网络错误：不分享，界面照常
    }
  }

  /// 生成节气分享卡片
  static Future<ShareCard?> generateSolarTermCard({
    required String termName,
    required String principle,
    String quote = '',
  }) =>
      _create(solarTermRequest(termName: termName, principle: principle, quote: quote));

  /// 生成体质报告分享卡片
  static Future<ShareCard?> generateConstitutionCard({
    required String typeName,
    required Map<String, dynamic> scores,
  }) =>
      _create(constitutionRequest(typeName: typeName, scores: scores));

  /// 显示分享底部菜单
  static void showShareSheet(BuildContext context, {
    required String title,
    required String content,
    Uint8List? imageBytes,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Text('分享到', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _shareItem(ctx, Icons.chat, '微信好友', Colors.green, text: content),
            _shareItem(ctx, Icons.circle, '朋友圈', Colors.green.shade700, text: content),
            _shareItem(ctx, Icons.content_copy, '复制文案', Colors.grey, text: content),
            if (imageBytes != null) _shareItem(ctx, Icons.save_alt, '保存图片', Colors.blue, text: content),
          ]),
        ]),
      ),
    );
  }

  static Widget _shareItem(BuildContext ctx, IconData icon, String label, Color color, {String? text}) => GestureDetector(
    onTap: () {
      Navigator.pop(ctx);
      if (label == '复制文案' && text != null) {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)));
      }
    },
    child: Column(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 24)),
      SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    ]),
  );
}
