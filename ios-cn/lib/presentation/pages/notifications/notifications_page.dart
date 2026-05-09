/// 通知页面
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/state_view.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient().get('/api/v1/notifications/',
        queryParameters: {'user_id': 'guest', 'limit': 50});
      if (resp.data?['success'] == true) {
        final items = resp.data['data']['items'] as List<dynamic>? ?? [];
        if (mounted) setState(() { _items = items; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = '加载失败'; });
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'solar_term': return Icons.eco;
      case 'shichen': return Icons.schedule;
      case 'checkin': return Icons.check_circle;
      case 'system': return Icons.info;
      case 'subscription': return Icons.star;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('通知', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StateView<List<dynamic>>(
        loading: _loading,
        error: _error,
        data: _items.isEmpty && !_loading ? null : _items,
        onRetry: _loadNotifications,
        loadingWidget: const LoadingSkeleton(itemCount: 4),
        builder: (items) => items.isEmpty
          ? const ErrorView(message: '暂无通知', icon: Icons.notifications_none)
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isRead = item['is_read'] == true;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRead ? ShunShiColors.surface : ShunShiColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcon(item['type']), color: ShunShiColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['title'] ?? '通知', style: TextStyle(fontSize: 15, fontWeight: isRead ? FontWeight.w400 : FontWeight.w600, color: ShunShiColors.textPrimary)),
                        if (item['body'] != null && item['body'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(item['body'].toString(), style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
                        ],
                        const SizedBox(height: 4),
                        Text(item['created_at']?.toString().substring(0, 16) ?? '', style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
                      ])),
                      if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: ShunShiColors.primary, shape: BoxShape.circle)),
                    ]),
                  );
                },
              ),
            ),
      ),
    );
  }
}
