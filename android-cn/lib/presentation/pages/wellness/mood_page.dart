import 'package:flutter/material.dart';

/// 正念呼吸引导数据
final List<Map<String, String>> _breathingSteps = [
  {'title': '调整姿势', 'desc': '找一个舒适的坐姿或仰卧位，轻轻闭上双眼'},
  {'title': '自然呼吸', 'desc': '不用刻意控制呼吸，先感受自然呼吸的节奏'},
  {'title': '吸气 4 秒', 'desc': '用鼻子缓慢吸气，感受腹部逐渐隆起'},
  {'title': '屏息 4 秒', 'desc': '轻轻屏住呼吸，感受身体的宁静'},
  {'title': '呼气 6 秒', 'desc': '用口缓慢呼气，感受身体的放松'},
  {'title': '保持觉察', 'desc': '重复以上呼吸循环，保持对当下呼吸的觉察'},
];

/// 情绪支持页面
class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  String? _selectedMood;

  final Map<String, Map<String, dynamic>> _moodResponses = {
    'happy': {
      'icon': '😊',
      'color': Colors.amber,
      'title': '保持好心情',
      'description': '开心的情绪是身心健康的最佳状态。中医认为"喜则气和"，适度的喜悦有利于气血通畅。',
      'tips': [
        {'title': '分享快乐', 'desc': '把你的快乐分享给身边的人，中医讲"喜则气缓"，分享能让喜悦更持久，还能增进人际关系'},
        {'title': '记录美好', 'desc': '用文字或照片记录当下的美好时刻，形成积极的心理暗示，有助于培养感恩的心态'},
        {'title': '适度运动', 'desc': '趁心情愉悦时做些运动，散步或瑜伽，让好心情和身体活力互相促进'},
        {'title': '品味当下', 'desc': '正念享受此刻的快乐，不做评判，全身心感受喜悦在身体中的流动'},
      ],
    },
    'sad': {
      'icon': '😢',
      'color': Colors.blue,
      'title': '我在这里陪你',
      'description': '中医讲"悲则气消"，过度悲伤会消耗正气。允许自己感受情绪，但也要注意调节，不让悲伤过久。',
      'tips': [
        {'title': '允许感受', 'desc': '不要压抑悲伤，给自己10-15分钟安静地感受情绪。中医认为情志需要适度表达，郁而不发反而伤身'},
        {'title': '疏肝理气', 'desc': '按揉太冲穴（足背大拇指与二趾之间），每次3-5分钟，有疏肝解郁之效'},
        {'title': '户外散步', 'desc': '到户外走走，接触自然。中医认为"人与天地相应"，自然的环境有助于舒畅气机'},
        {'title': '温热饮食', 'desc': '喝一杯温热的桂圆红枣茶，甜味入脾，能缓悲忧。避免生冷食物，以免加重脾虚'},
        {'title': '倾诉表达', 'desc': '给信任的人打个电话或写日记，将情绪表达出来。郁结于胸则气机不畅，适度宣泄有利健康'},
      ],
    },
    'anxious': {
      'icon': '😰',
      'color': Colors.orange,
      'title': '放轻松，一切都会好',
      'description': '中医认为焦虑多与心神不宁、肝气郁结有关。"思则气结"，过度思虑会使气机郁滞。放松身心是缓解焦虑的第一步。',
      'tips': [
        {'title': '4-7-8呼吸法', 'desc': '吸气4秒，屏息7秒，呼气8秒。这个呼吸法能快速激活副交感神经，让心跳减慢、血压降低'},
        {'title': '按揉内关穴', 'desc': '手腕横纹上三横指两筋之间，用拇指按揉3-5分钟。内关穴有宁心安神、理气宽胸之效'},
        {'title': '写下来', 'desc': '把担心的事情逐一写在纸上，然后评估哪些是能控制的。中医讲"思则气结"，外在化能解开郁结'},
        {'title': '温胆汤茶饮', 'desc': '半夏10g、竹茹10g、陈皮6g泡茶饮用，温胆和胃，适合焦虑失眠者'},
        {'title': '正念冥想', 'desc': '闭目静坐5-10分钟，专注于呼吸或身体感受，将注意力从焦虑的念头中抽离出来'},
      ],
    },
    'angry': {
      'icon': '😤',
      'color': Colors.red,
      'title': '先冷静一下',
      'description': '中医认为"怒则气上"，暴怒会使肝气上逆，导致头痛面赤、甚至晕厥。及时疏导怒气是保护健康的关键。',
      'tips': [
        {'title': '离开场景', 'desc': '先暂时离开让你生气的地方。中医讲"怒则气上"，物理远离有助于气机平复'},
        {'title': '按揉太冲穴', 'desc': '足背大拇指与二趾之间的凹陷处，用力按揉3-5分钟，有平肝潜阳之效'},
        {'title': '深呼吸十次', 'desc': '缓慢深呼吸，每次呼气时想象怒气从口中排出。深呼吸能直接调节自主神经系统'},
        {'title': '运动释放', 'desc': '做些有氧运动（快走、慢跑），将愤怒转化为身体能量。运动能消耗掉由愤怒产生的应激激素'},
        {'title': '菊花决明茶', 'desc': '菊花5朵、决明子10g泡茶饮用，清肝明目降火，适合怒气未消者'},
      ],
    },
    'tired': {
      'icon': '😴',
      'color': Colors.purple,
      'title': '好好休息一下吧',
      'description': '疲惫是身体在发出信号。中医认为疲劳多因气血不足或脾虚湿困所致。适当的休息和调理是恢复活力的基础。',
      'tips': [
        {'title': '小憩片刻', 'desc': '午时（11-13点）小憩15-20分钟。中医认为午时心经当令，此时休息最能养心安神'},
        {'title': '按揉足三里', 'desc': '膝盖骨下缘外侧向下量四横指处，按揉5-10分钟。足三里是"长寿穴"，能补益气血'},
        {'title': '枸杞黄芪茶', 'desc': '黄芪10g、枸杞10g泡茶饮用，补气养血，适合疲劳乏力者。气血足则精神旺'},
        {'title': '轻松拉伸', 'desc': '做5-10分钟的简单拉伸，活动颈椎、肩背和腰部，促进气血流通，缓解肌肉紧张'},
        {'title': '调整饮食', 'desc': '多吃补气血的食物（红枣、山药、小米粥），少吃生冷油腻。脾为后天之本，养好脾胃是解乏的根本'},
      ],
    },
    'lonely': {
      'icon': '😔',
      'color': Colors.teal,
      'title': '你并不孤单',
      'description': '中医认为孤独感多与心气不足、肝气郁结有关。"悲哀愁忧则心动，心动则五脏六腑皆摇"。适当社交和调理能改善孤独。',
      'tips': [
        {'title': '联系朋友', 'desc': '给久未联系的朋友发条消息或打个电话。人际交往能疏通气机，愉悦心情'},
        {'title': '玫瑰花茶', 'desc': '玫瑰花5朵、陈皮3g泡茶饮用，疏肝理气解郁，芳香能开窍醒神，缓解孤独感'},
        {'title': '参加活动', 'desc': '加入兴趣社群或志愿活动。社交能促进气的流通，减少肝气郁结'},
        {'title': '养一盆花草', 'desc': '照顾植物能获得陪伴感和成就感。中医讲人与自然相应，亲近自然能舒缓情志'},
        {'title': '写感恩日记', 'desc': '每天写3件值得感恩的事，培养积极心态。关注已有的美好，减少对孤独的关注'},
      ],
    },
    'stressed': {
      'icon': '😫',
      'color': Colors.deepOrange,
      'title': '学会释放压力',
      'description': '中医认为压力过大会导致肝气郁结、心脾两虚。长期压力是很多疾病的根源，学会管理压力对健康至关重要。',
      'tips': [
        {'title': '耳穴按摩', 'desc': '搓揉双耳至发热，然后点按耳垂中心、耳尖、神门穴各30秒。耳朵上分布着全身的穴位'},
        {'title': '八段锦练习', 'desc': '做一套八段锦（15分钟），特别是"双手托天理三焦"和"左右开弓似射雕"，能快速疏解压力'},
        {'title': '酸枣仁安神茶', 'desc': '酸枣仁15g、百合10g、茯苓10g煎水代茶饮，养心安神，适合压力导致的失眠焦虑'},
        {'title': '建立边界', 'desc': '学会说"不"，给自己留出独处和休息的时间。过度承担会导致气虚，适当放手才能更好地前行'},
      ],
    },
    'irritable': {
      'icon': '😤',
      'color': Colors.redAccent,
      'title': '平复一下心情',
      'description': '烦躁不安多与心火亢盛、肝阳上扰有关。中医讲"心藏神"，心火旺则神不安。清心降火是缓解烦躁的关键。',
      'tips': [
        {'title': '莲心茶', 'desc': '莲子心3-5g泡水饮用，清心火效果极佳。虽味苦但能快速平复烦躁不安'},
        {'title': '按揉涌泉穴', 'desc': '足底前1/3处，搓揉至发热。涌泉穴有引火归元之效，能将上扰的虚火引回肾中'},
        {'title': '冷水洗脸', 'desc': '用冷水轻轻拍打面部数次。冷水刺激能激活副交感神经，快速降温镇静'},
        {'title': '冥想静坐', 'desc': '闭目静坐5分钟，专注于呼吸。让烦躁的念头像云一样飘过，不去追随也不去对抗'},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪陪伴'),
        backgroundColor: Colors.pink[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI 对话入口
            Card(
              color: Colors.pink[50],
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/chat'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.pink[100],
                        child: const Text('🤖', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('和顺时聊聊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('随时倾听，陪伴你', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chat),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 正念呼吸引导入口
            Card(
              color: Colors.teal[50],
              child: InkWell(
                onTap: () => _showBreathingGuide(),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal[100],
                        child: const Text('🌬️', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('正念呼吸引导', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('跟着节奏，放松身心', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_outline),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('现在感觉如何？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _moodResponses.entries.map((entry) {
                return _buildMoodChip(entry.key, entry.value);
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_selectedMood != null) _buildSuggestions(),
          ],
        ),
      ),
    );
  }

  void _showBreathingGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌬️ 正念呼吸引导'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _breathingSteps.map((step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${_breathingSteps.indexOf(step) + 1}',
                      style: TextStyle(fontSize: 12, color: Colors.teal[800]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(step['desc']!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/chat');
            },
            child: const Text('开始引导'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String key, Map<String, dynamic> data) {
    final isSelected = _selectedMood == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? data['color'] : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? data['color'] : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data['icon'], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              _getMoodLabel(key),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodLabel(String key) {
    const labels = {
      'happy': '开心',
      'sad': '难过',
      'anxious': '焦虑',
      'angry': '生气',
      'tired': '疲惫',
      'lonely': '孤独',
      'stressed': '压力大',
      'irritable': '烦躁',
    };
    return labels[key] ?? key;
  }

  Widget _buildSuggestions() {
    final data = _moodResponses[_selectedMood]!;
    final tips = data['tips'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: (data['color'] as Color).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data['icon'], style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text(data['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(data['description'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('缓解方法', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tips.map((tip) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: data['color'] as Color),
                    const SizedBox(width: 8),
                    Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tip['desc'], style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
