import 'package:flutter/material.dart';

/// 睡眠改善数据模型
class _SleepTip {
  final String title;
  final String category;
  final IconData icon;
  final String content;
  final List<String> steps;

  const _SleepTip({
    required this.title,
    required this.category,
    required this.icon,
    required this.content,
    required this.steps,
  });
}

/// 睡眠改善常量数据
const List<_SleepTip> _kSleepTips = [
  // === 入睡技巧 ===
  _SleepTip(title: '4-7-8呼吸法', category: '入睡技巧', icon: Icons.air,
    content: '由哈佛大学安德鲁·韦尔博士推广的呼吸法，能快速激活副交感神经，帮助身体进入放松状态。吸气4秒、屏息7秒、呼气8秒，循环3-5次即可感受到困意。',
    steps: [
      '仰卧或舒适坐姿，放松全身肌肉',
      '舌尖抵住上颚门牙后方',
      '用鼻缓慢吸气4秒，感受腹部隆起',
      '屏住呼吸7秒，保持放松',
      '用口缓慢呼气8秒，发出轻微呼气声',
      '重复3-5个循环，直到自然入睡',
    ]),
  _SleepTip(title: '身体扫描放松法', category: '入睡技巧', icon: Icons.accessibility,
    content: '源自正念冥想，通过依次关注身体各部位来释放紧张，逐渐引导身心进入深度放松状态。',
    steps: [
      '仰卧，闭上双眼，做3次深呼吸',
      '从头顶开始，感受头部的放松',
      '注意力依次移向面部、颈部、肩膀',
      '继续扫描手臂、胸腔、腹部',
      '再到臀部、大腿、小腿、双脚',
      '在感到紧张的部位多做几次深呼吸',
    ]),
  _SleepTip(title: '数息法', category: '入睡技巧', icon: Icons.self_improvement,
    content: '源自佛家禅修，是最古老的助眠方法之一。通过专注计数呼吸来安定心神，排除杂念，帮助快速入睡。',
    steps: [
      '仰卧舒适姿势，自然呼吸',
      '每次呼气时心中默数，从1数到10',
      '数到10后重新从1开始',
      '若中途走神，不要懊恼，从1重新开始',
      '保持专注但不过于用力',
      '通常数到几轮后自然入睡',
    ]),
  _SleepTip(title: '想象引导法', category: '入睡技巧', icon: Icons.image,
    content: '通过想象宁静的场景来放松身心，转移焦虑和杂念，是认知行为疗法推荐的助眠技巧。',
    steps: [
      '闭上双眼，做几次深呼吸放松',
      '想象一个让你感到安全和放松的场景',
      '可以是一片宁静的湖泊、温暖的沙滩',
      '尽可能调动感官——感受微风、听到水声',
      '让身体跟随想象逐渐放松',
      '沉浸在这个场景中直到入睡',
    ]),

  // === 睡前习惯 ===
  _SleepTip(title: '睡前泡脚', category: '睡前习惯', icon: Icons.bathtub,
    content: '中医认为"寒从脚起"，脚部有众多经络和穴位。温水泡脚可温通经络、引火下行、促进血液循环，有助于快速入睡。',
    steps: [
      '睡前30分钟准备泡脚',
      '水温40-45℃，以不烫为宜',
      '可加入艾草、姜片、花椒等中药',
      '水位漫过脚踝，浸泡15-20分钟',
      '泡至微微出汗即可，不可大汗',
      '擦干双脚后立即上床入睡',
    ]),
  _SleepTip(title: '穴位按摩助眠', category: '睡前习惯', icon: Icons.pan_tool,
    content: '睡前按摩特定穴位可安神助眠。《黄帝内经》记载诸多助眠穴位，坚持按摩可有效改善睡眠质量。',
    steps: [
      '按揉神门穴（手腕横纹尺侧端）3分钟',
      '按揉三阴交穴（内踝尖上3寸）3分钟',
      '按揉涌泉穴（足底前1/3处）5分钟',
      '搓揉双耳至发热',
      '按揉百会穴（头顶正中）2分钟',
      '每个穴位以有酸胀感为度',
    ]),
  _SleepTip(title: '睡前阅读', category: '睡前习惯', icon: Icons.menu_book,
    content: '睡前阅读纸质书有助于转移注意力、放松大脑。但应避免内容过于刺激或使用电子设备阅读，蓝光会抑制褪黑素分泌。',
    steps: [
      '睡前30-60分钟开始阅读',
      '选择纸质书籍，避免电子设备',
      '内容以轻松愉快的为主',
      '避免悬疑、恐怖类刺激性内容',
      '阅读时配合柔和的暖色灯光',
      '感到困意时放下书本入睡',
    ]),
  _SleepTip(title: '睡前饮食注意', category: '睡前习惯', icon: Icons.no_meals,
    content: '中医认为"胃不和则卧不安"。睡前饮食不当会导致消化负担过重，影响睡眠。合理饮食是改善睡眠的基础。',
    steps: [
      '睡前2-3小时停止进食正餐',
      '避免浓茶、咖啡等含咖啡因饮品',
      '避免辛辣、油腻、生冷食物',
      '如感饥饿可少量饮用温牛奶',
      '酸枣仁、百合、龙眼有助眠功效',
      '饮酒虽能助眠但会降低睡眠质量',
    ]),
  _SleepTip(title: '睡前远离手机', category: '睡前习惯', icon: Icons.phone_disabled,
    content: '手机蓝光会抑制褪黑素分泌，延迟入睡时间。社交信息和短视频还会刺激大脑兴奋，导致难以入眠。',
    steps: [
      '睡前1小时放下手机',
      '将手机放在卧室外或远离床头',
      '用阅读或冥想替代刷手机',
      '如需设闹钟可用传统闹钟',
      '避免在床上使用电子设备',
      '养成固定的睡前"断电"仪式',
    ]),

  // === 时辰养生 ===
  _SleepTip(title: '子时入睡（23:00-1:00）', category: '时辰养生', icon: Icons.dark_mode,
    content: '中医认为子时为胆经当令，是"阴中之阴"，此时入睡最养胆气。《黄帝内经》云："凡十一藏取决于胆也"。子时入睡有助于养肝利胆、修复身体。',
    steps: [
      '争取每晚22:30前上床准备',
      '23:00前进入睡眠状态',
      '子时是身体修复的黄金时段',
      '错过子时入睡，肝胆得不到充分休养',
      '长期子时不睡容易面色萎黄、口苦咽干',
      '逐步调整作息，养成早睡习惯',
    ]),
  _SleepTip(title: '午时小憩（11:00-13:00）', category: '时辰养生', icon: Icons.wb_sunny,
    content: '午时为心经当令，是阳气最旺盛的时候。适当午睡可养心安神、恢复精力，但不宜过久，以免影响夜间睡眠。',
    steps: [
      '午餐后休息15-30分钟即可',
      '午休时间不宜超过30分钟',
      '不要饭后立即躺下，先散步10分钟',
      '午睡以静卧或坐位闭目养神为主',
      '下午3点后不宜再午睡',
      '失眠者可缩短或取消午睡',
    ]),
  _SleepTip(title: '卯时起床（5:00-7:00）', category: '时辰养生', icon: Icons.alarm,
    content: '卯时为大肠经当令，此时起床有利于排毒。古人日出而作，顺应天时，定时起床有助于建立良好的生物钟。',
    steps: [
      '晨起时间尽量固定，包括周末',
      '起床后先喝一杯温水润肠通便',
      '晨起后做适量运动唤醒身体',
      '定时作息有助于形成稳定生物钟',
      '避免赖床，超过30分钟影响精神',
      '冬春季可适当晚起，但不晚于7点',
    ]),
  _SleepTip(title: '顺应四季睡眠', category: '时辰养生', icon: Icons.calendar_today,
    content: '《黄帝内经》提出四季睡眠原则："春三月……夜卧早起；夏三月……夜卧早起；秋三月……早卧早起；冬三月……早卧晚起"。',
    steps: [
      '春季：22:30入睡，6:30起床，顺肝气升发',
      '夏季：23:00入睡，6:00起床，养心养阳',
      '秋季：22:00入睡，6:00起床，收敛神气',
      '冬季：21:30入睡，7:00起床，养藏精气',
      '根据日出日落时间灵活调整',
      '保持每日固定的作息节奏',
    ]),

  // === 环境调整 ===
  _SleepTip(title: '卧室温度调节', category: '环境调整', icon: Icons.thermostat,
    content: '研究表明18-22℃是最佳睡眠温度。中医认为睡眠时阳气入内，体表偏凉，适当低温有助于阳气的收敛和潜藏。',
    steps: [
      '卧室温度控制在18-22℃',
      '夏季可用空调，但避免直吹身体',
      '冬季注意保暖但不过度加热',
      '被褥选择透气性好的棉质材料',
      '根据个人体质微调温度',
      '使用加湿器保持40-60%湿度',
    ]),
  _SleepTip(title: '光线管理', category: '环境调整', icon: Icons.light_mode,
    content: '《黄帝内经》云："阳气者，一日而主外，平旦人气生，日中而阳气隆，日西而阳气已虚"。光线是调节生物钟的关键因素。',
    steps: [
      '卧室使用遮光窗帘，保持暗环境',
      '睡前1小时调暗室内灯光',
      '使用暖色（2700-3000K）低亮度灯具',
      '避免蓝光（手机、电脑）的暴露',
      '起夜使用低亮度暖光地脚灯',
      '早晨起床后接受自然光照射',
    ]),
  _SleepTip(title: '床品与睡眠卫生', category: '环境调整', icon: Icons.bed,
    content: '良好的睡眠环境是优质睡眠的基础。选择合适的枕头、被褥和床品，定期清洁维护，营造舒适的睡眠空间。',
    steps: [
      '枕头高度以仰卧一拳、侧卧一拳半为宜',
      '被褥根据季节选择适当厚度',
      '床品定期清洗，保持清洁',
      '床垫每7-10年更换一次',
      '卧室保持整洁，避免杂物堆积',
      '卧室不放电视、电脑等电子设备',
    ]),
  _SleepTip(title: '白噪音与环境音', category: '环境调整', icon: Icons.volume_up,
    content: '适度的白噪音可以掩蔽突发噪音，帮助大脑放松。自然的声音如雨声、流水声具有天然的安神效果。',
    steps: [
      '可使用白噪音机或手机APP',
      '推荐雨声、流水声等自然音效',
      '音量控制在30-40分贝',
      '设置定时关闭，避免整夜播放',
      '尽量消除噪音源（关闭电器等）',
      '如果环境过于安静，可使用风扇的白噪音',
    ]),
];

