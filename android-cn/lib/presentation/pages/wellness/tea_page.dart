import 'package:flutter/material.dart';

/// 茶饮数据模型
class _TeaItem {
  final String name;
  final String season;
  final String timeOfDay;
  final String colorKey;
  final String ingredients;
  final String temperature;
  final String effect;
  final String brew;
  final String crowd;
  final String tips;
  final String emoji;

  const _TeaItem({
    required this.name,
    required this.season,
    required this.timeOfDay,
    required this.colorKey,
    required this.ingredients,
    required this.temperature,
    required this.effect,
    required this.brew,
    required this.crowd,
    required this.tips,
    this.emoji = '🍵',
  });
}

/// 茶饮推荐常量数据
const List<_TeaItem> _kTeas = [
  // === 春季 ===
  _TeaItem(name: '枸杞菊花茶', season: 'spring', timeOfDay: 'morning', colorKey: 'yellow',
    ingredients: '枸杞10粒、菊花3-5朵、冰糖少许',
    temperature: '温热', crowd: '用眼过度者、肝火偏旺者',
    effect: '清肝明目、滋阴润燥、缓解眼疲劳',
    brew: '菊花、枸杞用85℃热水冲泡，加盖闷5分钟，加冰糖调味',
    tips: '菊花性寒，脾胃虚寒者少饮，可加红枣平衡寒性',
    emoji: '🌼'),
  _TeaItem(name: '玫瑰花茶', season: 'spring', timeOfDay: 'afternoon', colorKey: 'pink',
    ingredients: '玫瑰花5-8朵、蜂蜜适量',
    temperature: '温热', crowd: '女性、情绪郁结者、面色暗沉者',
    effect: '疏肝解郁、活血化瘀、美容养颜',
    brew: '玫瑰花用80℃热水冲泡，加盖闷5分钟，温后加蜂蜜',
    tips: '经期女性、孕妇慎用；玫瑰花不宜与茶叶同泡',
    emoji: '🌹'),
  _TeaItem(name: '决明子茶', season: 'spring', timeOfDay: 'afternoon', colorKey: 'brown',
    ingredients: '炒决明子10g、菊花3朵',
    temperature: '温热', crowd: '目赤肿痛、便秘者、高血压人群',
    effect: '清肝明目、润肠通便、降血压',
    brew: '决明子炒熟后用90℃热水冲泡，可反复冲泡3次',
    tips: '脾胃虚寒者少饮，孕妇忌服；生决明子需炒熟后再泡',
    emoji: '🫘'),
  _TeaItem(name: '薄荷茶', season: 'spring', timeOfDay: 'afternoon', colorKey: 'green',
    ingredients: '新鲜薄荷叶5-8片、蜂蜜适量',
    temperature: '温凉', crowd: '头痛鼻塞者、消化不良者',
    effect: '疏风散热、清利头目、疏肝解郁',
    brew: '薄荷叶洗净放入杯中，用80℃热水冲泡，加盖闷3分钟',
    tips: '薄荷有发散作用，体虚多汗者不宜多饮',
    emoji: '🍃'),
  _TeaItem(name: '陈皮茶', season: 'spring', timeOfDay: 'afternoon', colorKey: 'orange',
    ingredients: '陈皮5g、生姜3片',
    temperature: '温热', crowd: '消化不良者、痰湿体质者',
    effect: '理气健脾、燥湿化痰、和胃止呕',
    brew: '陈皮、生姜用沸水冲泡，加盖闷10分钟',
    tips: '阴虚燥咳者慎用；陈皮越陈效果越好',
    emoji: '🍊'),

  // === 夏季 ===
  _TeaItem(name: '酸梅汤', season: 'summer', timeOfDay: 'afternoon', colorKey: 'brown',
    ingredients: '乌梅30g、山楂20g、甘草5g、冰糖适量、桂花少许',
    temperature: '凉饮', crowd: '暑热口渴者、食欲不振者',
    effect: '生津止渴、消食和中、敛肺涩肠',
    brew: '乌梅山楂甘草加水1500ml煮沸，小火煮30分钟，加冰糖，撒桂花',
    tips: '胃酸过多者少饮；可放凉后饮用更佳',
    emoji: '🧃'),
  _TeaItem(name: '金银花茶', season: 'summer', timeOfDay: 'afternoon', colorKey: 'yellow',
    ingredients: '金银花5g、菊花3朵、蜂蜜适量',
    temperature: '凉茶', crowd: '风热感冒者、咽喉肿痛者',
    effect: '清热解毒、疏散风热、消炎抗菌',
    brew: '金银花、菊花用90℃热水冲泡，加盖闷5分钟，温后加蜂蜜',
    tips: '体质虚寒者不宜多饮，经期女性慎用',
    emoji: '🌻'),
  _TeaItem(name: '荷叶茶', season: 'summer', timeOfDay: 'afternoon', colorKey: 'green',
    ingredients: '干荷叶10g、山楂5g、决明子5g',
    temperature: '凉饮', crowd: '体重管理者、血脂偏高者、夏季消暑',
    effect: '清热解暑、降脂减肥、利尿消肿',
    brew: '荷叶、山楂、决明子用沸水冲泡，闷10分钟后饮用',
    tips: '脾胃虚寒者不宜，孕妇忌服',
    emoji: '🍃'),
  _TeaItem(name: '竹叶茶', season: 'summer', timeOfDay: 'afternoon', colorKey: 'green',
    ingredients: '淡竹叶10g、甘草3g',
    temperature: '凉茶', crowd: '心烦口渴者、小便不利者',
    effect: '清心除烦、利尿通淋、生津止渴',
    brew: '淡竹叶、甘草用沸水冲泡，闷10分钟',
    tips: '性寒，脾胃虚寒者不宜长期饮用',
    emoji: '🎋'),
  _TeaItem(name: '薄荷菊花茶', season: 'summer', timeOfDay: 'morning', colorKey: 'green',
    ingredients: '薄荷叶5片、菊花3朵、冰糖适量',
    temperature: '凉饮', crowd: '暑热头痛者、目赤咽痛者',
    effect: '清暑解热、疏风散热、提神醒脑',
    brew: '菊花先用热水冲泡3分钟，再加薄荷叶，闷2分钟',
    tips: '不宜长期饮用，症状缓解后即可停用',
    emoji: '🌿'),

  // === 秋季 ===
  _TeaItem(name: '银耳莲子羹', season: 'autumn', timeOfDay: 'afternoon', colorKey: 'white',
    ingredients: '银耳半朵、莲子15g、红枣3颗、冰糖适量',
    temperature: '温热', crowd: '秋燥干咳者、皮肤干燥者',
    effect: '滋阴润肺、养胃生津、美容养颜',
    brew: '银耳泡发撕小朵，加莲子红枣小火炖2小时至银耳出胶',
    tips: '糖尿病患者不加冰糖；银耳需充分泡发',
    emoji: '🥣'),
  _TeaItem(name: '百合茶', season: 'autumn', timeOfDay: 'evening', colorKey: 'white',
    ingredients: '干百合10g、蜂蜜适量',
    temperature: '温热', crowd: '秋季干咳者、心烦失眠者',
    effect: '润肺止咳、清心安神、养阴清热',
    brew: '百合用沸水冲泡，加盖闷15分钟，温后加蜂蜜',
    tips: '风寒咳嗽者不宜；新鲜百合效果更佳',
    emoji: '🪷'),
  _TeaItem(name: '梨膏茶', season: 'autumn', timeOfDay: 'afternoon', colorKey: 'yellow',
    ingredients: '秋梨膏2勺、温开水',
    temperature: '温热', crowd: '秋季咽喉干痒者、干咳少痰者',
    effect: '润肺止咳、生津利咽、清热化痰',
    brew: '取2勺秋梨膏，加200ml温开水搅拌均匀即可',
    tips: '脾胃虚寒者加几片生姜一起饮用',
    emoji: '🍐'),
  _TeaItem(name: '沙参麦冬茶', season: 'autumn', timeOfDay: 'afternoon', colorKey: 'brown',
    ingredients: '北沙参10g、麦冬10g、冰糖适量',
    temperature: '温热', crowd: '秋燥口干咽燥者、干咳无痰者',
    effect: '养阴清肺、益胃生津、润燥止咳',
    brew: '沙参、麦冬加水煎煮20分钟，去渣取汁加冰糖',
    tips: '感冒初期、痰多色白者不宜使用',
    emoji: '🌾'),

  // === 冬季 ===
  _TeaItem(name: '生姜红糖茶', season: 'winter', timeOfDay: 'morning', colorKey: 'red',
    ingredients: '生姜片15g、红糖20g、红枣3颗',
    temperature: '热饮', crowd: '体寒怕冷者、风寒感冒初期',
    effect: '温中散寒、补血活血、暖胃止痛',
    brew: '生姜切片，加500ml水煮沸后小火煮10分钟，加红糖搅拌',
    tips: '阴虚火旺、体质偏热者不宜；上午饮用为佳',
    emoji: '🫖'),
  _TeaItem(name: '桂圆红枣茶', season: 'winter', timeOfDay: 'morning', colorKey: 'red',
    ingredients: '桂圆肉10g、红枣5颗、枸杞10g',
    temperature: '温热', crowd: '气血不足者、面色苍白者、失眠者',
    effect: '补血安神、益气养心、温阳散寒',
    brew: '红枣去核，所有材料加水500ml煮沸，小火煮15分钟',
    tips: '糖尿病患者慎用；上火时不宜饮用',
    emoji: '🫘'),
  _TeaItem(name: '陈皮普洱', season: 'winter', timeOfDay: 'afternoon', colorKey: 'brown',
    ingredients: '陈皮5g、普洱茶8g',
    temperature: '热饮', crowd: '消化不良者、血脂偏高者、冬季暖身',
    effect: '理气健脾、消食化积、降脂暖胃',
    brew: '陈皮、普洱茶用沸水冲泡，第一泡洗茶，第二泡开始饮用',
    tips: '空腹不宜饮用；普洱茶性温，适合冬季',
    emoji: '🫖'),
  _TeaItem(name: '当归黄芪茶', season: 'winter', timeOfDay: 'morning', colorKey: 'brown',
    ingredients: '当归5g、黄芪10g、红枣3颗',
    temperature: '热饮', crowd: '气血两虚者、容易疲劳者、手脚冰凉者',
    effect: '补气养血、温经散寒、增强免疫',
    brew: '药材加水500ml，大火煮沸转小火煎煮20分钟',
    tips: '感冒发热时停用；月经量多者经期停用',
    emoji: '🌿'),
  _TeaItem(name: '核桃芝麻茶', season: 'winter', timeOfDay: 'morning', colorKey: 'brown',
    ingredients: '核桃仁15g、黑芝麻10g、冰糖适量',
    temperature: '温热', crowd: '肾虚腰痛者、须发早白者、冬季进补',
    effect: '补肾益精、乌发养颜、润肠通便',
    brew: '核桃、芝麻炒香研碎，用沸水冲泡，加冰糖调味',
    tips: '腹泻者不宜；坚持饮用效果更佳',
    emoji: '🌰'),

  // === 四季通用 ===
  _TeaItem(name: '酸枣仁茶', season: 'all', timeOfDay: 'evening', colorKey: 'brown',
    ingredients: '酸枣仁15g、百合5g、茯苓10g',
    temperature: '温热', crowd: '失眠多梦者、心悸不安者',
    effect: '安神助眠、养心益肝、敛汗生津',
    brew: '酸枣仁炒熟后捣碎，与百合茯苓一起加水煎煮20分钟',
    tips: '睡前1-2小时饮用效果最佳；白天不宜饮用以免嗜睡',
    emoji: '💤'),
  _TeaItem(name: '山楂茶', season: 'all', timeOfDay: 'afternoon', colorKey: 'red',
    ingredients: '干山楂片10g、冰糖适量',
    temperature: '温热', crowd: '食积腹胀者、血脂偏高者',
    effect: '消食化积、活血化瘀、降脂降压',
    brew: '山楂片用沸水冲泡，加盖闷10分钟，加冰糖调味',
    tips: '胃酸过多者不宜空腹饮用',
    emoji: '🍒'),
  _TeaItem(name: '红枣枸杞茶', season: 'all', timeOfDay: 'morning', colorKey: 'red',
    ingredients: '红枣5颗、枸杞10g',
    temperature: '温热', crowd: '气血不足者、视力疲劳者',
    effect: '补气养血、养肝明目、增强免疫',
    brew: '红枣去核，与枸杞一起用沸水冲泡，闷10分钟',
    tips: '感冒发热时不宜；上火时减量',
    emoji: '❤️'),
  _TeaItem(name: '甘草茶', season: 'all', timeOfDay: 'afternoon', colorKey: 'brown',
    ingredients: '生甘草5g、蜂蜜适量',
    temperature: '温热', crowd: '咽喉不适者、脾胃虚弱者',
    effect: '补脾益气、润肺止咳、缓急止痛',
    brew: '甘草用沸水冲泡，闷10分钟，加蜂蜜调味',
    tips: '长期大量使用可能导致水肿；高血压者慎用',
    emoji: '🍯'),
];

