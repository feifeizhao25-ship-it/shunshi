import '../../widgets/illustrated_widgets.dart';
import 'wellness_content.dart';
import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/network/api_client.dart';
import '../../../core/solar_term/solar_term_table.dart';
import '../../../design_system/theme.dart';

/// 养生馆 - 分类详情页
/// 根据 type 展示具体内容列表，支持 API 获取 + 个性化 + fallback
class WellnessCategoryPage extends StatefulWidget {
  final String type;
  const WellnessCategoryPage({super.key, this.type = 'food_therapy'});

  @override
  State<WellnessCategoryPage> createState() => _WellnessCategoryPageState();
}

class _WellnessCategoryPageState extends State<WellnessCategoryPage> {
  final _api = ApiClient();
  List<_Item> _items = [];
  bool _isLoading = true;
  String? _constitutionType;

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    _constitutionType = prefs.getString('constitution_type');
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, String>{
        'category': _apiCategoryFor(widget.type),
        'limit': '10',
      };
      if (_constitutionType != null) {
        queryParams['constitution'] = _constitutionType!;
      }

      final res = await _api.get('/api/v1/contents', queryParameters: queryParams);
      final data = res.data;
      final List<dynamic> raw;
      if (data is Map && data['items'] != null) {
        raw = data['items'] as List;
      } else if (data is Map && data['data'] is Map && data['data']['items'] != null) {
        raw = data['data']['items'] as List;
      } else if (data is List) {
        raw = data;
      } else {
        raw = [];
      }

      if (raw.isNotEmpty) {
        setState(() {
          _items = raw.map<_Item>((e) {
            final m = e as Map<String, dynamic>;
            return _Item(
              name: m['title'] as String? ?? '',
              desc: m['description'] as String? ?? '',
              tip: m['benefits'] is List
                  ? (m['benefits'] as List).join('、')
                  : (m['benefits'] as String? ?? ''),
              image: (m['image'] as String?) ?? wellnessImageForName(m['title'] as String? ?? ''),
              id: m['id']?.toString(),
              extra: m,
            );
          }).toList().cast<_Item>();
          _isLoading = false;
        });
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }
  }

  void _useFallback() {
    setState(() {
      _items = widget.type == 'food_therapy' ? _seasonalFoodFallback() : (_fallbackItems[widget.type] ?? []);
      _isLoading = false;
    });
  }

  static String _apiCategoryFor(String type) {
    switch (type) {
      case 'food_therapy': return 'food';
      case 'exercise': return 'exercise';
      case 'tea': return 'tea';
      case 'acupressure': return 'acupoint';
      case 'sleep': return 'sleep';
      case 'constitution': return 'constitution';
      default: return type;
    }
  }

  void _onItemTap(_Item item) {
    // Navigate to the appropriate detail page based on category type
    switch (widget.type) {
      case 'food_therapy':
        if (item.id != null) {
          context.push('/content/${item.id}');
        } else {
          context.push('/diet-recommend', extra: {
            'constitutionType': _constitutionType,
          });
        }
        break;
      case 'exercise':
        if (item.id != null) {
          context.push('/content/${item.id}');
        } else {
          context.push('/exercise-detail');
        }
        break;
      case 'tea':
        _showTeaDetail(item);
        break;
      case 'acupressure':
        if (item.id != null) {
          context.push('/meridian-detail', extra: {'meridianId': item.id});
        } else {
          context.push('/meridian-detail', extra: {'meridianId': ''});
        }
        break;
      case 'sleep':
        context.push('/sleep-report');
        break;
      case 'constitution':
        context.push('/constitution');
        break;
      default:
        if (item.id != null) {
          context.push('/content/${item.id}');
        }
    }
  }

  void _showTeaDetail(_Item item) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: ShunShiColors.surface,
      title: Text(item.name, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.desc, style: const TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ShunShiColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_cafe, size: 18, color: ShunShiColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(item.tip, style: TextStyle(fontSize: 13, color: ShunShiColors.primary, height: 1.5))),
            ],
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了', style: TextStyle(color: ShunShiColors.primary)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final meta = _categoryMeta[widget.type] ?? _categoryMeta['food_therapy']!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(meta.title, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => safePop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: CategoryCover(
              asset: wellnessCoverAsset(widget.type),
              icon: meta.icon,
              title: meta.title,
              subtitle: meta.subtitle,
            ),
          ),
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: ShunShiColors.primary))
              : _items.isEmpty
                  ? const Center(child: Text('暂无内容', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: IllustratedCard(
                              asset: item.image ?? wellnessImageForName(item.name),
                              fallbackIcon: meta.icon,
                              title: item.name,
                              desc: item.desc,
                              tip: item.tip,
                              onTap: () => _onItemTap(item),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPlaceholder(_Meta meta) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: ShunShiColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(meta.icon, size: 22, color: ShunShiColors.primary),
    );
  }
}

