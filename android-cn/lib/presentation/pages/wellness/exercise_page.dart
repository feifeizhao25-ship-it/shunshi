import 'package:flutter/material.dart';

/// 运动功法数据模型
class _ExerciseItem {
  final String name;
  final String category;
  final String emoji;
  final String dynasty;
  final String duration;
  final String difficulty;
  final String crowd;
  final String benefits;
  final String description;
  final List<String> steps;

  const _ExerciseItem({
    required this.name,
    required this.category,
    required this.emoji,
    required this.dynasty,
    required this.duration,
    required this.difficulty,
    required this.crowd,
    required this.benefits,
    required this.description,
    required this.steps,
  });
}

/// 运动功法常量数据
const List<_ExerciseItem> _kExercises = [
  // === 传统功法 ===
  _ExerciseItem(name: '八段锦', category: '传统功法', emoji: '🧘‍♂️',
    dynasty: '宋代', duration: '15分钟', difficulty: '简单',
    crowd: '适合所有人群，尤其适合中老年人和久坐办公者',
    benefits: '调理气血、疏通经络、强身健体',
    description: '传统养生功法，分为八段动作，柔和缓慢，适合各年龄段。每日坚持可调和脏腑、强筋壮骨。',
    steps: [
      '双手托天理三焦 — 双手交叉上托，拉伸脊柱',
      '左右开弓似射雕 — 马步扩胸，增强肺功能',
      '调理脾胃须单举 — 左右交替上举，调理脾胃',
      '五劳七伤往后瞧 — 头部左右转动，缓解疲劳',
      '摇头摆尾去心火 — 转腰摆臀，清心火',
      '双手攀足固肾腰 — 弯腰触足，强腰固肾',
      '攥拳怒目增气力 — 握拳瞪目，增强肝气',
      '背后七颠百病消 — 踮脚振动，通畅气血',
    ]),
  _ExerciseItem(name: '五禽戏', category: '传统功法', emoji: '🐯',
    dynasty: '东汉', duration: '20分钟', difficulty: '中等',
    crowd: '适合有一定运动基础的中青年，体质虚弱者可简化动作',
    benefits: '增强体质、预防疾病、延年益寿',
    description: '华佗创编，模仿虎、鹿、熊、猿、鸟五种动物的动作，动静结合，外练筋骨内练脏腑。',
    steps: [
      '虎戏 — 模仿虎扑之势，增强肝胆功能',
      '鹿戏 — 鹿抵鹿奔，舒展腰背，补肾强腰',
      '熊戏 — 模仿熊行，调理脾胃，增强消化',
      '猿戏 — 灵巧模仿猿猴，养心安神，灵活肢体',
      '鸟戏 — 模仿鸟翔，扩展胸腔，增强心肺功能',
    ]),
  _ExerciseItem(name: '太极拳', category: '传统功法', emoji: '☯️',
    dynasty: '明代', duration: '30分钟', difficulty: '中等',
    crowd: '适合各年龄段，中老年人尤宜，关节不适者可先学简化版',
    benefits: '修身养性、平衡阴阳、缓解压力',
    description: '以柔克刚、以静制动，传统内家拳法。讲究心静体松、意气相随，是养生运动的首选。',
    steps: [
      '起势 — 双脚分开，双手缓缓上举',
      '左右野马分鬃 — 弓步分手，舒展胸臂',
      '白鹤亮翅 — 虚步亮掌，平衡重心',
      '左右搂膝拗步 — 弓步推掌，协调上下',
      '手挥琵琶 — 虚步合手，蓄势待发',
      '倒卷肱 — 后退推掌，锻炼协调',
      '云手 — 横向移动，松腰转胯',
      '收势 — 气沉丹田，缓缓收回',
    ]),
  _ExerciseItem(name: '站桩功', category: '传统功法', emoji: '🧍',
    dynasty: '传统', duration: '10-30分钟', difficulty: '简单',
    crowd: '适合所有人群，尤其适合体质虚弱需要调养者',
    benefits: '培补元气、增强体质、静心养神',
    description: '静功基础功法，看似不动实为内动。通过保持特定姿势调息养神，是气功的入门功法。',
    steps: [
      '双脚平行与肩同宽，重心居中',
      '膝盖微屈不超过脚尖，松腰敛臀',
      '含胸拔背，沉肩坠肘，虚腋',
      '双手抱球于丹田前，十指相对',
      '舌抵上腭，目微闭或平视前方',
      '自然腹式呼吸，心无杂念',
    ]),
  _ExerciseItem(name: '易筋经', category: '传统功法', emoji: '💪',
    dynasty: '传统', duration: '20分钟', difficulty: '中等',
    crowd: '适合青壮年，关节活动自如者',
    benefits: '强筋壮骨、疏通经络、内壮外强',
    description: '少林传统功法，通过十二式动作拉伸筋脉、强壮骨骼，有"易骨易筋易髓"之说。',
    steps: [
      '韦驮献杵 — 双手合十，端正身形',
      '摘星换斗 — 单手上举，拉伸侧腰',
      '出爪亮翅 — 扩胸展臂，增强肺活量',
      '倒拽九牛尾 — 弓步后拽，强健腰背',
      '九鬼拔马刀 — 扭转脊柱，灵活颈椎',
      '三盘落地 — 屈膝下蹲，强壮下肢',
    ]),

  // === 日常运动 ===
  _ExerciseItem(name: '快走', category: '日常运动', emoji: '🚶‍♂️',
    dynasty: '现代', duration: '30-60分钟', difficulty: '简单',
    crowd: '几乎所有人群，尤其适合中老年人、体重管理人群',
    benefits: '增强心肺、促进代谢、控制体重',
    description: '最简便有效的有氧运动。步速约每分钟100-120步，微微出汗即可，不宜过度。',
    steps: [
      '选择平坦路段，穿舒适运动鞋',
      '起步热身5分钟，逐渐加快速度',
      '保持挺胸抬头，双臂自然摆动',
      '步幅适中，脚跟先着地过渡到全脚掌',
      '运动后拉伸5分钟放松肌肉',
    ]),
  _ExerciseItem(name: '太极慢跑', category: '日常运动', emoji: '🏃‍♂️',
    dynasty: '现代', duration: '20-40分钟', difficulty: '简单',
    crowd: '适合有基本运动能力的成年人，关节不适者慎用',
    benefits: '强心健肺、活血通络、舒缓压力',
    description: '以慢速慢跑配合自然呼吸，节奏舒缓不追求速度。是中医推荐的养心运动。',
    steps: [
      '热身5分钟，活动关节',
      '慢跑速度以能正常交谈为准',
      '注意呼吸节奏，鼻吸口呼',
      '前脚掌着地，膝盖保持弹性',
      '收尾慢走5分钟，做拉伸放松',
    ]),
  _ExerciseItem(name: '游泳', category: '日常运动', emoji: '🏊‍♂️',
    dynasty: '现代', duration: '30-45分钟', difficulty: '中等',
    crowd: '适合大部分人群，皮肤病患者及经期女性不宜',
    benefits: '全身运动、增强心肺、保护关节',
    description: '水中运动对关节压力最小，同时能锻炼全身肌肉。中医认为游泳可通调水道、疏通经络。',
    steps: [
      '下水前做好热身，避免抽筋',
      '选择蛙泳或仰泳等舒展泳姿',
      '保持匀速，不要过度追求速度',
      '每次30-45分钟为宜',
      '出水后及时擦干保暖，喝温水',
    ]),
  _ExerciseItem(name: '骑车', category: '日常运动', emoji: '🚴‍♂️',
    dynasty: '现代', duration: '30-60分钟', difficulty: '简单',
    crowd: '适合成年人，腰椎间盘突出者慎用',
    benefits: '增强下肢力量、锻炼心肺、环保出行',
    description: '户外骑行既能锻炼身体又能亲近自然。注意调整座椅高度，避免过度弯腰。',
    steps: [
      '调整座椅高度，腿伸直时微弯',
      '起步慢速骑行5分钟热身',
      '保持匀速，心率在中等强度',
      '注意交通安全，佩戴头盔',
      '骑行后拉伸大腿和小腿',
    ]),

  // === 办公运动 ===
  _ExerciseItem(name: '颈椎操', category: '办公运动', emoji: '🦒',
    dynasty: '现代', duration: '5分钟', difficulty: '简单',
    crowd: '久坐办公族、颈椎不适者',
    benefits: '缓解颈椎疲劳、预防颈椎病、改善肩颈酸痛',
    description: '针对久坐导致的颈椎问题设计的一套简单操，每小时做一次可有效预防颈椎病。',
    steps: [
      '低头仰头 — 缓慢低头至下巴贴胸，再仰头看天，各5次',
      '左右转头 — 头部缓慢左右转动，各5次',
      '左右侧屈 — 耳朵靠向肩部，各5次',
      '环绕运动 — 头部做小幅360度环绕，顺逆各5圈',
      '双手抱头 — 头向后仰，双手前推对抗，保持5秒，重复5次',
    ]),
  _ExerciseItem(name: '肩背拉伸', category: '办公运动', emoji: '💆‍♂️',
    dynasty: '现代', duration: '5分钟', difficulty: '简单',
    crowd: '伏案工作者、肩背酸痛者',
    benefits: '缓解肩背僵硬、改善含胸驼背、放松肩颈',
    description: '简单有效的肩背放松动作，可在工位上随时进行，缓解长期伏案带来的肌肉紧张。',
    steps: [
      '耸肩缩脖 — 双肩上耸至耳部，保持3秒后放下，重复10次',
      '扩胸运动 — 双臂后展扩胸，保持5秒，重复10次',
      '肩部环绕 — 双肩前后大环绕，各10圈',
      '猫牛式伸展 — 坐位拱背再挺胸，配合呼吸，重复10次',
      '对侧拉伸 — 一手搭另一肩，对侧手轻拉肘部，各保持15秒',
    ]),
  _ExerciseItem(name: '眼部按摩操', category: '办公运动', emoji: '👁️',
    dynasty: '中医传统', duration: '3分钟', difficulty: '简单',
    crowd: '长时间用眼者、眼睛干涩疲劳者',
    benefits: '缓解眼疲劳、明目护眼、预防近视',
    description: '中医眼部保健功法，通过穴位按摩和眼肌运动来缓解用眼过度。',
    steps: [
      '搓热双手捂眼 — 掌心温热后轻敷双眼30秒',
      '按揉睛明穴 — 内眼角凹陷处按揉30秒',
      '按揉四白穴 — 瞳孔正下方眶下孔处按揉30秒',
      '按揉太阳穴 — 外眼角后方按揉30秒',
      '远眺放松 — 看窗外远处绿色植物1分钟',
    ]),
  _ExerciseItem(name: '久坐拉伸操', category: '办公运动', emoji: '🤸‍♂️',
    dynasty: '现代', duration: '5分钟', difficulty: '简单',
    crowd: '久坐办公族、下肢水肿者',
    benefits: '促进下肢血液循环、缓解腰背酸痛、放松身心',
    description: '针对久坐导致的气血不畅设计，简单易行，每工作1小时练习一次。',
    steps: [
      '坐姿抬腿 — 坐位交替抬腿伸直，各10次',
      '踝关节环绕 — 坐位双脚踝部环绕转动，各20圈',
      '坐位体前屈 — 坐位伸直双腿前屈触脚，保持15秒',
      '站起踮脚 — 起立踮脚尖再放下，重复20次',
      '深蹲起立 — 缓慢深蹲5次，锻炼腿部力量',
    ]),

  // === 季节运动 ===
  _ExerciseItem(name: '春季踏青', category: '季节运动', emoji: '🌸',
    dynasty: '传统', duration: '60分钟', difficulty: '简单',
    crowd: '所有人群，过敏体质者注意花粉防护',
    benefits: '舒肝理气、畅达情志、强壮筋骨',
    description: '《黄帝内经》云："春三月，此谓发陈"。春季宜到户外踏青，顺应肝气生发之性。',
    steps: [
      '选择空气清新、花草较多的公园或郊外',
      '穿舒适运动服和运动鞋',
      '步行为主，配合深呼吸感受自然',
      '途中可配合做八段锦等功法',
      '避免出汗过多，以微汗为度',
    ]),
  _ExerciseItem(name: '夏日游泳消暑', category: '季节运动', emoji: '🏖️',
    dynasty: '现代', duration: '30-45分钟', difficulty: '中等',
    crowd: '适合大部分人群，经期和心脏病患者慎用',
    benefits: '消暑降温、强心健肺、疏通经络',
    description: '《黄帝内经》云："夏三月，此谓蕃秀"。夏季宜选清凉运动，避免烈日下剧烈运动。',
    steps: [
      '选择清晨或傍晚时段',
      '游泳前做好充分热身',
      '水温不宜过低，避免寒气入体',
      '游泳后及时擦干保暖',
      '运动后不要立即喝冷饮',
    ]),
  _ExerciseItem(name: '秋日登高', category: '季节运动', emoji: '🍂',
    dynasty: '传统', duration: '60-120分钟', difficulty: '中等',
    crowd: '适合有一定运动基础的成年人',
    benefits: '清肺润燥、舒展心胸、强健筋骨',
    description: '《黄帝内经》云："秋三月，此谓容平"。秋季宜登高远眺，收敛神气，使肺气清肃。',
    steps: [
      '选择坡度适中的登山路线',
      '穿着适当，注意温差变化',
      '登高时配合深呼吸，吸入清气',
      '速度适中，不可急促',
      '下山时保护膝盖，侧身下行',
    ]),
  _ExerciseItem(name: '冬日暖阳慢走', category: '季节运动', emoji: '❄️',
    dynasty: '传统', duration: '30-45分钟', difficulty: '简单',
    crowd: '所有人群，心脑疾病患者注意保暖',
    benefits: '温阳散寒、强身健体、调和气血',
    description: '《黄帝内经》云："冬三月，此谓闭藏"。冬季宜在暖阳下适度运动，以微汗为度，不可大汗淋漓。',
    steps: [
      '选择上午10点至下午3点间阳光时段',
      '穿足够保暖的运动装备，注意头颈保暖',
      '步行速度不宜过快，微微出汗即止',
      '运动后及时添衣保暖',
      '运动后喝温热饮品，不宜饮冷',
    ]),
];

