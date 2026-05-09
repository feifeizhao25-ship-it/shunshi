/// 分享工具 — 调用后端生成海报 + 系统分享
library;

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareUtil {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'http://116.62.32.43:4000',
    connectTimeout: const Duration(seconds: 15),
    responseType: ResponseType.bytes,
  ));

  /// 生成节气分享海报
  static Future<Uint8List?> generateSolarTermCard({
    required String termName,
    required String principle,
    String quote = '',
  }) async {
    try {
      final res = await _dio.post('/api/v1/share/solar-term-card', data: {
        'term_name': termName,
        'principle': principle,
        'quote': quote,
        'product_version': 'cn',
      });
      if (res.statusCode == 200 && res.data is List<int>) {
        return Uint8List.fromList(res.data as List<int>);
      }
    } catch (_) {}
    return null;
  }

  /// 生成体质报告海报
  static Future<Uint8List?> generateConstitutionCard({
    required String typeName,
    required Map<String, dynamic> scores,
  }) async {
    try {
      final res = await _dio.post('/api/v1/share/constitution-card', data: {
        'type_name': typeName,
        'scores': scores,
        'product_version': 'cn',
      });
      if (res.statusCode == 200 && res.data is List<int>) {
        return Uint8List.fromList(res.data as List<int>);
      }
    } catch (_) {}
    return null;
  }

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
