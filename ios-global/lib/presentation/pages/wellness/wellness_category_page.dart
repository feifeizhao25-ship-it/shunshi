import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

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
    'food_therapy': [
      _Item('菊花茶', '清热明目，疏风散热。适合春季饮用，缓解眼部疲劳。', '取杭白菊5-6朵，沸水冲泡5分钟即可饮用。', image: 'assets/images/foods/juhua.png'),
      _Item('青团', '清明时令糕点，艾草与糯米融合，清香软糯。', '艾草汁拌入糯米粉，包入豆沙馅，蒸制15分钟。', image: 'assets/images/foods/qingtuan.png'),
      _Item('艾草', '温经止血，散寒除湿。春季采摘鲜嫩艾草食用。', '可制作艾草粑粑、艾草鸡蛋汤等。', image: 'assets/images/foods/aicao.png'),
      _Item('河虾', '高蛋白低脂肪，补肾壮阳。春季河虾最为肥美。', '清炒河虾或河虾豆腐汤，鲜美营养。', image: 'assets/images/foods/hexia.png'),
      _Item('螺蛳', '清明螺蛳赛肥鹅。清热利水，明目退黄。', '葱姜爆炒或酱爆螺蛳，鲜美可口。', image: 'assets/images/foods/luosi.png'),
      _Item('红枣桂圆粥', '补血养心，安神助眠。适合气血不足、失眠者。', '红枣10枚，桂圆肉15g，大米100g，同煮成粥。'),
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
      _Item('足三里', '位于外膝眼下四横指处。调理脾胃，补中益气。', '每日按揉5分钟，可增强免疫力，改善消化。'),
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

  void _showDetail(BuildContext context, _Item item) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: Text(item.name, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.desc, style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.tips_and_updates_outlined, size: 18, color: ShunShiColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(item.tip, style: TextStyle(fontSize: 13, color: ShunShiColors.primary, height: 1.5))),
          ]),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了', style: TextStyle(color: ShunShiColors.primary)))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[type] ?? _categoryMeta['food_therapy']!;
    final items = _items[type] ?? [];
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        title: Text(meta.title, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        backgroundColor: ShunShiColors.background,
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
            child: Text(meta.subtitle, style: const TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.textTertiary)),
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
                    decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: ShunShiColors.border)),
                    child: Row(children: [
                      item.image != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(item.image!, width: 44, height: 44, fit: BoxFit.cover))
                          : Container(width: 44, height: 44, decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                              child: Icon(meta.icon, size: 22, color: ShunShiColors.primary)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(item.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.4)),
                      ])),
                      Icon(Icons.chevron_right, color: ShunShiColors.textDisabled, size: 20),
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