/// 茶饮推荐页面
class TeaPage extends StatefulWidget {
  const TeaPage({super.key});

  @override
  State<TeaPage> createState() => _TeaPageState();
}

class _TeaPageState extends State<TeaPage> {
  String _selectedTimeOfDay = 'all';
  String? _selectedSeason;

  static const List<Map<String, String>> _seasonFilters = [
    {'value': 'spring', 'label': '🌸 春'},
    {'value': 'summer', 'label': '☀️ 夏'},
    {'value': 'autumn', 'label': '🍂 秋'},
    {'value': 'winter', 'label': '❄️ 冬'},
    {'value': 'all', 'label': '🌿 四季'},
  ];

  List<_TeaItem> get _filteredTeas {
    return _kTeas.where((tea) {
      if (_selectedTimeOfDay != 'all' && tea.timeOfDay != _selectedTimeOfDay) return false;
      if (_selectedSeason != null && tea.season != _selectedSeason) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('茶饮推荐'),
        backgroundColor: Colors.green[50],
      ),
      body: Column(
        children: [
          // 筛选区
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('饮用时间', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTimeChip('all', '全天', Icons.wb_sunny),
                    _buildTimeChip('morning', '早上', Icons.wb_twilight),
                    _buildTimeChip('afternoon', '下午', Icons.wb_cloudy),
                    _buildTimeChip('evening', '晚上', Icons.nightlight),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('选择季节', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _seasonFilters.map((s) {
                    final v = s['value']!;
                    final l = s['label']!;
                    return FilterChip(
                      label: Text(l),
                      selected: _selectedSeason == v,
                      onSelected: (selected) {
                        setState(() => _selectedSeason = selected ? v : null);
                      },
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: _filteredTeas.isEmpty
                ? const Center(child: Text('暂无匹配的茶饮推荐', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTeas.length,
                    itemBuilder: (context, index) {
                      final tea = _filteredTeas[index];
                      return _TeaCard(tea: tea);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String value, String label, IconData icon) {
    final isSelected = _selectedTimeOfDay == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.green),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTimeOfDay = value);
      },
      selectedColor: Colors.green,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }
}

class _TeaCard extends StatelessWidget {
  final _TeaItem tea;

  const _TeaCard({required this.tea});

  Color get _teaColor {
    switch (tea.colorKey) {
      case 'yellow':
        return Colors.amber;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'red':
        return Colors.red[300]!;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'white':
        return Colors.grey[400]!;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _teaColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(tea.emoji, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tea.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.thermostat, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(tea.temperature, style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(_getTimeLabel(tea.timeOfDay), style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(tea.crowd, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tea.effect, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('材料：${tea.ingredients}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 6),
            Text('冲泡：${tea.brew}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tea.tips, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeLabel(String timeOfDay) {
    const labels = {
      'morning': '早上',
      'afternoon': '下午',
      'evening': '晚上',
      'all': '全天',
    };
    return labels[timeOfDay] ?? timeOfDay;
  }
}