// ── Data models ──

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
  final String? id;
  final Map<String, dynamic>? extra;
  const _Item({
    required this.name,
    required this.desc,
    this.tip = '',
    this.image,
    this.id,
    this.extra,
  });
}

// ── Static metadata ──

const _categoryMeta = {
  'constitution': _Meta(Icons.favorite_rounded, '体质调养', '传统九种体质分类，仅供了解、不作诊断'),
  'food_therapy': _Meta(Icons.restaurant_menu, '节气食谱', '顺应节气，食时令'),
  'tea': _Meta(Icons.emoji_food_beverage, '养生茶饮', '一杯清茶，慢享时令'),
  'acupressure': _Meta(Icons.accessibility_new, '经络穴位', '认识常用穴位，传统按揉保健'),
  'exercise': _Meta(Icons.self_improvement, '传统功法', '动静结合，内外兼修'),
  'sleep': _Meta(Icons.headphones, '助眠音频', '睡前放松的音频引导'),
};

// ── Fallback static data (used when API fails) ──

/// 离线内容库（来自 wellness_content.dart，全部配有插画，不含疗效声明）
final _fallbackItems = <String, List<_Item>>{
  for (final e in kWellnessEntries.entries)
    e.key: [for (final x in e.value) _Item(name: x.name, desc: x.desc, tip: x.tip, image: x.image)],
};

