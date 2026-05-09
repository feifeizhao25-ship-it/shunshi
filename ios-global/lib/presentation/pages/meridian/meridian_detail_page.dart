/// 经络详情页 — 展示十二经络按揉指南
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../widgets/state_view.dart';

class MeridianDetailPage extends StatefulWidget {
  final String meridianId;
  const MeridianDetailPage({super.key, required this.meridianId});

  @override
  State<MeridianDetailPage> createState() => _MeridianDetailPageState();
}

class _MeridianDetailPageState extends State<MeridianDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final resp = await ApiClient().get('/api/v1/contents/${widget.meridianId}');
      final data = resp.data;
      if (data != null && data['success'] == true) {
        setState(() { _data = data['data']; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(_data?['title'] ?? '经络详情',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: StateView<Map<String, dynamic>>(
        loading: _loading,
        error: !_loading && _data == null ? '内容加载失败' : null,
        data: _data,
        onRetry: _loadData,
        loadingWidget: const LoadingSkeleton(itemCount: 1),
        builder: (data) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [ShunShiColors.primary, ShunShiColors.primary.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_data?['subtitle'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFFE4C285))),
                        const SizedBox(height: 8),
                        Text(_data?['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        if (_data?['best_time'] != null)
                          Row(children: [
                            const Icon(Icons.access_time, color: Color(0xFFE4C285), size: 16),
                            const SizedBox(width: 6),
                            Text('最佳时间：${_data?['best_time']}', style: const TextStyle(fontSize: 13, color: Color(0xFFE4C285))),
                          ]),
                        if (_data?['duration_minutes'] != null && _data?['duration_minutes'] > 0) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.timer, color: Color(0xFFE4C285), size: 16),
                            const SizedBox(width: 6),
                            Text('预计时长：${_data?['duration_minutes']}分钟', style: const TextStyle(fontSize: 13, color: Color(0xFFE4C285))),
                          ]),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text('经络概述', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(_data?['description'] ?? '', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8)),
                    const SizedBox(height: 20),

                    // Steps
                    Text('按揉步骤', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    const SizedBox(height: 8),
                    _buildSteps(),
                    const SizedBox(height: 20),

                    // Caution
                    if (_data?['caution'] != null && _data!['caution'].toString().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_data!['caution'].toString(),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF795548), height: 1.6))),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Source
                    if (_data?['source_classic'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ShunShiColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(Icons.menu_book, size: 16, color: ShunShiColors.textTertiary),
                          const SizedBox(width: 8),
                          Text('出处：${_data!['source_classic']}',
                            style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, fontStyle: FontStyle.italic)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tags
                    if (_data?['tags'] != null) ...[
                      Wrap(spacing: 8, runSpacing: 8,
                        children: (_data!['tags'] as List).map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ShunShiColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(t.toString(), style: TextStyle(fontSize: 12, color: ShunShiColors.primary)),
                        )).toList()),
                      const SizedBox(height: 20),
                    ],

                    // Quote
                    Center(child: Text('"通则不痛，痛则不通。"',
                      style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 14,
                        fontStyle: FontStyle.italic, color: ShunShiColors.textTertiary))),
                    const SizedBox(height: 40),
                  ]),
                ),
      ),
    );
  }

  Widget _buildSteps() {
    final steps = _data?['steps'];
    if (steps == null) return const SizedBox.shrink();
    List<String> stepList;
    if (steps is List) {
      stepList = steps.map((s) => s.toString()).toList();
    } else if (steps is String) {
      stepList = [steps];
    } else {
      return const SizedBox.shrink();
    }
    return Column(children: stepList.asMap().entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${e.key + 1}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.primary))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(e.value,
            style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6))),
        ]),
      );
    }).toList());
  }
}
