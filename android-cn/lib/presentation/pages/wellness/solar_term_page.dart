import 'package:flutter/material.dart';

/// 节气养生页面
class SolarTermPage extends StatelessWidget {
  const SolarTermPage({super.key});

  @override
  Widget build(BuildContext context) {
    final solarTerms = [
      {'name': '立春', 'date': '2月3-5日', 'tip': '养肝护肝', 'food': '菠菜、豆芽', 'color': Colors.green, 'desc': '东风解冻，万物复苏，宜早睡早起，舒展身体'},
      {'name': '雨水', 'date': '2月18-20日', 'tip': '健脾祛湿', 'food': '山药、薏米', 'color': Colors.blue, 'desc': '降雨增多，空气湿润，宜调理脾胃'},
      {'name': '惊蛰', 'date': '3月5-7日', 'tip': '春捂防寒', 'food': '梨、蜂蜜', 'color': Colors.orange, 'desc': '春雷始鸣，宜保护阳气，预防感冒'},
      {'name': '春分', 'date': '3月20-22日', 'tip': '阴阳平衡', 'food': '银耳、百合', 'color': Colors.purple, 'desc': '昼夜相等，宜调和阴阳，适当运动'},
      {'name': '清明', 'date': '4月4-6日', 'tip': '踏青养心', 'food': '艾草、青团', 'color': Colors.green, 'desc': '气清景明，宜外出踏青，调畅情志'},
      {'name': '谷雨', 'date': '4月19-21日', 'tip': '祛湿健脾', 'food': '香椿、枸杞', 'color': Colors.teal, 'desc': '雨生百谷，宜健脾祛湿，保养皮肤'},
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('节气养生'),
        centerTitle: true,
        backgroundColor: Colors.green[50],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: solarTerms.length,
        itemBuilder: (context, index) {
          final term = solarTerms[index];
          final isCurrent = term['name'] == '惊蛰';
          return _buildSolarTermCard(context, term, isCurrent);
        },
      ),
    );
  }

  Widget _buildSolarTermCard(BuildContext context, Map<String, dynamic> term, bool isCurrent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [(term['color'] as Color).withAlpha(25), (term['color'] as Color).withAlpha(12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: term['color'], borderRadius: BorderRadius.circular(20)),
                child: Text(term['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(term['date'], style: TextStyle(color: Colors.grey.shade600)),
              const Spacer(),
              if (isCurrent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                child: const Text('当前', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(term['desc'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              _buildInfoChip('🌿 ${term['tip']}'),
              const SizedBox(width: 8),
              _buildInfoChip('🍽️ ${term['food']}'),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/food'),
                icon: const Icon(Icons.restaurant_menu, size: 16),
                label: const Text('食疗方案'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('AI 咨询'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
