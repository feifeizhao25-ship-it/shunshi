import 'package:flutter/material.dart';

/// 食疗推荐数据模型
class _FoodItem {
  final String name;
  final String category;
  final String season;
  final String constitution;
  final String ingredients;
  final String effect;
  final String recipe;
  final String emoji;

  const _FoodItem({
    required this.name,
    required this.category,
    required this.season,
    required this.constitution,
    required this.ingredients,
    required this.effect,
    required this.recipe,
    this.emoji = '🍲',
  });
}

/// 食疗推荐常量数据
const List<_FoodItem> _kFoods = [
  // === 春季 ===
  _FoodItem(name: '荠菜豆腐羹', category: '清肝', season: 'spring', constitution: '肝火旺',
    ingredients: '荠菜150g、嫩豆腐1块、鸡蛋1个',
    effect: '清肝明目、凉血止血、健脾利水',
    recipe: '1. 荠菜洗净切碎，豆腐切小丁\n2. 锅中加水烧开，放入豆腐\n3. 加荠菜煮2分钟，淋入蛋液\n4. 加盐调味，淋香油出锅',
    emoji: '🥬'),
  _FoodItem(name: '香椿拌豆腐', category: '疏肝', season: 'spring', constitution: '湿气重',
    ingredients: '香椿嫩芽100g、豆腐1块、香油、盐',
    effect: '清热利湿、解毒润肤、开胃爽口',
    recipe: '1. 香椿焯水后切碎\n2. 豆腐切丁焯水沥干\n3. 两者拌匀，加盐、香油调味即可',
    emoji: '🌿'),
  _FoodItem(name: '山药薏米粥', category: '健脾', season: 'spring', constitution: '湿气重',
    ingredients: '山药200g、薏米50g、粳米100g',
    effect: '健脾祛湿、补肺益气、固肾益精',
    recipe: '1. 薏米提前浸泡2小时\n2. 山药去皮切块\n3. 所有食材加水大火煮沸转小火煮40分钟',
    emoji: '🥣'),
  _FoodItem(name: '菊花枸杞猪肝汤', category: '养肝', season: 'spring', constitution: '肝火旺',
    ingredients: '猪肝150g、菊花10g、枸杞15g、生姜',
    effect: '养肝明目、补血滋阴、清热解毒',
    recipe: '1. 猪肝切片焯水去腥\n2. 菊花、枸杞洗净备用\n3. 锅中加水烧开，放入猪肝、姜片\n4. 煮10分钟加菊花、枸杞，煮2分钟调味',
    emoji: '🌸'),
  _FoodItem(name: '春笋炒肉丝', category: '清热', season: 'spring', constitution: '痰湿',
    ingredients: '春笋200g、猪肉丝100g、木耳、葱姜',
    effect: '清热化痰、消食通便、健脾益气',
    recipe: '1. 春笋切片焯水去涩\n2. 肉丝用料酒、淀粉腌制\n3. 热锅凉油炒肉丝变色\n4. 加春笋、木耳翻炒，调味出锅',
    emoji: '🎋'),
  _FoodItem(name: '红枣山药糕', category: '健脾', season: 'spring', constitution: '气血虚',
    ingredients: '山药300g、红枣10颗、糯米粉100g',
    effect: '补中益气、养血安神、健脾养胃',
    recipe: '1. 山药蒸熟去皮捣泥\n2. 红枣去核切碎\n3. 山药泥加糯米粉、红枣揉团\n4. 模具成型，上锅蒸15分钟',
    emoji: '🥮'),
  _FoodItem(name: '菠菜猪肝汤', category: '养血', season: 'spring', constitution: '气血虚',
    ingredients: '菠菜200g、猪肝100g、生姜、枸杞',
    effect: '养血润燥、滋阴平肝、明目益睛',
    recipe: '1. 猪肝切片焯水，菠菜焯水切段\n2. 锅中加水烧开，放姜片\n3. 下猪肝煮5分钟，加菠菜\n4. 加枸杞、盐调味出锅',
    emoji: '🥬'),

  // === 夏季 ===
  _FoodItem(name: '百合莲子粥', category: '安神', season: 'summer', constitution: '心火旺',
    ingredients: '百合30g、莲子30g、粳米100g',
    effect: '清心安神、润肺止咳、养心益肾',
    recipe: '1. 莲子提前浸泡去芯\n2. 百合洗净，粳米淘净\n3. 加水大火煮沸转小火煮40分钟\n4. 加少许冰糖调味',
    emoji: '🪷'),
  _FoodItem(name: '绿豆冬瓜汤', category: '清热', season: 'summer', constitution: '湿热',
    ingredients: '绿豆50g、冬瓜300g、生姜、盐',
    effect: '清热解毒、消暑利湿、利尿消肿',
    recipe: '1. 绿豆提前浸泡1小时\n2. 冬瓜去皮切块\n3. 绿豆煮至开花，加冬瓜煮软\n4. 加盐调味即可',
    emoji: '🥒'),
  _FoodItem(name: '苦瓜炒蛋', category: '消暑', season: 'summer', constitution: '湿热',
    ingredients: '苦瓜1根、鸡蛋3个、蒜末',
    effect: '清热解毒、消暑止渴、明目解毒',
    recipe: '1. 苦瓜去瓤切片，盐腌去苦水\n2. 鸡蛋打散炒熟盛出\n3. 热锅炒蒜末、苦瓜至断生\n4. 倒入鸡蛋翻炒调味',
    emoji: '🥒'),
  _FoodItem(name: '酸梅汤', category: '生津', season: 'summer', constitution: '阴虚',
    ingredients: '乌梅30g、山楂20g、甘草5g、冰糖',
    effect: '生津止渴、消食和中、敛肺涩肠',
    recipe: '1. 乌梅、山楂、甘草洗净\n2. 加水1500ml大火煮沸\n3. 转小火煮30分钟\n4. 加冰糖调味，放凉饮用',
    emoji: '🧃'),
  _FoodItem(name: '丝瓜虾仁汤', category: '清热', season: 'summer', constitution: '阴虚',
    ingredients: '丝瓜2根、鲜虾仁100g、姜片',
    effect: '清热化痰、凉血解毒、通络生津',
    recipe: '1. 丝瓜去皮切滚刀块\n2. 虾仁用料酒腌制去腥\n3. 热锅爆香姜片，加丝瓜翻炒\n4. 加水煮开，放虾仁至变色调味',
    emoji: '🦐'),
  _FoodItem(name: '荷叶茯苓粥', category: '祛湿', season: 'summer', constitution: '湿气重',
    ingredients: '干荷叶15g、茯苓20g、粳米100g',
    effect: '清热解暑、健脾祛湿、宁心安神',
    recipe: '1. 荷叶、茯苓煎汁去渣\n2. 药汁中加入粳米\n3. 大火煮沸转小火煮至粥稠\n4. 可加少许冰糖调味',
    emoji: '🍃'),
  _FoodItem(name: '番茄鸡蛋面', category: '开胃', season: 'summer', constitution: '气虚',
    ingredients: '番茄2个、鸡蛋2个、面条、葱花',
    effect: '生津止渴、健胃消食、养阴润燥',
    recipe: '1. 番茄切块，鸡蛋打散\n2. 热锅炒鸡蛋盛出\n3. 炒番茄出汁，加适量水烧开\n4. 下面条煮熟，加鸡蛋调味',
    emoji: '🍝'),

  // === 秋季 ===
  _FoodItem(name: '银耳莲子羹', category: '润肺', season: 'autumn', constitution: '阴虚',
    ingredients: '银耳1朵、莲子30g、红枣5颗、冰糖',
    effect: '润肺止咳、养心安神、滋阴润燥',
    recipe: '1. 银耳泡发撕小朵\n2. 莲子去芯，红枣洗净\n3. 加水大火烧开转小火炖2小时\n4. 至银耳出胶，加冰糖',
    emoji: '🥣'),
  _FoodItem(name: '雪梨百合汤', category: '润燥', season: 'autumn', constitution: '阴虚',
    ingredients: '雪梨2个、鲜百合50g、冰糖、枸杞',
    effect: '滋阴润肺、化痰止咳、生津养胃',
    recipe: '1. 雪梨去皮去核切块\n2. 百合洗净，枸杞泡软\n3. 加水炖煮30分钟\n4. 加冰糖、枸杞再煮5分钟',
    emoji: '🍐'),
  _FoodItem(name: '沙参玉竹老鸭汤', category: '滋阴', season: 'autumn', constitution: '阴虚',
    ingredients: '老鸭半只、沙参20g、玉竹20g、生姜',
    effect: '滋阴润肺、养胃生津、补虚益气',
    recipe: '1. 老鸭焯水去血沫\n2. 沙参、玉竹洗净\n3. 全部材料入锅，加足水\n4. 大火烧开转小火炖2小时',
    emoji: '🦆'),
  _FoodItem(name: '杏仁秋梨膏', category: '润肺', season: 'autumn', constitution: '气血虚',
    ingredients: '秋梨5个、杏仁15g、冰糖100g、蜂蜜',
    effect: '润肺止咳、生津利咽、清热化痰',
    recipe: '1. 秋梨榨汁过滤\n2. 杏仁研碎加水煮取汁\n3. 梨汁加杏仁汁、冰糖熬至浓稠\n4. 凉后加蜂蜜，每次取一勺冲水',
    emoji: '🍯'),
  _FoodItem(name: '芝麻核桃粥', category: '补肾', season: 'autumn', constitution: '阳虚',
    ingredients: '黑芝麻30g、核桃仁30g、粳米100g',
    effect: '补肾益精、润肠通便、乌发养颜',
    recipe: '1. 黑芝麻炒香研碎\n2. 核桃仁掰小块\n3. 粳米加水煮至八成熟\n4. 加入芝麻、核桃继续煮至粥稠',
    emoji: '🌰'),
  _FoodItem(name: '莲藕排骨汤', category: '养阴', season: 'autumn', constitution: '阴虚',
    ingredients: '莲藕1节、排骨300g、生姜、红枣',
    effect: '清热滋阴、养血润燥、健脾开胃',
    recipe: '1. 排骨焯水，莲藕去皮切块\n2. 加姜片、红枣大火烧开\n3. 转小火炖1.5小时\n4. 加盐调味，撒葱花',
    emoji: '🍲'),

  // === 冬季 ===
  _FoodItem(name: '当归羊肉汤', category: '温阳', season: 'winter', constitution: '阳虚',
    ingredients: '羊肉500g、当归15g、生姜30g、红枣',
    effect: '温中散寒、补血活血、调经止痛',
    recipe: '1. 羊肉切块焯水去腥\n2. 当归、生姜、红枣洗净\n3. 全部入锅加水大火烧开\n4. 转小火炖2小时至肉烂',
    emoji: '🍖'),
  _FoodItem(name: '生姜红糖水', category: '驱寒', season: 'winter', constitution: '体寒',
    ingredients: '生姜30g、红糖20g、红枣5颗',
    effect: '温中散寒、补血活血、暖胃止痛',
    recipe: '1. 生姜切片，红枣去核\n2. 加水500ml煮沸\n3. 小火煮10分钟\n4. 加红糖搅拌至融化',
    emoji: '🫖'),
  _FoodItem(name: '黄芪当归汤', category: '补气', season: 'winter', constitution: '气血虚',
    ingredients: '黄芪30g、当归10g、鸡肉500g',
    effect: '补气养血、调理面色、增强免疫',
    recipe: '1. 鸡肉焯水切块\n2. 黄芪、当归洗净\n3. 全部材料入锅加水\n4. 大火烧开转小火炖1.5小时',
    emoji: '🍗'),
  _FoodItem(name: '黑豆核桃猪腰汤', category: '补肾', season: 'winter', constitution: '阳虚',
    ingredients: '黑豆50g、核桃30g、猪腰1对、生姜',
    effect: '补肾强腰、固精益气、温阳散寒',
    recipe: '1. 猪腰去筋膜切片焯水\n2. 黑豆提前浸泡\n3. 全部材料入锅加水\n4. 大火烧开转小火炖2小时',
    emoji: '🫘'),
  _FoodItem(name: '桂圆红枣粥', category: '养血', season: 'winter', constitution: '气血虚',
    ingredients: '桂圆肉20g、红枣10颗、糯米100g',
    effect: '补益心脾、养血安神、益气固表',
    recipe: '1. 糯米洗净浸泡30分钟\n2. 桂圆去壳，红枣去核\n3. 加水大火煮沸转小火\n4. 煮40分钟至粥稠',
    emoji: '🫘'),
  _FoodItem(name: '山药枸杞乌鸡汤', category: '补虚', season: 'winter', constitution: '气血虚',
    ingredients: '乌鸡半只、山药200g、枸杞15g、红枣',
    effect: '滋阴补肾、益气补血、养颜美容',
    recipe: '1. 乌鸡焯水去血沫\n2. 山药去皮切块\n3. 全部材料入锅加足水\n4. 大火烧开转小火炖2小时',
    emoji: '🍲'),
  _FoodItem(name: '核桃芝麻糊', category: '补肾', season: 'winter', constitution: '阳虚',
    ingredients: '核桃仁50g、黑芝麻30g、糯米粉20g、冰糖',
    effect: '补肾乌发、润肠通便、益智健脑',
    recipe: '1. 核桃、芝麻炒香研碎\n2. 糯米粉加冷水调糊\n3. 锅中加水煮开，倒入糯米糊\n4. 搅拌加芝麻核桃粉、冰糖',
    emoji: '🌰'),

  // === 四季通用 ===
  _FoodItem(name: '四物鸡汤', category: '补血', season: 'all', constitution: '气血虚',
    ingredients: '当归10g、川芎8g、白芍10g、熟地15g、鸡肉',
    effect: '补血调经、活血化瘀、养颜美容',
    recipe: '1. 四物药材洗净浸泡\n2. 鸡肉焯水切块\n3. 全部材料入锅加水\n4. 大火烧开转小火炖1.5小时',
    emoji: '🍲'),
  _FoodItem(name: '红豆薏米粥', category: '祛湿', season: 'all', constitution: '湿气重',
    ingredients: '红豆50g、薏米50g、粳米50g',
    effect: '健脾祛湿、利水消肿、清热排脓',
    recipe: '1. 红豆、薏米提前浸泡4小时\n2. 粳米洗净\n3. 加水大火煮沸转小火\n4. 煮40分钟至粥稠软烂',
    emoji: '🫘'),
  _FoodItem(name: '小米红枣粥', category: '健脾', season: 'all', constitution: '气虚',
    ingredients: '小米100g、红枣8颗、枸杞10g',
    effect: '健脾养胃、补益气血、安神助眠',
    recipe: '1. 小米淘净，红枣去核\n2. 加水大火煮沸转小火\n3. 煮30分钟至粥粘稠\n4. 加枸杞再煮5分钟',
    emoji: '🥣'),
  _FoodItem(name: '山药排骨汤', category: '补脾', season: 'all', constitution: '气虚',
    ingredients: '山药300g、排骨400g、生姜、枸杞',
    effect: '健脾益胃、补中益气、滋阴润燥',
    recipe: '1. 排骨焯水，山药去皮切块\n2. 加姜片、料酒大火烧开\n3. 转小火炖1小时\n4. 加山药继续炖30分钟调味',
    emoji: '🍖'),
  _FoodItem(name: '八宝粥', category: '补益', season: 'all', constitution: '气血虚',
    ingredients: '红豆、花生、莲子、桂圆、红枣、糯米、薏米、冰糖',
    effect: '补益气血、健脾养胃、安神助眠',
    recipe: '1. 豆类提前浸泡4小时\n2. 所有材料入锅\n3. 加水大火煮沸转小火\n4. 煮1小时至软烂，加冰糖',
    emoji: '🥣'),
  _FoodItem(name: '茯苓薏仁饼', category: '健脾', season: 'all', constitution: '湿气重',
    ingredients: '茯苓粉50g、薏米粉50g、面粉100g、蜂蜜',
    effect: '健脾渗湿、宁心安神、消食导滞',
    recipe: '1. 三种粉混合均匀\n2. 加适量水和蜂蜜揉成面团\n3. 擀成薄饼，平底锅小火烙熟\n4. 可当早餐或加餐食用',
    emoji: '🫓'),
];

