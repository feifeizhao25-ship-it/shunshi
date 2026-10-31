import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';
import '../../../core/solar_term/solar_term_table.dart';

/// 养生馆 - 分类详情页
/// 根据 type 展示具体内容列表
class WellnessCategoryPage extends StatelessWidget {
  final String type;
  const WellnessCategoryPage({super.key, this.type = 'food_therapy'});

  static const _categoryMeta = {
    'constitution': _Meta(Icons.favorite_rounded, '体质调养', '了解九种体质，因人施养'),
    'food_therapy': _Meta(Icons.restaurant_menu, '节气食谱', '顺应节气，食时令'),
    'tea': _Meta(Icons.emoji_food_beverage, '养生茶饮', '以茶养心，润燥养生'),
    'acupressure': _Meta(Icons.accessibility_new, '经络穴位', '疏通经络，保健强身'),
    'exercise': _Meta(Icons.self_improvement, '传统功法', '动静结合，内外兼修'),
    'sleep': _Meta(Icons.headphones, '助眠音频', '睡前放松的音频引导'),
  };

  static const _items = {
    'constitution': [
      _Item('平和质', '阴阳气血调和，体态适中，面色润泽。性格随和开朗，适应力强。', '保持规律作息，均衡饮食即可。'),
      _Item('气虚质', '元气不足，易疲乏，声音低弱。容易感冒，病后恢复慢。', '宜食黄芪、党参、山药等补气之物。'),
      _Item('阳虚质', '阳气不足，手足不温，畏寒怕冷。面色柔白，喜热饮食。', '宜食羊肉、生姜、桂圆等温补之物。'),
      _Item('阴虚质', '阴液亏少，口燥咽干，手足心热。体型偏瘦，喜冷饮。', '宜食银耳、百合、枸杞等滋阴之物。'),
      _Item('痰湿质', '痰湿凝聚，体形肥胖，腹部肥满。面部油脂较多，多汗且黏。', '宜食薏仁、冬瓜、荷叶等化痰除湿之物。'),
      _Item('湿热质', '湿热内蕴，面垢油光，易生痤疮。口苦口干，身重困倦。', '宜食绿豆、薏仁、苦瓜等清热利湿之物。'),
      _Item('血瘀质', '血行不畅，肤色晦暗，易出现瘀斑。唇色暗紫，眼眶暗黑。', '宜食山楂、黑豆、醋等活血化瘀之物。'),
      _Item('气郁质', '气机郁滞，神情抑郁，忧虑脆弱。形体瘦者居多。', '宜食玫瑰花、陈皮、佛手等疏肝解郁之物。'),
      _Item('特禀质', '先天禀赋不足，过敏体质。对季节适应能力差，易引发宿疾。', '宜食清淡均衡之物，避免过敏原。'),
    ],
    'tea': [
      _Item('玫瑰花茶', '疏肝解郁，活血散瘀。适合情绪低落、胸闷者。', '取干玫瑰花5-8朵，沸水冲泡，可加蜂蜜调味。'),
      _Item('陈皮普洱', '理气健脾，化痰降脂。适合消化不良者。', '陈皮3g，普洱茶5g，沸水冲泡饮用。'),
      _Item('红枣桂圆茶', '补气养血，安神定志。适合气血两虚者。', '红枣5枚，桂圆肉10g，沸水冲泡10分钟。'),
      _Item('菊花枸杞茶', '清肝明目，滋补肝肾。适合用眼过度者。', '菊花5朵，枸杞10g，沸水冲泡。'),
      _Item('生姜红枣茶', '温中散寒，回阳通脉。适合阳虚畏寒者。', '生姜3片，红枣5枚，水煎煮15分钟。'),
      _Item('荷叶山楂茶', '消食化积，降脂减肥。适合痰湿体质者。', '干荷叶5g，山楂10g，沸水冲泡。'),
    ],
    'acupressure': [
      _Item('合谷穴', '位于手背虎口处。镇静止痛，通经活络。', '拇指按揉3-5分钟，力度适中。可缓解头痛、牙痛。'),
      _Item('足三里', '位于外膝眼下四横指处。调理脾胃，补中益气。', '每日轻轻按揉 5 分钟，放松小腿。'),
      _Item('三阴交', '位于内踝尖上四横指处。健脾益血，调肝补肾。', '拇指按揉3-5分钟，对妇科保健尤为有效。'),
      _Item('涌泉穴', '位于足底前部凹陷处。引火归元，滋阴益肾。', '睡前搓揉涌泉穴100次，可改善睡眠。'),
      _Item('太冲穴', '位于足背第一二趾间。疏肝理气，清肝泻火。', '按揉3-5分钟，适合情绪烦躁时使用。'),
      _Item('内关穴', '位于腕横纹上三横指处。宁心安神，和胃降逆。', '按揉3分钟，可缓解心悸、恶心。'),
    ],
    'exercise': [
      _Item('八段锦', '八个动作组成，简单易学。调理脏腑，强身健体。', '每日晨起练习15分钟，动作舒缓，呼吸自然。'),
      _Item('太极拳', '内外兼修，刚柔并济。平衡阴阳，调和气血。', '建议跟随专业老师学习，每日练习30分钟。'),
      _Item('五禽戏', '模仿虎、鹿、熊、猿、鸟五种动物。舒筋活络，强健体魄。', '每日练习20分钟，注意动作舒展自然。'),
      _Item('易筋经', '十二势导引术。强筋健骨，壮内培元。', '适合有一定基础者，动作配合呼吸。'),
      _Item('六字诀', '通过嘘、呵、呼、呬、吹、嘻六个字音。调理五脏六腑。', '每日清晨练习，每个字音6次，配合呼吸。'),
    ],
    'sleep': [
      _Item('雨声白噪音', '持续稳定的雨声，营造宁静氛围，帮助入睡。', '建议睡前30分钟播放，音量调低，定时关闭。'),
      _Item('古琴助眠', '古琴悠远的音色，安神定志，舒缓身心。', '选择节奏缓慢的曲目，如《平沙落雁》。'),
      _Item('自然冥想', '引导式冥想配合自然音效，放松身心。', '跟随语音引导，关注呼吸，逐步放松全身。'),
      _Item('颂钵音疗', '颂钵共鸣的泛音，深层放松神经系统。', '使用耳机效果更佳，可配合腹式呼吸。'),
      _Item('森林溪流', '溪水潺潺，鸟鸣悠扬，回归自然。', '适合午休或夜间使用，营造自然睡眠环境。'),
    ],
  };

