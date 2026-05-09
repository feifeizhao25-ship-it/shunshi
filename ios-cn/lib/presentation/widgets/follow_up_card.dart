import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

/// 跟进卡片 — 显示在首页的养生提醒
class FollowUpCard extends StatefulWidget {
  const FollowUpCard({super.key});

  @override
  State<FollowUpCard> createState() => _FollowUpCardState();
}

class _FollowUpCardState extends State<FollowUpCard> {
  List<Map<String, dynamic>> _items = [];
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    try {
      final dio = Dio();
      final res = await dio.get('http://116.62.32.43:4000/api/v1/followup/list');
      if (res.data is List) {
        setState(() => _items = List<Map<String, dynamic>>.from(res.data));
      }
    } catch (_) {
      // Demo items
      setState(() => _items = [
        {'id': '1', 'title': '昨晚睡得好吗？', 'type': 'wellness'},
        {'id': '2', 'title': '今天试试菊花茶？', 'type': 'content'},
        {'id': '3', 'title': '记得午后散步 15 分钟', 'type': 'lifestyle'},
      ]);
    }
  }

  Future<void> _complete(String id) async {
    try {
      final dio = Dio();
      await dio.post('http://116.62.32.43:4000/api/v1/user/feedback', data: {
        'followup_id': id, 'action': 'completed',
      });
    } catch (_) {}
    setState(() => _dismissed.add(id));
  }

  void _remindLater(String id) {
    setState(() => _dismissed.add(id));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('稍后会再提醒你'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((e) => !_dismissed.contains(e['id'])).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visible.map((item) {
        return Dismissible(
          key: Key(item['id']),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => setState(() => _dismissed.add(item['id'])),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ShunShiColors.borderGhost),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_outlined, size: 18, color: ShunShiColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(item['title'] ?? '',
                  style: const TextStyle(fontSize: 15, color: ShunShiColors.textPrimary, height: 1.3))),
              const SizedBox(width: 8),
              // 已完成 button
              GestureDetector(
                onTap: () => _complete(item['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✓ 已完成',
                      style: TextStyle(fontSize: 12, color: ShunShiColors.primary, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _remindLater(item['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ShunShiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('⏰ 稍后',
                      style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