/// 食疗推荐页面
class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  String? _selectedSeason;
  String? _selectedConstitution;

  static const List<Map<String, String>> _seasonFilters = [
    {'value': 'spring', 'label': '春'},
    {'value': 'summer', 'label': '夏'},
    {'value': 'autumn', 'label': '秋'},
    {'value': 'winter', 'label': '冬'},
    {'value': 'all', 'label': '四季'},
  ];

  static const List<String> _constitutionFilters = [
    '湿气重', '肝火旺', '体寒', '气血虚', '心火旺', '阴虚', '痰湿', '湿热', '气虚', '阳虚',
  ];

  List<_FoodItem> get _filteredFoods {
    return _kFoods.where((food) {
      if (_selectedSeason != null && food.season != _selectedSeason) return false;
      if (_selectedConstitution != null && food.constitution != _selectedConstitution) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食疗推荐'),
        backgroundColor: Colors.red[50],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择季节', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _seasonFilters.map((f) {
                    final v = f['value']!;
                    final l = f['label']!;
                    final colors = {
                      'spring': Colors.green,
                      'summer': Colors.red,
                      'autumn': Colors.orange,
                      'winter': Colors.blue,
                      'all': Colors.grey,
                    };
                    return _buildFilterChip(v, l, colors[v]!);
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('我的体质', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _constitutionFilters.map((c) => _buildConstitutionChip(c)).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredFoods.isEmpty
                ? const Center(child: Text('暂无匹配的食疗推荐', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = _filteredFoods[index];
                      return _FoodCard(food: food);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedSeason == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSeason = selected ? value : null);
      },
      selectedColor: color.withValues(alpha: 0.3),
    );
  }

  Widget _buildConstitutionChip(String value) {
    final isSelected = _selectedConstitution == value;
    return FilterChip(
      label: Text(value, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedConstitution = selected ? value : null);
      },
    );
  }
}

class _FoodCard extends StatelessWidget {
  final _FoodItem food;

  const _FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[100],
          child: Text(food.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${food.category} · ${food.effect}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('食材', food.ingredients),
                const SizedBox(height: 8),
                _buildRow('功效', food.effect),
                const SizedBox(height: 12),
                const Text('做法:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(food.recipe, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/chat'),
                    icon: const Icon(Icons.chat),
                    label: const Text('咨询具体做法'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
