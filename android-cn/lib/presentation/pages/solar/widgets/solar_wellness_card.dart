/// 节气养生卡片 — 显示当前节气+时辰+饮食建议
library;

import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class SolarWellnessCard extends StatefulWidget {
  const SolarWellnessCard({super.key});

  @override
  State<SolarWellnessCard> createState() => _SolarWellnessCardState();
}

class _SolarWellnessCardState extends State<SolarWellnessCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 使用 Dio 直接请求
      final dio = Dio(BaseOptions(
        baseUrl: 'http://116.62.32.43:4000',
        connectTimeout: const Duration(seconds: 5),
      ));
      final res = await dio.get('/api/v1/solar-wellness/daily-advice');
      if (res.data is Map && res.data['success'] == true) {
        _data = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {
      // 静默失败
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildSkeleton();
    }
    if (_data == null) return const SizedBox.shrink();

    final solar = _data!['solar_term'] as Map<String, dynamic>? ?? {};
    final shichen = _data!['shichen'] as Map<String, dynamic>? ?? {};
    final dietList = (_data!['diet_recommend'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ShunShiColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: 节气 + 时辰
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${solar['name'] ?? ''}节气',
                  style: const TextStyle(
                    color: Color(0xFFFDF9F4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF74593C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${shichen['name'] ?? ''} ${shichen['organ'] ?? ''}经当令',
                  style: const TextStyle(
                    color: Color(0xFF74593C),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 养生原则
          Text(
            solar['principle'] ?? '',
            style: const TextStyle(
              color: ShunShiColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // 饮食建议
          if (dietList.isNotEmpty) ...[
            const Text(
              '宜食',
              style: TextStyle(
                color: Color(0xFF74593C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: dietList.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: ShunShiColors.primary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 8),

          // 时辰建议
          if (shichen['advice'] != null)
            Text(
              shichen['advice'] as String,
              style: TextStyle(
                color: const Color(0xFF4C3605).withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 12),
          // View details button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/solar-wellness'),
              icon: Icon(Icons.arrow_forward, size: 16, color: ShunShiColors.primary),
              label: Text('查看详情', style: TextStyle(color: ShunShiColors.primary, fontSize: 13)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20))),
            const SizedBox(width: 8),
            Container(width: 100, height: 24, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20))),
          ]),
          const SizedBox(height: 12),
          Container(width: 200, height: 16, color: Colors.grey[200]),
          const SizedBox(height: 8),
          Container(width: 150, height: 12, color: Colors.grey[200]),
        ],
      ),
    );
  }
}