  /// 节气食谱按当前节气所在的季节显示（不再全年显示春季食材）
  static List<_Item> _seasonalFood() {
    switch (_seasonOfTerm(currentSolarTermName())) {
      case 'spring':
        return const [
          _Item('青团', '清明前后的时令糕点，用艾草汁和糯米粉做皮，外软内甜。', '艾草汁拌入糯米粉，包入豆沙馅，蒸约 15 分钟。', image: 'assets/images/foods/qingtuan.webp'),
          _Item('艾草', '春季常见的野菜，也是端午的传统植物，可做艾草粑粑、艾草鸡蛋汤。', '食用前先焯水去苦味；对菊科植物过敏者不宜。', image: 'assets/images/foods/aicao.webp'),
          _Item('河虾', '春季河虾个头适中、肉质鲜嫩，富含蛋白质。', '清炒或做河虾豆腐汤；对海鲜过敏者避免。', image: 'assets/images/foods/hexia.webp'),
          _Item('螺蛳', '江南有「清明螺蛳赛肥鹅」的说法，春季的螺蛳肉质较肥。', '充分吐沙、煮熟透后再吃，每次不宜过量。', image: 'assets/images/foods/luosi.webp'),
          _Item('荠菜', '早春常见的野菜，可包饺子、做馄饨或煮汤。', '洗净焯水后拌馅；野菜请从可靠渠道购买，不要自行采摘不认识的植物。', image: 'assets/images/foods/jicai.webp'),
          _Item('香椿', '春季的时令嫩芽，常见做法是香椿炒蛋、凉拌香椿。', '食用前焯水，现采现吃，不宜久放；一次不宜吃太多。', image: 'assets/images/foods/xiangchun.webp'),
        ];
      case 'summer':
        return const [
          _Item('绿豆汤', '夏季常见的解暑饮品，煮好后放凉饮用，口味清淡。', '绿豆洗净，加水煮至开花，可加少量冰糖；脾胃虚寒者不宜多喝。', image: 'assets/images/foods/lvdou.webp'),
          _Item('冬瓜海带汤', '冬瓜水分多、热量低，与海带同煮，是夏天常见的清淡汤品。', '冬瓜去皮切块，与泡发的海带同煮约 20 分钟，少放盐。', image: 'assets/images/foods/donggua.webp'),
          _Item('苦瓜', '夏季常见的时令蔬菜，味苦，可清炒、凉拌或煮汤。', '切片后用盐略腌或焯水可减轻苦味；腹泻时不宜多吃。', image: 'assets/images/foods/kugua.webp'),
          _Item('莲藕', '夏季上市的时令食材，可凉拌、炖汤或清炒，口感脆甜。', '藕片焯水后凉拌；与排骨炖汤约 1 小时。', image: 'assets/images/foods/lianou.webp'),
          _Item('西瓜', '夏季解渴的水果，水分充足；不宜冰镇过度，一次不宜吃太多。', '常温或微凉食用即可；糖尿病患者请遵医嘱控制量。', image: 'assets/images/foods/xigua.webp'),
          _Item('薏米红豆粥', '夏季常见的粥品，口感软糯，常搭配红豆一起煮。', '薏米和红豆提前浸泡 2 小时，煮约 40 分钟。', image: 'assets/images/foods/yimi.webp'),
        ];
      case 'autumn':
        return const [
          _Item('银耳雪梨羹', '秋季干燥时常见的甜汤，口感润滑，做法简单。', '银耳泡发撕小朵，与雪梨块同煮约 40 分钟，可加少量冰糖。', image: 'assets/images/foods/yinger.webp'),
          _Item('百合', '秋季上市的鲜百合，可清炒、煮粥或做甜汤，口感清甜。', '鲜百合掰开洗净，与西芹清炒或加入粥中；注意不要煮得过烂。', image: 'assets/images/foods/baihe.webp'),
          _Item('莲子', '常用于煮粥、煲汤的传统食材，口感软糯。', '莲子提前泡软，去芯后与米同煮约 40 分钟；莲心味苦，可去除。', image: 'assets/images/foods/lianzi.webp'),
          _Item('山药', '秋冬常见的根茎蔬菜，可蒸、炒或炖汤，口感绵软。', '削皮时注意戴手套，避免手痒；蒸熟蘸少量糖或清炒。', image: 'assets/images/foods/shanyao.webp'),
          _Item('柿子', '霜降前后上市，民间有「霜降吃柿子」的习俗。', '要吃完全成熟的柿子；不要空腹吃，也不要与大量螃蟹同食。', image: 'assets/images/foods/shizi.webp'),
          _Item('板栗', '秋季的坚果，可煮、炒或炖鸡，口感粉糯。', '在壳上划口后再煮或烤；一次不宜吃太多，容易胀气。', image: 'assets/images/foods/banli.webp'),
        ];
      case 'winter':
        return const [
          _Item('白萝卜', '冬季常见的蔬菜，可炖汤、清炒或腌制，口感清甜。', '与排骨或羊肉同炖约 1 小时；切块后先焯水可减轻辛味。', image: 'assets/images/foods/luobo.webp'),
          _Item('羊肉汤', '北方不少地方有立冬、冬至前后吃羊肉的习惯。', '羊肉先焯水去腥，加姜片慢炖约 1.5 小时；高血压、上火者适量。', image: 'assets/images/foods/yangrou.webp'),
          _Item('烤红薯', '冬季常见的小吃，香甜软糯，含有膳食纤维。', '带皮烤约 40 分钟；不要吃烤焦的部分，一次不宜多吃。', image: 'assets/images/foods/hongshu.webp'),
          _Item('核桃', '常见的坚果，可直接吃或加入粥、点心，口感香脆。', '每天一小把即可，注意控制总量；对坚果过敏者避免。', image: 'assets/images/foods/hetao.webp'),
          _Item('黑芝麻糊', '冬季常见的热饮甜点，香味浓郁，口感细腻。', '熟黑芝麻与糯米粉加水煮成糊，少放糖。', image: 'assets/images/foods/zhima.webp'),
          _Item('腊八粥', '农历腊月初八的传统食俗，用多种谷物和干果煮成。', '米、豆、干果提前浸泡，小火慢煮约 1 小时。', image: 'assets/images/foods/laba.webp'),
        ];
    }
    return const [];
  }