/// 节气食谱离线备用内容，按当前节气所在的季节显示
List<_Item> _seasonalFoodFallback() {
  switch (_seasonOfTerm(currentSolarTermName())) {
    case 'spring':
      return const [
        _Item(name: '青团', desc: '清明前后的时令糕点，用艾草汁和糯米粉做皮，外软内甜。', tip: '艾草汁拌入糯米粉，包入豆沙馅，蒸约 15 分钟。', image: 'assets/images/foods/qingtuan.webp'),
        _Item(name: '艾草', desc: '春季常见的野菜，也是端午的传统植物，可做艾草粑粑、艾草鸡蛋汤。', tip: '食用前先焯水去苦味；对菊科植物过敏者不宜。', image: 'assets/images/foods/aicao.webp'),
        _Item(name: '河虾', desc: '春季河虾个头适中、肉质鲜嫩，富含蛋白质。', tip: '清炒或做河虾豆腐汤；对海鲜过敏者避免。', image: 'assets/images/foods/hexia.webp'),
        _Item(name: '螺蛳', desc: '江南有「清明螺蛳赛肥鹅」的说法，春季的螺蛳肉质较肥。', tip: '充分吐沙、煮熟透后再吃，每次不宜过量。', image: 'assets/images/foods/luosi.webp'),
        _Item(name: '荠菜', desc: '早春常见的野菜，可包饺子、做馄饨或煮汤。', tip: '洗净焯水后拌馅；野菜请从可靠渠道购买，不要自行采摘不认识的植物。', image: 'assets/images/foods/jicai.webp'),
        _Item(name: '香椿', desc: '春季的时令嫩芽，常见做法是香椿炒蛋、凉拌香椿。', tip: '食用前焯水，现采现吃，不宜久放；一次不宜吃太多。', image: 'assets/images/foods/xiangchun.webp'),
      ];
    case 'summer':
      return const [
        _Item(name: '绿豆汤', desc: '夏季常见的解暑饮品，煮好后放凉饮用，口味清淡。', tip: '绿豆洗净，加水煮至开花，可加少量冰糖；脾胃虚寒者不宜多喝。', image: 'assets/images/foods/lvdou.webp'),
        _Item(name: '冬瓜海带汤', desc: '冬瓜水分多、热量低，与海带同煮，是夏天常见的清淡汤品。', tip: '冬瓜去皮切块，与泡发的海带同煮约 20 分钟，少放盐。', image: 'assets/images/foods/donggua.webp'),
        _Item(name: '苦瓜', desc: '夏季常见的时令蔬菜，味苦，可清炒、凉拌或煮汤。', tip: '切片后用盐略腌或焯水可减轻苦味；腹泻时不宜多吃。', image: 'assets/images/foods/kugua.webp'),
        _Item(name: '莲藕', desc: '夏季上市的时令食材，可凉拌、炖汤或清炒，口感脆甜。', tip: '藕片焯水后凉拌；与排骨炖汤约 1 小时。', image: 'assets/images/foods/lianou.webp'),
        _Item(name: '西瓜', desc: '夏季解渴的水果，水分充足；不宜冰镇过度，一次不宜吃太多。', tip: '常温或微凉食用即可；糖尿病患者请遵医嘱控制量。', image: 'assets/images/foods/xigua.webp'),
        _Item(name: '薏米红豆粥', desc: '夏季常见的粥品，口感软糯，常搭配红豆一起煮。', tip: '薏米和红豆提前浸泡 2 小时，煮约 40 分钟。', image: 'assets/images/foods/yimi.webp'),
      ];
    case 'autumn':
      return const [
        _Item(name: '银耳雪梨羹', desc: '秋季干燥时常见的甜汤，口感润滑，做法简单。', tip: '银耳泡发撕小朵，与雪梨块同煮约 40 分钟，可加少量冰糖。', image: 'assets/images/foods/yinger.webp'),
        _Item(name: '百合', desc: '秋季上市的鲜百合，可清炒、煮粥或做甜汤，口感清甜。', tip: '鲜百合掰开洗净，与西芹清炒或加入粥中；注意不要煮得过烂。', image: 'assets/images/foods/baihe.webp'),
        _Item(name: '莲子', desc: '常用于煮粥、煲汤的传统食材，口感软糯。', tip: '莲子提前泡软，去芯后与米同煮约 40 分钟；莲心味苦，可去除。', image: 'assets/images/foods/lianzi.webp'),
        _Item(name: '山药', desc: '秋冬常见的根茎蔬菜，可蒸、炒或炖汤，口感绵软。', tip: '削皮时注意戴手套，避免手痒；蒸熟蘸少量糖或清炒。', image: 'assets/images/foods/shanyao.webp'),
        _Item(name: '柿子', desc: '霜降前后上市，民间有「霜降吃柿子」的习俗。', tip: '要吃完全成熟的柿子；不要空腹吃，也不要与大量螃蟹同食。', image: 'assets/images/foods/shizi.webp'),
        _Item(name: '板栗', desc: '秋季的坚果，可煮、炒或炖鸡，口感粉糯。', tip: '在壳上划口后再煮或烤；一次不宜吃太多，容易胀气。', image: 'assets/images/foods/banli.webp'),
      ];
    case 'winter':
      return const [
        _Item(name: '白萝卜', desc: '冬季常见的蔬菜，可炖汤、清炒或腌制，口感清甜。', tip: '与排骨或羊肉同炖约 1 小时；切块后先焯水可减轻辛味。', image: 'assets/images/foods/luobo.webp'),
        _Item(name: '羊肉汤', desc: '北方不少地方有立冬、冬至前后吃羊肉的习惯。', tip: '羊肉先焯水去腥，加姜片慢炖约 1.5 小时；高血压、上火者适量。', image: 'assets/images/foods/yangrou.webp'),
        _Item(name: '烤红薯', desc: '冬季常见的小吃，香甜软糯，含有膳食纤维。', tip: '带皮烤约 40 分钟；不要吃烤焦的部分，一次不宜多吃。', image: 'assets/images/foods/hongshu.webp'),
        _Item(name: '核桃', desc: '常见的坚果，可直接吃或加入粥、点心，口感香脆。', tip: '每天一小把即可，注意控制总量；对坚果过敏者避免。', image: 'assets/images/foods/hetao.webp'),
        _Item(name: '黑芝麻糊', desc: '冬季常见的热饮甜点，香味浓郁，口感细腻。', tip: '熟黑芝麻与糯米粉加水煮成糊，少放糖。', image: 'assets/images/foods/zhima.webp'),
        _Item(name: '腊八粥', desc: '农历腊月初八的传统食俗，用多种谷物和干果煮成。', tip: '米、豆、干果提前浸泡，小火慢煮约 1 小时。', image: 'assets/images/foods/laba.webp'),
      ];
  }
  return const [];
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