/// 运动功法页面
class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  String? _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'value': '传统功法', 'label': '传统功法', 'emoji': '🧘‍♂️'},
    {'value': '日常运动', 'label': '日常运动', 'emoji': '🏃‍♂️'},
    {'value': '办公运动', 'label': '办公运动', 'emoji': '💼'},
    {'value': '季节运动', 'label': '季节运动', 'emoji': '🌱'},
  ];

  List<_ExerciseItem> get _filteredExercises {
    if (_selectedCategory == null) return _kExercises;
    return _kExercises.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动功法'),
        backgroundColor: Colors.orange[50],
      ),
      body: Column(
        children: [
          // 分类筛选
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('运动类型', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                      selectedColor: Colors.orange.withValues(alpha: 0.2),
                    ),
                    ..._categories.map((c) {
                      final isSelected = _selectedCategory == c['value'];
                      return FilterChip(
                        label: Text('${c['emoji']} ${c['label']}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = selected ? c['value'] : null);
                        },
                        selectedColor: Colors.orange.withValues(alpha: 0.2),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return _ExerciseCard(
                  exercise: exercise,
                  onTap: () => _showExerciseDetail(exercise),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetail(_ExerciseItem exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(exercise.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildTag(exercise.dynasty, Colors.grey[200]!),
                  _buildTag(exercise.duration, Colors.blue[100]!),
                  _buildTag(exercise.difficulty, Colors.green[100]!),
                  _buildTag(exercise.category, Colors.orange[100]!),
                ],
              ),
              const SizedBox(height: 16),
              Text(exercise.description, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Text('适合人群：${exercise.crowd}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 16),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise.benefits,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('动作分解', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(
                exercise.steps.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.orange[100],
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.steps[i],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/chat');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始 AI 指导练习'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _ExerciseItem exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(exercise.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.category} · ${exercise.duration} · ${exercise.difficulty}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.benefits,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
