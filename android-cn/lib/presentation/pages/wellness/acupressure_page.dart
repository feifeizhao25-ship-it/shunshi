import 'package:flutter/material.dart';

/// 穴位数据模型
class _AcupointItem {
  final String name;
  final String category;
  final String location;
  final String positioning;
  final String effect;
  final String method;
  final String duration;
  final String frequency;
  final String emoji;

  const _AcupointItem({
    required this.name,
    required this.category,
    required this.location,
    required this.positioning,
    required this.effect,
    required this.method,
    required this.duration,
    required this.frequency,
    this.emoji = '📍',
  });
}

/// 穴位保健常量数据
const List<_AcupointItem> _kAcupoints = [
  // === 头部 ===
  _AcupointItem(name: '百会穴', category: '头部', emoji: '🧠',
    location: '头顶正中线与两耳尖连线的交点',
    positioning: '正坐，从两耳尖直上头顶正中线，指尖可触及凹陷处',
    effect: '醒脑开窍、升阳举陷、安神定志，主治头痛眩晕、失眠健忘',
    method: '拇指或中指按压，力度由轻到重，以有酸胀感为度',
    duration: '3-5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '风池穴', category: '头部', emoji: '🌀',
    location: '后颈部，枕骨下，两条大筋外缘的凹陷中',
    positioning: '正坐低头，后脑勺下方可触及两块肌肉，其外侧凹陷处即是',
    effect: '疏风解表、平肝熄风、清利头目，主治感冒、颈椎病、偏头痛',
    method: '双手拇指同时按压，向上方用力，可配合旋转按揉',
    duration: '3-5分钟', frequency: '每日2-3次'),
  _AcupointItem(name: '太阳穴', category: '头部', emoji: '☀️',
    location: '眉梢与目外眦之间，向后约一横指的凹陷处',
    positioning: '手指从外眼角向后摸，约一指宽处可触及凹陷',
    effect: '清肝明目、疏风止痛，主治偏头痛、眼疲劳、牙痛',
    method: '双手食指或中指按揉，可做小幅旋转，顺逆各15圈',
    duration: '2-3分钟', frequency: '头痛发作时或每日2次'),
  _AcupointItem(name: '印堂穴', category: '头部', emoji: '👤',
    location: '两眉头连线的中点处',
    positioning: '正坐，两眉头之间正中可触及凹陷',
    effect: '清头明目、通鼻开窍，主治前额头痛、鼻塞、失眠',
    method: '拇指从下向上推按，或中指按揉，力度适中',
    duration: '2-3分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '四白穴', category: '头部', emoji: '👁️',
    location: '面部，瞳孔直下，眶下孔凹陷处',
    positioning: '正坐直视前方，瞳孔正下方约一指宽处',
    effect: '明目退翳、疏风清热，主治眼疲劳、面瘫、三叉神经痛',
    method: '食指按揉，力度轻柔，以有酸麻感为度',
    duration: '2-3分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '迎香穴', category: '头部', emoji: '👃',
    location: '鼻翼外缘中点旁，鼻唇沟中',
    positioning: '手指沿鼻翼外侧向下摸至法令纹处',
    effect: '散风清热、通利鼻窍，主治鼻炎、鼻塞、面部神经麻痹',
    method: '双手食指同时按揉，可配合深呼吸',
    duration: '2-3分钟', frequency: '每日2次'),

  // === 上肢 ===
  _AcupointItem(name: '合谷穴', category: '上肢', emoji: '✋',
    location: '手背，第1、2掌骨之间，第2掌骨桡侧的中点',
    positioning: '拇指与食指并拢，虎口处最高点即是',
    effect: '镇静止痛、通经活络、清热解表，主治头痛、牙痛、感冒',
    method: '拇指按压对侧合谷，由轻到重，以有酸胀感为度',
    duration: '2-3分钟', frequency: '每日2-3次'),
  _AcupointItem(name: '内关穴', category: '上肢', emoji: '🤲',
    location: '前臂掌侧，腕横纹上2寸，两筋之间',
    positioning: '手腕横纹向上量三横指宽，两根筋之间的中点',
    effect: '宁心安神、理气止痛，主治心悸、失眠、恶心呕吐',
    method: '拇指按压，做小幅旋转按揉，可配合深呼吸',
    duration: '3-5分钟', frequency: '每日2-3次'),
  _AcupointItem(name: '外关穴', category: '上肢', emoji: '💪',
    location: '前臂背侧，腕横纹上2寸，尺骨与桡骨之间',
    positioning: '手腕横纹向上量三横指，前臂背侧两骨之间',
    effect: '清热解表、通经活络，主治感冒发热、耳鸣、偏头痛',
    method: '拇指按压，配合旋转按揉',
    duration: '3-5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '曲池穴', category: '上肢', emoji: '🦾',
    location: '肘横纹外侧端，屈肘时肘横纹尽头处',
    positioning: '屈肘90度，肘横纹外侧端可触及凹陷',
    effect: '疏风清热、调和气血，主治高血压、过敏、手臂麻木',
    method: '拇指按压或用掌根按揉，力度适中',
    duration: '3-5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '神门穴', category: '上肢', emoji: '💫',
    location: '腕掌侧横纹尺侧端，尺侧腕屈肌腱桡侧凹陷处',
    positioning: '手腕横纹靠小指一侧，可触及凹陷',
    effect: '宁心安神、清心泻火，主治失眠、心悸、焦虑',
    method: '拇指按揉，睡前按摩效果最佳',
    duration: '3-5分钟', frequency: '每日1-2次，睡前必按'),

  // === 下肢 ===
  _AcupointItem(name: '足三里穴', category: '下肢', emoji: '🦵',
    location: '小腿外侧，犊鼻穴下3寸，胫骨前嵴外一横指',
    positioning: '膝盖骨下缘外侧凹陷（犊鼻）向下量四横指',
    effect: '补脾健胃、扶正培元、通经活络，有"长寿穴"之称',
    method: '拇指用力按压，可做旋转按揉，配合艾灸效果更佳',
    duration: '5-10分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '三阴交穴', category: '下肢', emoji: '🦶',
    location: '内踝尖上3寸，胫骨内侧缘后方',
    positioning: '内踝骨最高点向上量四横指，胫骨后缘',
    effect: '健脾益血、调肝补肾，主治月经不调、失眠、消化不良',
    method: '拇指按压，可做旋转按揉，力度由轻到重',
    duration: '3-5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '涌泉穴', category: '下肢', emoji: '🌊',
    location: '足底部，蜷足时足前部凹陷处，约足底前1/3',
    positioning: '蜷足，足底前1/3处的凹陷中',
    effect: '醒脑开窍、滋阴益肾、引火归元，主治失眠、高血压、头痛',
    method: '搓揉或按压，睡前泡脚后按摩效果最佳',
    duration: '5-10分钟', frequency: '每晚睡前1次'),
  _AcupointItem(name: '太冲穴', category: '下肢', emoji: '🌳',
    location: '足背，第1、2跖骨间隙的后方凹陷处',
    positioning: '足背大拇趾与二趾之间，向上推至两骨结合前的凹陷',
    effect: '平肝息风、清热利湿，主治头痛眩晕、烦躁易怒、高血压',
    method: '拇指按压，由轻到重，以有酸胀感为度',
    duration: '3-5分钟', frequency: '每日1-2次，生气时按可平怒'),
  _AcupointItem(name: '阳陵泉穴', category: '下肢', emoji: '⚡',
    location: '小腿外侧，腓骨小头前下方凹陷处',
    positioning: '膝盖外侧下方可触及一圆骨突（腓骨小头），其前下凹陷',
    effect: '疏肝利胆、强筋壮骨，主治膝关节炎、胆囊炎、胁痛',
    method: '拇指按压或用掌根按揉',
    duration: '3-5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '太溪穴', category: '下肢', emoji: '💧',
    location: '内踝尖与跟腱之间的凹陷处',
    positioning: '内踝骨最高点后方的凹陷中',
    effect: '滋补肾阴、益肾纳气，主治腰痛、耳鸣、失眠、月经不调',
    method: '拇指按揉，配合艾灸效果更佳',
    duration: '3-5分钟', frequency: '每日1-2次'),

  // === 背部 ===
  _AcupointItem(name: '命门穴', category: '背部', emoji: '🔥',
    location: '腰部后正中线上，第2腰椎棘突下',
    positioning: '正坐或俯卧，与肚脐正对的后腰处',
    effect: '温肾壮阳、固精缩尿、温脾止泻，主治腰痛、遗精、腹泻',
    method: '掌根擦热命门穴，或掌心捂住做旋转按揉',
    duration: '5-10分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '肾俞穴', category: '背部', emoji: '🫘',
    location: '腰部，第2腰椎棘突下旁开1.5寸',
    positioning: '命门穴左右各旁开约两指宽处',
    effect: '补肾纳气、壮腰强膝，主治腰痛、耳鸣、遗精、水肿',
    method: '双手握拳，用指关节按揉，或掌根擦热',
    duration: '5-10分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '肺俞穴', category: '背部', emoji: '🌬️',
    location: '背部，第3胸椎棘突下旁开1.5寸',
    positioning: '低头找到最高椎骨突起（大椎），向下数3个椎体旁开两指',
    effect: '宣肺止咳、疏风解表，主治咳嗽、哮喘、感冒',
    method: '他人协助按压，拇指按揉或掌根擦热',
    duration: '3-5分钟', frequency: '每日1次'),
  _AcupointItem(name: '肝俞穴', category: '背部', emoji: '🌿',
    location: '背部，第9胸椎棘突下旁开1.5寸',
    positioning: '肩胛骨下角平对第7胸椎，向下数2个椎体旁开两指',
    effect: '疏肝理气、明目退黄，主治目赤肿痛、胁痛、黄疸',
    method: '他人协助按压或借助按摩工具',
    duration: '3-5分钟', frequency: '每日1次'),
  _AcupointItem(name: '膏肓穴', category: '背部', emoji: '💫',
    location: '背部，第4胸椎棘突下旁开3寸',
    positioning: '两肩胛骨内侧缘之间的区域，约第4胸椎旁开四指',
    effect: '补肺益气、培补元气，有"百病皆可取膏肓"之说',
    method: '他人协助点按或艾灸，也可用拳背轻叩',
    duration: '5分钟', frequency: '每日1次'),

  // === 胸腹 ===
  _AcupointItem(name: '关元穴', category: '胸腹', emoji: '🧘',
    location: '下腹部前正中线上，脐下3寸',
    positioning: '肚脐正中向下量四横指宽处',
    effect: '培元固本、补益下焦，主治遗精、月经不调、腹泻、虚劳',
    method: '掌心按揉或掌根推按，配合艾灸效果更佳',
    duration: '5-10分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '气海穴', category: '胸腹', emoji: '💨',
    location: '下腹部前正中线上，脐下1.5寸',
    positioning: '肚脐正中向下量两横指宽处',
    effect: '补气固本、温阳益气，主治气虚乏力、腹胀、月经不调',
    method: '掌心叠按，顺时针旋转按揉36圈',
    duration: '5-10分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '中脘穴', category: '胸腹', emoji: '🍽️',
    location: '上腹部前正中线上，脐上4寸',
    positioning: '胸骨下端与肚脐连线的中点处',
    effect: '健脾和胃、补中安神，主治胃痛、腹胀、消化不良',
    method: '掌根按揉，顺时针方向，饭后1小时为宜',
    duration: '5-10分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '膻中穴', category: '胸腹', emoji: '❤️',
    location: '胸部前正中线上，两乳头连线的中点',
    positioning: '两乳头之间的正中线处',
    effect: '宽胸理气、活血通络，主治胸闷、心悸、乳腺增生',
    method: '掌根上下推擦或按揉，配合深呼吸效果更佳',
    duration: '3-5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '天枢穴', category: '胸腹', emoji: '🔄',
    location: '腹部，脐旁2寸',
    positioning: '肚脐左右各旁开约三横指宽处',
    effect: '理气消滞、调节肠胃，主治腹胀、便秘、腹泻、消化不良',
    method: '双手掌根同时按揉，顺时针方向',
    duration: '5分钟', frequency: '每日1-2次'),
  _AcupointItem(name: '神阙穴', category: '胸腹', emoji: '⭕',
    location: '肚脐正中',
    positioning: '肚脐中央凹陷处',
    effect: '温阳救逆、健脾和胃，主治腹痛、泄泻、虚脱',
    method: '掌心捂住肚脐做旋转按揉，可配合艾灸隔盐灸',
    duration: '5-10分钟', frequency: '每日1次，配合艾灸'),
];