/// 睡眠改善页面
class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  String _sleepQuality = 'normal';
  String? _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'value': '入睡技巧', 'label': '入睡技巧'},
    {'value': '睡前习惯', 'label': '睡前习惯'},
    {'value': '时辰养生', 'label': '时辰养生'},
    {'value': '环境调整', 'label': '环境调整'},
  ];

  List<_SleepTip> get _filteredTips {
    if (_selectedCategory == null) return _kSleepTips;
    return _kSleepTips.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('睡眠改善'),
        backgroundColor: Colors.indigo[50],
      ),
      body: Column(
        children: [
          // 睡眠质量评估
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('昨晚睡眠质量如何？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQualityButton('poor', '😫 较差'),
                    _buildQualityButton('normal', '😐 一般'),
                    _buildQualityButton('good', '😊 良好'),
                  ],
                ),
                const SizedBox(height: 12),
                // 分类筛选
                const Text('建议分类', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                      selectedColor: Colors.indigo.withValues(alpha: 0.2),
                    ),
                    ..._categories.map((c) {
                      final isSelected = _selectedCategory == c['value'];
                      return FilterChip(
                        label: Text(c['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = selected ? c['value'] : null);
                        },
                        selectedColor: Colors.indigo.withValues(alpha: 0.2),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // 建议列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredTips.length,
              itemBuilder: (context, index) {
                final tip = _filteredTips[index];
                return _buildTipCard(tip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityButton(String quality, String label) {
    final isSelected = _sleepQuality == quality;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _sleepQuality = quality);
        }
      },
    );
  }

  Widget _buildTipCard(_SleepTip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[100],
          child: Icon(tip.icon, color: Colors.indigo[700]),
        ),
        title: Text(tip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tip.content, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Chip(
          label: Text(tip.category, style: const TextStyle(fontSize: 10)),
          backgroundColor: Colors.indigo[50],
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onTap: () => _showTipDetail(tip),
      ),
    );
  }

  void _showTipDetail(_SleepTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Icon(tip.icon, color: Colors.indigo[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tip.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(tip.content, style: const TextStyle(fontSize: 15, height: 1.6)),
              const SizedBox(height: 20),
              const Text('具体步骤', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(tip.steps.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.indigo[100],
                      child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: Colors.indigo[800])),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tip.steps[i], style: const TextStyle(fontSize: 14, height: 1.4))),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