  void _showDetail(BuildContext context, _Item item) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface(context),
      title: Text(item.name, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, color: AppColors.textPrimary(context))),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.desc, style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.6)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary(context).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.primary(context)),
            const SizedBox(width: 8),
            Expanded(child: Text(item.tip, style: TextStyle(fontSize: 13, color: AppColors.primary(context), height: 1.5))),
          ]),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('知道了', style: TextStyle(color: AppColors.primary(context))))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[type] ?? _categoryMeta['food_therapy']!;
    final items = type == 'food_therapy' ? _seasonalFood() : (_items[type] ?? const <_Item>[]);
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(meta.title, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => safePop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(meta.subtitle, style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: AppColors.textTertiary(context))),
          ),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _showDetail(context, item),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border(context))),
                    child: Row(children: [
                      item.image != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(item.image!, width: 44, height: 44, fit: BoxFit.cover))
                          : Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary(context).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                              child: Icon(meta.icon, size: 22, color: AppColors.primary(context))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                        const SizedBox(height: 4),
                        Text(item.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context), height: 1.4)),
                      ])),
                      Icon(Icons.chevron_right, color: AppColors.textDisabled(context), size: 20),
                    ]),
                  ),
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}

class _Meta {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Meta(this.icon, this.title, this.subtitle);
}

class _Item {
  final String name;
  final String desc;
  final String tip;
  final String? image;
  const _Item(this.name, this.desc, this.tip, {this.image});
}

String _seasonOfTerm(String? term) {
  const spring = ['立春', '雨水', '惊蛰', '春分', '清明', '谷雨'];
  const summer = ['立夏', '小满', '芒种', '夏至', '小暑', '大暑'];
  const autumn = ['立秋', '处暑', '白露', '秋分', '寒露', '霜降'];
  if (term != null) {
    if (spring.contains(term)) return 'spring';
    if (summer.contains(term)) return 'summer';
    if (autumn.contains(term)) return 'autumn';
    return 'winter';
  }
  final m = DateTime.now().month;
  if (m >= 3 && m <= 5) return 'spring';
  if (m >= 6 && m <= 8) return 'summer';
  if (m >= 9 && m <= 11) return 'autumn';
  return 'winter';
}