/// 穴位保健页面
class AcupressurePage extends StatefulWidget {
  const AcupressurePage({super.key});

  @override
  State<AcupressurePage> createState() => _AcupressurePageState();
}

class _AcupressurePageState extends State<AcupressurePage> {
  String? _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'value': '头部', 'label': '头部', 'emoji': '🧠'},
    {'value': '上肢', 'label': '上肢', 'emoji': '✋'},
    {'value': '下肢', 'label': '下肢', 'emoji': '🦵'},
    {'value': '背部', 'label': '背部', 'emoji': '🔙'},
    {'value': '胸腹', 'label': '胸腹', 'emoji': '🫁'},
  ];

  List<_AcupointItem> get _filteredAcupoints {
    if (_selectedCategory == null) return _kAcupoints;
    return _kAcupoints.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('穴位保健'),
        backgroundColor: Colors.purple[50],
      ),
      body: Column(
        children: [
          // 部位筛选
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择部位', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                      selectedColor: Colors.purple.withValues(alpha: 0.2),
                    ),
                    ..._categories.map((c) {
                      final isSelected = _selectedCategory == c['value'];
                      return FilterChip(
                        label: Text('${c['emoji']} ${c['label']}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = selected ? c['value'] : null);
                        },
                        selectedColor: Colors.purple.withValues(alpha: 0.2),
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
              itemCount: _filteredAcupoints.length,
              itemBuilder: (context, index) {
                final point = _filteredAcupoints[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      child: Text(point.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${point.category} · ${point.location}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('定位', point.positioning),
                            const SizedBox(height: 8),
                            _buildInfoRow('功效', point.effect),
                            const SizedBox(height: 8),
                            _buildInfoRow('按压方法', point.method),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow('时长', point.duration),
                                ),
                                Expanded(
                                  child: _buildInfoRow('频率', point.frequency),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(child: Text(value, style: const TextStyle(height: 1.4))),
      ],
    );
  }
}
