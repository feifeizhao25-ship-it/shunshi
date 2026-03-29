import 'package:flutter/material.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  // 模拟家庭数据
  Map<String, dynamic>? _family;
  final List<Map<String, dynamic>> _members = [];
  final List<Map<String, dynamic>> _careLogs = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        _family = {
          'id': 'family_001',
          'name': '我的家庭',
          'member_count': 3,
        };
        
        _members.addAll([
          {'id': '1', 'name': '爸爸', 'relation': '父亲', 'age': 55, 'constitution': '阳虚质', 'avatar': '👨'},
          {'id': '2', 'name': '妈妈', 'relation': '母亲', 'age': 52, 'constitution': '气虚质', 'avatar': '👩'},
          {'id': '3', 'name': '我', 'relation': '本人', 'age': 30, 'constitution': '平和质', 'avatar': '🧑'},
        ]);
        
        _careLogs.addAll([
          {'time': '今天 09:00', 'content': '提醒爸爸测量血压', 'status': 'completed'},
          {'time': '今天 14:00', 'content': '提醒妈妈喝养生茶', 'status': 'pending'},
          {'time': '昨天 20:00', 'content': '查看爸爸睡眠数据', 'status': 'completed'},
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭关怀'),
        centerTitle: true,
        backgroundColor: Colors.blue[50],
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddMemberDialog(),
          ),
        ],
      ),
      body: _family == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFamilyData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 家庭状态卡片
                  _buildFamilyStatusCard(),
                  const SizedBox(height: 20),
                  
                  // 关怀记录
                  _buildCareSection(),
                  const SizedBox(height: 20),
                  
                  // 家庭成员
                  _buildMembersSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCareDialog(),
        icon: const Icon(Icons.favorite),
        label: const Text('发送关怀'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFamilyStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.family_restroom, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Text('${_family!['name']} (${_family!['member_count']}人)', 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('3', '成员', Icons.people),
              _buildStatItem('2', '今日关怀', Icons.favorite),
              _buildStatItem('1', '待提醒', Icons.notifications),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 24),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _buildCareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近关怀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._careLogs.map((log) => _buildCareCard(log)),
      ],
    );
  }

  Widget _buildCareCard(Map<String, dynamic> log) {
    final isCompleted = log['status'] == 'completed';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            isCompleted ? Icons.check : Icons.schedule,
            color: isCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(log['content']),
        subtitle: Text(log['time']),
        trailing: Text(
          isCompleted ? '已完成' : '待执行',
          style: TextStyle(
            color: isCompleted ? Colors.green : Colors.orange,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('家庭成员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._members.map((member) => _buildMemberCard(member)),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMemberDetail(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(member['avatar'], style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${member['relation']} · ${member['age']}岁', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        member['constitution'],
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
              Column(children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => Navigator.pushNamed(context, '/chat'),
                  color: Colors.green,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () => _sendCare(member),
                  color: Colors.pink,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('添加家庭成员', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: '姓名', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: '关系', hintText: '如：父亲、母亲', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: '出生年份', hintText: '如：1960', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('成员添加成功')),
                  );
                },
                child: const Text('添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCareDialog() {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加家庭成员')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('发送关怀', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ..._members.map((member) => ListTile(
              leading: Text(member['avatar'], style: const TextStyle(fontSize: 24)),
              title: Text(member['name']),
              subtitle: Text(member['relation']),
              onTap: () {
                Navigator.pop(context);
                _sendCare(member);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _sendCare(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('关怀 ${member['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.pink),
              title: const Text('健康提醒'),
              onTap: () => _sendCareMessage(member, '健康提醒'),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant, color: Colors.orange),
              title: const Text('养生建议'),
              onTap: () => _sendCareMessage(member, '养生建议'),
            ),
            ListTile(
              leading: const Icon(Icons.medication, color: Colors.blue),
              title: const Text('服药提醒'),
              onTap: () => _sendCareMessage(member, '服药提醒'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _sendCareMessage(Map<String, dynamic> member, String type) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已向 ${member['name']} 发送$type')),
    );
    
    setState(() {
      _careLogs.insert(0, {
        'time': '刚刚',
        'content': '${member['name']}的$type',
        'status': 'completed',
      });
    });
  }

  void _showMemberDetail(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(member['avatar'], style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(member['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('${member['relation']} · ${member['age']}岁', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Chip(label: Text('${member['constitution']}'), backgroundColor: Colors.green[50]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.chat, '对话', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/chat');
                }),
                _buildActionButton(Icons.favorite, '关怀', () {
                  Navigator.pop(context);
                  _sendCare(member);
                }),
                _buildActionButton(Icons.analytics, '报告', () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(children: [
        CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(icon, color: Colors.green[700]),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
