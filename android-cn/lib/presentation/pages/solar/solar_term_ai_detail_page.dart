/// 节气详情页（图文版）— 封面插画 → 关键信息 chips → 引言卡 → 物候三候时间轴 → 生活方案卡片 → 静心 → 资料来源（可折叠）
/// 全部条目为「待审核」，来源：中国气象局、紫金山天文台、国家中医药管理局；不含疗效声明。
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../design_system/theme.dart';

class SolarTermAIDetailPage extends StatelessWidget {
  final String termName;
  final String? season;
  final String? englishName;

  const SolarTermAIDetailPage({
    super.key,
    required this.termName,
    this.season,
    this.englishName,
  });

  static const _termData = {
    '立春': _TermData(
      englishName: '二十四节气 · 第1个',
      season: '春季 · 第一节气',
      quote: '立，建始也，五行之气，往者过，来者续',
      description: '立春是二十四节气的第1个节气，太阳到达黄经315°。2026年交节时刻：2月4日 04:02（北京时间，紫金山天文台）。物候“三候”：东风解冻、蛰虫始振、鱼陟负冰。',
      foodTitle: '咬春',
      foodDesc: '立春有“咬春”的习俗：北方人吃春饼、萝卜，南方人吃春卷，都是对春天的期待。',
      foodTags: ['春饼', '春卷', '萝卜'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 八段锦',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '立春 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“东风解冻”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      sources: [
        _Source('中国气象局 · 立春专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/lichun/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '雨水': _TermData(
      englishName: '二十四节气 · 第2个',
      season: '春季 · 第二节气',
      quote: '好雨知时节，当春乃发生',
      description: '雨水是二十四节气的第2个节气，太阳到达黄经330°。2026年交节时刻：2月18日 23:52（北京时间，紫金山天文台）。物候“三候”：獭祭鱼、雁北归、草木萌动。',
      foodTitle: '均衡时令餐',
      foodDesc: '雨水前后宜按国家中医药管理局《中国公民中医养生保健素养》的提示，谷类、蔬菜、水果、禽肉均衡搭配，不偏食偏嗜。',
      foodTags: ['谷类', '蔬菜', '水果'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。民间素有“春捂”之俗，提醒人们顺应天时、灵活增减衣物。',
      exerciseTitle: '传统健身 · 太极拳',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '雨水 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“獭祭鱼”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      sources: [
        _Source('中国气象局 · 雨水专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/yushui/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '惊蛰': _TermData(
      englishName: '二十四节气 · 第3个',
      season: '春季 · 第三节气',
      quote: '二月节，万物出乎震，震为雷，故曰惊蛰',
      description: '惊蛰是二十四节气的第3个节气，太阳到达黄经345°，春雷始鸣，蛰伏的虫类渐渐苏醒。2026年交节时刻：3月5日 21:59（北京时间，紫金山天文台）。物候“三候”：桃始华、仓庚鸣、鹰化为鸠。',
      foodTitle: '惊蛰吃梨',
      foodDesc: '部分地区保留惊蛰吃梨的习俗，“梨”与“离”谐音，寓意远离害虫与疾病，求个平安顺遂。',
      foodTags: ['梨'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 五禽戏',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '惊蛰 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“桃始华”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      sources: [
        _Source('中国气象局 · 惊蛰专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/jingzhe/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '春分': _TermData(
      englishName: '二十四节气 · 第4个',
      season: '春季 · 第四节气',
      quote: '昼夜均而寒暑平。',
      description: '春分是二十四节气的第4个节气，太阳到达黄经0°，此日太阳直射赤道，昼夜几乎等长。2026年交节时刻：3月20日 22:46（北京时间，紫金山天文台）。物候“三候”：元鸟至、雷乃发声、始电。',
      foodTitle: '春分竖蛋',
      foodDesc: '俗话说“春分到，蛋儿俏”，春分这天，人们喜欢挑一只新鲜鸡蛋，试着把它稳稳立在桌上；这是流传已久的春分民俗。',
      foodTags: ['竖蛋'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 六字诀',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '春分 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“元鸟至”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      sources: [
        _Source('中国气象局 · 春分专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/chunfen/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '清明': _TermData(
      englishName: '二十四节气 · 第5个',
      season: '春季 · 第五节气',
      quote: '麦怕清明霜，谷要秋来旱',
      description: '清明是二十四节气的第5个节气，太阳到达黄经15°。2026年交节时刻：4月5日 02:40（北京时间，紫金山天文台）。物候“三候”：桐始华、田鼠化为鴽、虹始见。',
      foodTitle: '青团艾糍',
      foodDesc: '清明前后，南方有以艾草入食、做艾糍与青团的习俗，也有清明果；开封一带流行杏仁茶。',
      foodTags: ['青团', '艾糍', '清明果'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 八段锦',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '清明 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“桐始华”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      sources: [
        _Source('中国气象局 · 清明专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/qingming/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '谷雨': _TermData(
      englishName: '二十四节气 · 第6个',
      season: '春季 · 第六节气',
      quote: '清明断雪，谷雨断霜',
      description: '谷雨是二十四节气的第6个节气，太阳到达黄经30°。2026年交节时刻：4月20日 09:39（北京时间，紫金山天文台）。物候“三候”：萍始生、鸣鸠拂其羽、戴胜降于桑。',
      foodTitle: '谷雨茶 · 香椿',
      foodDesc: '谷雨时节，南方采制春茶，称“谷雨茶”；北方有食香椿的习俗，也叫“吃春”。',
      foodTags: ['谷雨茶', '香椿芽'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 太极拳',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '谷雨 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“萍始生”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
      sources: [
        _Source('中国气象局 · 谷雨专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/guyu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '立夏': _TermData(
      englishName: '二十四节气 · 第7个',
      season: '夏季 · 第一节气',
      quote: '立夏不下，犁耙高挂',
      description: '立夏是二十四节气的第7个节气，太阳到达黄经45°。2026年交节时刻：5月5日 19:49（北京时间，紫金山天文台）。物候“三候”：蝼蝈鸣、蚯蚓出、王瓜生。',
      foodTitle: '立夏蛋 · 尝新',
      foodDesc: '立夏这天，各家会给孩子煮立夏蛋，挂在胸前玩“斗蛋”；江浙一带有蒸新茶、配时令水果馈赠亲邻的习俗。',
      foodTags: ['立夏蛋', '新茶', '时令水果'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。立夏还有“称人”的民俗，也是孩子们最期待的一天。',
      exerciseTitle: '传统健身 · 五禽戏',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '立夏 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“蝼蝈鸣”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF1B4D45), Color(0xFF2F7A5E)],
      sources: [
        _Source('中国气象局 · 立夏专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/lixia/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '小满': _TermData(
      englishName: '二十四节气 · 第8个',
      season: '夏季 · 第二节气',
      quote: '小满不满，麦有一险',
      description: '小满是二十四节气的第8个节气，太阳到达黄经60°。2026年交节时刻：5月21日 08:37（北京时间，紫金山天文台）。物候“三候”：苦菜秀、靡草死、麦秋至。',
      foodTitle: '小满吃苦菜',
      foodDesc: '小满前后，民间有吃苦菜的习惯：嫩叶生吃略带苦味，用开水烫一下也好吃；一粥一饭里藏着小满的烟火气。',
      foodTags: ['苦菜', '粥'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 六字诀',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '小满 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“苦菜秀”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF1B4D45), Color(0xFF2F7A5E)],
      sources: [
        _Source('中国气象局 · 小满专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/xiaoman/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '芒种': _TermData(
      englishName: '二十四节气 · 第9个',
      season: '夏季 · 第三节气',
      quote: '收麦如救火，龙口把粮夺',
      description: '芒种是二十四节气的第9个节气，太阳到达黄经75°。2026年交节时刻：6月5日 23:48（北京时间，紫金山天文台）。物候“三候”：螳螂生、鵙始鸣、反舌无声。',
      foodTitle: '新麦与青梅',
      foodDesc: '芒种有“北食新麦、南烹青梅”的时令食俗，顺应物候，让忙碌的夏日多一份温润的烟火诗意。',
      foodTags: ['新麦面食', '青梅'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 八段锦',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '芒种 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“螳螂生”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF1B4D45), Color(0xFF2F7A5E)],
      sources: [
        _Source('中国气象局 · 芒种专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/mangzhong/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '夏至': _TermData(
      englishName: '二十四节气 · 第10个',
      season: '夏季 · 第四节气',
      quote: '吃过夏至面，一天短一线',
      description: '夏至是二十四节气的第10个节气，太阳到达黄经90°。2026年交节时刻：6月21日 16:25（北京时间，紫金山天文台）。物候“三候”：鹿角解、蝉始鸣、半夏生。',
      foodTitle: '夏至面',
      foodDesc: '民间有“吃过夏至面，一天短一线”的说法；北方有“冬至饺子夏至面”，江南吃“夏至饼”，夏季也常见绿豆汤、冬瓜汤、酸梅汤。',
      foodTags: ['夏至面', '夏至饼', '绿豆汤'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 太极拳',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '夏至 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“鹿角解”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF1B4D45), Color(0xFF2F7A5E)],
      sources: [
        _Source('中国气象局 · 夏至专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/xiazhi/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '小暑': _TermData(
      englishName: '二十四节气 · 第11个',
      season: '夏季 · 第五节气',
      quote: '暑，热也，就热之中分为大小，月初为小',
      description: '小暑是二十四节气的第11个节气，太阳到达黄经105°。2026年交节时刻：7月7日 09:57（北京时间，紫金山天文台）。物候“三候”：温风至、蟋蟀居宇、鹰始鸷。',
      foodTitle: '伏日食俗 · 食新',
      foodDesc: '北方有“头伏饺子，二伏面，三伏烙饼摊鸡蛋”的说法；小暑过后还有“食新”习俗，即尝新米、祭祀五谷与祖先。',
      foodTags: ['伏日饺子', '新米饭', '烙饼'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 五禽戏',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '小暑 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“温风至”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF1B4D45), Color(0xFF2F7A5E)],
      sources: [
        _Source('中国气象局 · 小暑专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/xiaoshu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '大暑': _TermData(
      englishName: '二十四节气 · 第12个',
      season: '夏季 · 第六节气',
      quote: '月中为大，今则热气犹大也',
      description: '大暑是二十四节气的第12个节气，太阳到达黄经120°。2026年交节时刻：7月23日 03:13（北京时间，紫金山天文台）。物候“三候”：腐草为萤、土润溽暑、大雨时行。',
      foodTitle: '仙草 · 酸菜面',
      foodDesc: '广东不少地方大暑有吃仙草（凉粉、烧仙草）的习俗；陕西安康则流行酸菜面，也有喝绿豆汤的做法。',
      foodTags: ['烧仙草', '酸菜面', '绿豆汤'],
      livingTitle: '晚睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：春季、夏季宜晚睡早起。',
      exerciseTitle: '传统健身 · 六字诀',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '大暑 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“腐草为萤”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF1B4D45), Color(0xFF2F7A5E)],
      sources: [
        _Source('中国气象局 · 大暑专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/dashu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '立秋': _TermData(
      englishName: '二十四节气 · 第13个',
      season: '秋季 · 第一节气',
      quote: '秋，揪也，物于此而揪敛也',
      description: '立秋是二十四节气的第13个节气，太阳到达黄经135°。2026年交节时刻：8月7日 19:43（北京时间，紫金山天文台）。物候“三候”：凉风至、白露生、寒蝉鸣。',
      foodTitle: '贴秋膘 · 咬秋',
      foodDesc: '立秋有“贴秋膘”的习俗，炖肉、烤肉、红烧肉上桌；也有人在这天吃西瓜或香瓜，寓意把秋天“咬住”。',
      foodTags: ['贴秋膘', '西瓜'],
      livingTitle: '早睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：秋季宜早睡早起。',
      exerciseTitle: '传统健身 · 八段锦',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '立秋 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“凉风至”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF5A3A1E), Color(0xFF8A5A2B)],
      sources: [
        _Source('中国气象局 · 立秋专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/liqiu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '处暑': _TermData(
      englishName: '二十四节气 · 第14个',
      season: '秋季 · 第二节气',
      quote: '处，止也，暑气至此而止矣',
      description: '处暑是二十四节气的第14个节气，太阳到达黄经150°。2026年交节时刻：8月23日 10:19（北京时间，紫金山天文台）。物候“三候”：鹰乃祭鸟、天地始肃、禾乃登。',
      foodTitle: '处暑鸭',
      foodDesc: '民间有处暑吃鸭子的习俗，认为农历七月中旬的鸭子最为肥美；也有“处暑润燥，少辛多酸”的谚语流传。',
      foodTags: ['鸭子', '葡萄', '山楂'],
      livingTitle: '早睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：秋季宜早睡早起。处暑前后昼暖夜凉、温差增大，出门不妨备一件薄外套。',
      exerciseTitle: '传统健身 · 太极拳',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '处暑 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“鹰乃祭鸟”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF5A3A1E), Color(0xFF8A5A2B)],
      sources: [
        _Source('中国气象局 · 处暑专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/chushu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '白露': _TermData(
      englishName: '二十四节气 · 第15个',
      season: '秋季 · 第三节气',
      quote: '水土湿气凝而为露，秋属金，金色白，白者露之色，而气始寒也',
      description: '白露是二十四节气的第15个节气，太阳到达黄经165°。2026年交节时刻：9月7日 22:41（北京时间，紫金山天文台）。物候“三候”：鸿雁来、玄鸟归、群鸟养羞。',
      foodTitle: '白露茶 · 社糕',
      foodDesc: '民间有“要喝茶，秋白露”的说法；宋时白露前后还有食社糕、饮酒的风俗。',
      foodTags: ['白露茶', '社糕', '建瓯锥栗'],
      livingTitle: '早睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：秋季宜早睡早起。',
      exerciseTitle: '传统健身 · 五禽戏',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '白露 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“鸿雁来”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF5A3A1E), Color(0xFF8A5A2B)],
      sources: [
        _Source('中国气象局 · 白露专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/bailu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '秋分': _TermData(
      englishName: '二十四节气 · 第16个',
      season: '秋季 · 第四节气',
      quote: '白露早，寒露迟，秋分种麦正当时',
      description: '秋分是二十四节气的第16个节气，太阳到达黄经180°。2026年交节时刻：9月23日 08:05（北京时间，紫金山天文台）。物候“三候”：雷始收声、蛰虫坯户、水始涸。',
      foodTitle: '秋菜 · 秋汤',
      foodDesc: '岭南有“秋分吃秋菜”的习俗，也有喝秋汤的传统；一碗温润的粥羹、一壶老白茶、一勺秋梨膏，都是节气文化落在日子里的样子。',
      foodTags: ['秋菜', '秋汤', '秋梨膏'],
      livingTitle: '早睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：秋季宜早睡早起。',
      exerciseTitle: '传统健身 · 六字诀',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '秋分 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“雷始收声”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF5A3A1E), Color(0xFF8A5A2B)],
      sources: [
        _Source('中国气象局 · 秋分专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/qiufen/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '寒露': _TermData(
      englishName: '二十四节气 · 第17个',
      season: '秋季 · 第五节气',
      quote: '九月节，露气寒冷，将凝结也',
      description: '寒露是二十四节气的第17个节气，太阳到达黄经195°。2026年交节时刻：10月8日 14:29（北京时间，紫金山天文台）。物候“三候”：鸿雁来宾、雀入大水为蛤、菊有黄华。',
      foodTitle: '芝麻 · 螃蟹 · 秋茶',
      foodDesc: '寒露传统习俗主要有赏枫叶、吃芝麻、吃螃蟹、饮秋茶等；江南一带还爱赏菊、钓鱼。',
      foodTags: ['芝麻', '螃蟹', '秋茶'],
      livingTitle: '早睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：秋季宜早睡早起。中国气象局专题页提到：寒露后天气转凉，注意足部保暖，适时添衣。',
      exerciseTitle: '传统健身 · 八段锦',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '寒露 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“鸿雁来宾”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF5A3A1E), Color(0xFF8A5A2B)],
      sources: [
        _Source('中国气象局 · 寒露专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/hanlu/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '霜降': _TermData(
      englishName: '二十四节气 · 第18个',
      season: '秋季 · 第六节气',
      quote: '气肃而凝，露结为霜矣',
      description: '霜降是二十四节气的第18个节气，太阳到达黄经210°。2026年交节时刻：10月23日 17:38（北京时间，紫金山天文台）。物候“三候”：豺乃祭兽、草木黄落、蜇虫咸俯。',
      foodTitle: '霜降吃柿',
      foodDesc: '霜降前后，柿子挂满枝头，吃柿子是重要民俗，取“柿柿如意”的好兆头；也有赏菊品茶的传统。',
      foodTags: ['柿子', '菊花茶'],
      livingTitle: '早睡早起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：秋季宜早睡早起。',
      exerciseTitle: '传统健身 · 太极拳',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '霜降 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“豺乃祭兽”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF5A3A1E), Color(0xFF8A5A2B)],
      sources: [
        _Source('中国气象局 · 霜降专题', 'https://www.cma.gov.cn/ztbd/2026zt/24jq/shuangjiang/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '立冬': _TermData(
      englishName: '二十四节气 · 第19个',
      season: '冬季 · 第一节气',
      quote: '立，建始也；冬，终也，万物收藏也',
      description: '立冬是二十四节气的第19个节气，太阳到达黄经225°。2026年交节时刻：11月7日 17:52（北京时间，紫金山天文台）。物候“三候”：水始冰、地始冻、雉入大水为蜃。',
      foodTitle: '饺子 · 汤圆',
      foodDesc: '北方立冬有吃饺子的习俗，饺子谐音“交子”，意指秋冬之交；南方则多吃汤圆，一家人围炉包饺子、煮汤圆。',
      foodTags: ['饺子', '汤圆'],
      livingTitle: '早睡晚起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：冬季宜早睡晚起。',
      exerciseTitle: '传统健身 · 五禽戏',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '立冬 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“水始冰”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF263A57), Color(0xFF3E5A7D)],
      sources: [
        _Source('中国气象局 · 立冬专题', 'https://www.cma.gov.cn/ztbd/2025zt/24jq/lidong/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '小雪': _TermData(
      englishName: '二十四节气 · 第20个',
      season: '冬季 · 第二节气',
      quote: '小雪腌菜，大雪腌肉',
      description: '小雪是二十四节气的第20个节气，太阳到达黄经240°。2026年交节时刻：11月22日 15:23（北京时间，紫金山天文台）。物候“三候”：虹藏不见、天气上升地气下降、闭塞而成冬。',
      foodTitle: '腌菜 · 糍粑 · 刨汤',
      foodDesc: '小雪前后有腌咸菜、做糍粑、吃刨汤的习俗，谚语说“小雪腌菜，大雪腌肉”；南方许多地方也有腊肉、腊味的传统。',
      foodTags: ['糍粑', '刨汤', '腊肉'],
      livingTitle: '早睡晚起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：冬季宜早睡晚起。',
      exerciseTitle: '传统健身 · 六字诀',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '小雪 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“虹藏不见”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF263A57), Color(0xFF3E5A7D)],
      sources: [
        _Source('中国气象局 · 小雪专题', 'https://www.cma.gov.cn/ztbd/2025zt/24jq/xiaoxue/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '大雪': _TermData(
      englishName: '二十四节气 · 第21个',
      season: '冬季 · 第三节气',
      quote: '今年麦盖三层被，来年枕着馒头睡',
      description: '大雪是二十四节气的第21个节气，太阳到达黄经255°。2026年交节时刻：12月7日 10:53（北京时间，紫金山天文台）。物候“三候”：鹖鴠不鸣、虎始交、荔挺出。',
      foodTitle: '热汤 · 围炉',
      foodDesc: '大雪天寒，喝一碗热汤、吃一顿火锅是常见的取暖办法，也有围炉煮茶、闲叙旧话的雅趣；东北朝鲜族有打糕的年味习俗。',
      foodTags: ['热汤', '火锅', '打糕'],
      livingTitle: '早睡晚起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：冬季宜早睡晚起。',
      exerciseTitle: '传统健身 · 八段锦',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '大雪 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“鹖鴠不鸣”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF263A57), Color(0xFF3E5A7D)],
      sources: [
        _Source('中国气象局 · 大雪专题', 'https://www.cma.gov.cn/ztbd/2025zt/24jq/daxue/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '冬至': _TermData(
      englishName: '二十四节气 · 第22个',
      season: '冬季 · 第四节气',
      quote: '终藏之气，至此而极也',
      description: '冬至是二十四节气的第22个节气，太阳到达黄经270°。2026年交节时刻：12月22日 04:50（北京时间，紫金山天文台）。物候“三候”：蚯蚓结、麋角解、水泉动。',
      foodTitle: '冬至饺 · 汤圆',
      foodDesc: '冬至的传统节日食品有馄饨、饺子、汤圆、赤豆粥、黍米糕；北方宰羊、吃饺子，南方吃冬至米团、长线面，江南有赤豆糯米饭。',
      foodTags: ['饺子', '馄饨', '赤豆粥', '汤圆'],
      livingTitle: '早睡晚起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：冬季宜早睡晚起。冬至过后进入“数九”，白昼渐长，民间有“吃了冬至饭，一天长一线”的说法。',
      exerciseTitle: '传统健身 · 太极拳',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '冬至 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“蚯蚓结”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF263A57), Color(0xFF3E5A7D)],
      sources: [
        _Source('中国气象局 · 冬至专题', 'https://www.cma.gov.cn/ztbd/2025zt/24jq/dongzhi/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '小寒': _TermData(
      englishName: '二十四节气 · 第23个',
      season: '冬季 · 第五节气',
      quote: '月初寒尚小，故云',
      description: '小寒是二十四节气的第23个节气，太阳到达黄经285°。2026年交节时刻：1月5日 16:23（北京时间，紫金山天文台）。物候“三候”：雁北乡、鹊始巢、雉始雊。',
      foodTitle: '腊八粥 · 菜饭',
      foodDesc: '小寒前后，北京有喝腊八粥的习俗，南京则吃菜饭；各地温度与习俗不同，共同的是同一血脉里的节气情结。',
      foodTags: ['腊八粥', '南京菜饭'],
      livingTitle: '早睡晚起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：冬季宜早睡晚起。',
      exerciseTitle: '传统健身 · 五禽戏',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '小寒 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“雁北乡”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF263A57), Color(0xFF3E5A7D)],
      sources: [
        _Source('中国气象局 · 小寒专题', 'https://www.cma.gov.cn/ztbd/2025zt/24jq/xiaohan/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
    '大寒': _TermData(
      englishName: '二十四节气 · 第24个',
      season: '冬季 · 第六节气',
      quote: '大寒见三白，来年好收成',
      description: '大寒是二十四节气的第24个节气，太阳到达黄经300°。2026年交节时刻：1月20日 09:45（北京时间，紫金山天文台）。物候“三候”：鸡乳、征鸟厉疾、水泽腹坚。',
      foodTitle: '腊八粥 · 消寒糕',
      foodDesc: '大寒时节，西安有喝腊八粥的习俗，可甜可咸；老北京吃消寒糕，取消除寒冷、步步高升的寓意。',
      foodTags: ['腊八粥', '消寒糕'],
      livingTitle: '早睡晚起',
      livingDesc: '国家中医药管理局《中国公民中医养生保健素养》提示：冬季宜早睡晚起。',
      exerciseTitle: '传统健身 · 六字诀',
      exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，是《中国公民中医养生保健素养》列出的传统健身项目。动作舒缓，量力而行。',
      meditationTitle: '大寒 · 静心片刻',
      meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次，留意窗外的天光与风。再想一想本节气的物候“鸡乳”，看看今天身边是否有类似的小变化。这是一段文字引导的静心小练习，不含音频。',
      meditationDuration: '3 分钟',
      gradient: [Color(0xFF263A57), Color(0xFF3E5A7D)],
      sources: [
        _Source('中国气象局 · 大寒专题', 'https://www.cma.gov.cn/ztbd/2025zt/24jq/dahan/index.html'),
        _Source('中国科学院紫金山天文台 · 2026年日历资料（交节时刻）', 'https://www.pmo.cas.cn/xwdt2019/kpdt2019/202203/P020251230620718707826.pdf'),
        _Source('国家中医药管理局 · 《中国公民中医养生保健素养》（起居与传统健身）', 'http://www.natcm.gov.cn/bangongshi/gongzuodongtai/2018-03-25/5248.html'),
      ],
    ),
  };

  // 结构化关键信息：序号、太阳黄经、2026 交节时刻（紫金山天文台）、物候三候（中国气象局）
  static const _facts = {
    '立春': _Facts(1, 315, '2月4日 04:02', ['东风解冻', '蛰虫始振', '鱼陟负冰']),
    '雨水': _Facts(2, 330, '2月18日 23:52', ['獭祭鱼', '雁北归', '草木萌动']),
    '惊蛰': _Facts(3, 345, '3月5日 21:59', ['桃始华', '仓庚鸣', '鹰化为鸠']),
    '春分': _Facts(4, 0, '3月20日 22:46', ['元鸟至', '雷乃发声', '始电']),
    '清明': _Facts(5, 15, '4月5日 02:40', ['桐始华', '田鼠化为鴽', '虹始见']),
    '谷雨': _Facts(6, 30, '4月20日 09:39', ['萍始生', '鸣鸠拂其羽', '戴胜降于桑']),
    '立夏': _Facts(7, 45, '5月5日 19:49', ['蝼蝈鸣', '蚯蚓出', '王瓜生']),
    '小满': _Facts(8, 60, '5月21日 08:37', ['苦菜秀', '靡草死', '麦秋至']),
    '芒种': _Facts(9, 75, '6月5日 23:48', ['螳螂生', '鵙始鸣', '反舌无声']),
    '夏至': _Facts(10, 90, '6月21日 16:25', ['鹿角解', '蝉始鸣', '半夏生']),
    '小暑': _Facts(11, 105, '7月7日 09:57', ['温风至', '蟋蟀居宇', '鹰始鸷']),
    '大暑': _Facts(12, 120, '7月23日 03:13', ['腐草为萤', '土润溽暑', '大雨时行']),
    '立秋': _Facts(13, 135, '8月7日 19:43', ['凉风至', '白露生', '寒蝉鸣']),
    '处暑': _Facts(14, 150, '8月23日 10:19', ['鹰乃祭鸟', '天地始肃', '禾乃登']),
    '白露': _Facts(15, 165, '9月7日 22:41', ['鸿雁来', '玄鸟归', '群鸟养羞']),
    '秋分': _Facts(16, 180, '9月23日 08:05', ['雷始收声', '蛰虫坯户', '水始涸']),
    '寒露': _Facts(17, 195, '10月8日 14:29', ['鸿雁来宾', '雀入大水为蛤', '菊有黄华']),
    '霜降': _Facts(18, 210, '10月23日 17:38', ['豺乃祭兽', '草木黄落', '蜇虫咸俯']),
    '立冬': _Facts(19, 225, '11月7日 17:52', ['水始冰', '地始冻', '雉入大水为蜃']),
    '小雪': _Facts(20, 240, '11月22日 15:23', ['虹藏不见', '天气上升地气下降', '闭塞而成冬']),
    '大雪': _Facts(21, 255, '12月7日 10:53', ['鹖鴠不鸣', '虎始交', '荔挺出']),
    '冬至': _Facts(22, 270, '12月22日 04:50', ['蚯蚓结', '麋角解', '水泉动']),
    '小寒': _Facts(23, 285, '1月5日 16:23', ['雁北乡', '鹊始巢', '雉始雊']),
    '大寒': _Facts(24, 300, '1月20日 09:45', ['鸡乳', '征鸟厉疾', '水泽腹坚']),
  };

  static const _cover = {
    '立春': 'lichun',
    '雨水': 'yushui',
    '惊蛰': 'jingzhe',
    '春分': 'chunfen',
    '清明': 'qingming',
    '谷雨': 'guyu',
    '立夏': 'lixia',
    '小满': 'xiaoman',
    '芒种': 'mangzhong',
    '夏至': 'xiazhi',
    '小暑': 'xiaoshu',
    '大暑': 'dashu',
    '立秋': 'liqiu',
    '处暑': 'chushu',
    '白露': 'bailu',
    '秋分': 'qiufen',
    '寒露': 'hanlu',
    '霜降': 'shuangjiang',
    '立冬': 'lidong',
    '小雪': 'xiaoxue',
    '大雪': 'daxue',
    '冬至': 'dongzhi',
    '小寒': 'xiaohan',
    '大寒': 'dahan',
  };

  // 食俗标签 → 已有的食材插画
  static const _foodImg = {
    '青团': 'qingtuan', '艾糍': 'aicao', '香椿芽': 'xiangchun', '香椿': 'xiangchun', '柿子': 'shizi',
    '西瓜': 'xigua', '绿豆汤': 'lvdou', '腊八粥': 'laba', '芝麻': 'zhima', '萝卜': 'luobo',
  };

  _TermData get _data =>
      _termData[termName] ??
      _TermData(
        englishName: englishName ?? '二十四节气',
        season: season ?? '二十四节气',
        quote: '顺天时，养正气。',
        description: '$termName时节，阴阳交替，万物更新。顺应自然节律，调和身心。',
        foodTitle: '时令饮食',
        foodDesc: '选用当季食材，均衡搭配。',
        foodTags: ['时令食材'],
        livingTitle: '起居有常',
        livingDesc: '顺应日出日落，调整作息。',
        exerciseTitle: '传统健身',
        exerciseDesc: '太极拳、八段锦、五禽戏、六字诀，量力而行。',
        meditationTitle: '$termName · 静心片刻',
        meditationDesc: '找一处安静的地方坐下，缓缓呼吸几次。',
        meditationDuration: '3 分钟',
        gradient: [Color(0xFF144227), Color(0xFF2D5A3D)],
        sources: const [],
      );

  String get _shareText {
    final d = _data;
    final f = _facts[termName];
    final extra = f == null ? d.description : '太阳黄经${f.longitude}°，2026年${f.when}交节';
    return '$termName · ${d.season}\n${d.quote}\n$extra\n—— 来自顺时';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final d = _data;
    final f = _facts[termName];
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, d, f),
                if (f != null) _buildFactChips(f),
                _buildQuoteCard(d, f),
                if (f != null) _buildHouTimeline(f, d),
                _buildSectionTitle(Icons.spa_outlined, '顺时生活方案'),
                _buildFoodCard(d),
                _buildLivingCard(d),
                _buildExerciseCard(d),
                _buildMeditationCard(d),
                _buildSourcesSection(d),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(child: _buildShareButton()),
          ),
        ],
      ),
    );
  }

  // ── 封面插画 Hero ──
  Widget _buildHero(BuildContext context, _TermData d, _Facts? f) {
    final cover = _cover[termName];
    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: d.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          if (cover != null)
            Image.asset(
              'assets/images/solar/$cover.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          // 底部渐暗，保证标题可读
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x40000000), Color(0x00000000), Color(0xB3000000)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(Icons.arrow_back_ios_new, () => Navigator.of(context).maybePop(), '返回'),
                  _circleButton(Icons.share_outlined, () => SharePlus.instance.share(ShareParams(text: _shareText)), '分享'),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                  child: Text(d.season, style: const TextStyle(fontSize: 13, letterSpacing: 2, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(termName, style: const TextStyle(
                  fontSize: 48, height: 1.15, fontWeight: FontWeight.w600, color: Colors.white,
                  fontFamily: ShunShiTypography.serifFamily,
                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 12)],
                )),
                const SizedBox(height: 4),
                Text(d.englishName, style: TextStyle(
                  fontSize: 15, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: ShunShiTypography.serifFamily,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, String label) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.32), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  // ── 关键信息 chips：序号 / 黄经 / 交节时刻 ──
  Widget _buildFactChips(_Facts f) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _factChip(Icons.tag, '第 ${f.index} 个节气', ShunShiColors.primary),
          _factChip(Icons.explore_outlined, '太阳黄经 ${f.longitude}°', ShunShiColors.secondary),
          _factChip(Icons.schedule, '2026年${f.when} 交节', ShunShiColors.apricot),
        ],
      ),
    );
  }

  Widget _factChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.3, color: ShunShiColors.textPrimary)),
        ],
      ),
    );
  }

  // ── 引言卡（pull-quote） ──
  Widget _buildQuoteCard(_TermData d, _Facts? f) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: ShunShiColors.apricot, width: 4)),
          boxShadow: ShunShiShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, size: 28, color: ShunShiColors.apricot.withValues(alpha: 0.8)),
            const SizedBox(height: 4),
            Text(d.quote, style: const TextStyle(
              fontSize: 20, height: 1.6, color: ShunShiColors.textPrimary,
              fontFamily: ShunShiTypography.serifFamily,
            )),
            if (f == null) ...[
              const SizedBox(height: 12),
              Text(d.description, style: const TextStyle(fontSize: 14, height: 1.7, color: ShunShiColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  // ── 物候三候时间轴 ──
  Widget _buildHouTimeline(_Facts f, _TermData d) {
    const labels = ['一候', '二候', '三候'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.timeline, '物候三候'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < f.hou.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : d.gradient.last.withValues(alpha: 0.35))),
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: d.gradient.last),
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                            Expanded(child: Container(height: 2, color: i == f.hou.length - 1 ? Colors.transparent : d.gradient.last.withValues(alpha: 0.35))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(labels[i], style: const TextStyle(fontSize: 12, letterSpacing: 2, color: ShunShiColors.textTertiary)),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(f.hou[i], textAlign: TextAlign.center, style: const TextStyle(
                            fontSize: 14, height: 1.45, color: ShunShiColors.textPrimary,
                            fontFamily: ShunShiTypography.serifFamily,
                          )),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: ShunShiColors.primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary,
            fontFamily: ShunShiTypography.serifFamily,
          )),
        ],
      ),
    );
  }

  Widget _lifeCard({required IconData icon, required Color color, required String label, required String title, required Widget body, Color? bgColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor ?? ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 2, color: ShunShiColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(
                    fontSize: 17, height: 1.4, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
                  )),
                  const SizedBox(height: 8),
                  body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _bodyStyle => const TextStyle(fontSize: 14, height: 1.6, color: ShunShiColors.textSecondary);

  Widget _buildFoodCard(_TermData d) {
    return _lifeCard(
      icon: Icons.restaurant_outlined,
      color: ShunShiColors.apricot,
      label: '节气食俗',
      title: d.foodTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.foodDesc, style: _bodyStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in d.foodTags) _foodTag(t)],
          ),
        ],
      ),
    );
  }

  Widget _foodTag(String tag) {
    final img = _foodImg[tag];
    return Container(
      padding: EdgeInsets.fromLTRB(img != null ? 4 : 12, 4, 12, 4),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (img != null) ...[
            ClipOval(
              child: Image.asset('assets/images/foods/$img.webp', width: 28, height: 28, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 28, height: 28)),
            ),
            const SizedBox(width: 8),
          ],
          Text(tag, style: const TextStyle(fontSize: 14, height: 1.4, color: ShunShiColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLivingCard(_TermData d) {
    return _lifeCard(
      icon: Icons.bedtime_outlined,
      color: ShunShiColors.blue,
      label: '起居',
      title: d.livingTitle,
      body: Text(d.livingDesc, style: _bodyStyle),
    );
  }

  Widget _buildExerciseCard(_TermData d) {
    return _lifeCard(
      icon: Icons.self_improvement,
      color: ShunShiColors.primaryLight,
      label: '传统健身',
      title: d.exerciseTitle.replaceFirst('传统健身 · ', ''),
      body: Text(d.exerciseDesc, style: _bodyStyle),
    );
  }

  // ── 静心：可折叠 ──
  Widget _buildMeditationCard(_TermData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        decoration: BoxDecoration(
          color: ShunShiColors.primaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('solar-meditation'),
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.air, size: 24, color: ShunShiColors.primary),
            ),
            title: Text(d.meditationTitle, style: const TextStyle(
              fontSize: 17, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            subtitle: const Text('静心提示 · 约 3 分钟', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(d.meditationDesc, style: _bodyStyle)],
          ),
        ),
      ),
    );
  }

  // ── 资料来源 / 待审核（可折叠） ──
  Widget _buildSourcesSection(_TermData d) {
    if (d.sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Container(
        key: const ValueKey('solar-sources'),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.12)),
        ),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            leading: const Icon(Icons.menu_book_outlined, size: 22, color: ShunShiColors.secondary),
            title: Row(
              children: [
                const Text('资料来源', style: TextStyle(fontSize: 15, color: ShunShiColors.textPrimary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: ShunShiColors.apricot.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                  child: const Text('待审核', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ShunShiColors.secondary)),
                ),
              ],
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final src in d.sources)
                InkWell(
                  onTap: () => launchUrl(Uri.parse(src.url), mode: LaunchMode.externalApplication),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '${src.label}\n', style: const TextStyle(fontSize: 14, height: 1.5, color: ShunShiColors.textPrimary)),
                      TextSpan(text: src.url, style: const TextStyle(
                        fontSize: 12, height: 1.4, color: ShunShiColors.primary, decoration: TextDecoration.underline)),
                    ])),
                  ),
                ),
              const SizedBox(height: 6),
              const Text('内容仅为节气物候、民俗与传统文化介绍，不构成医疗建议；条目待专家审核后正式发布。',
                  style: TextStyle(fontSize: 12, height: 1.5, color: ShunShiColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: () => SharePlus.instance.share(ShareParams(text: _shareText)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: ShunShiColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: ShunShiColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share, size: 20, color: Colors.white),
            SizedBox(width: 10),
            Text('分享这份顺时灵感', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _Facts {
  final int index;
  final int longitude;
  final String when;
  final List<String> hou;
  const _Facts(this.index, this.longitude, this.when, this.hou);
}

class _TermData {
  final String englishName;
  final String season;
  final String quote;
  final String description;
  final String foodTitle;
  final String foodDesc;
  final List<String> foodTags;
  final String livingTitle;
  final String livingDesc;
  final String exerciseTitle;
  final String exerciseDesc;
  final String meditationTitle;
  final String meditationDesc;
  final String meditationDuration;
  final List<Color> gradient;
  final List<_Source> sources;

  const _TermData({
    required this.englishName,
    required this.season,
    required this.quote,
    required this.description,
    required this.foodTitle,
    required this.foodDesc,
    required this.foodTags,
    required this.livingTitle,
    required this.livingDesc,
    required this.exerciseTitle,
    required this.exerciseDesc,
    required this.meditationTitle,
    required this.meditationDesc,
    required this.meditationDuration,
    required this.gradient,
    this.sources = const [],
  });
}

class _Source {
  final String label;
  final String url;
  const _Source(this.label, this.url);
}
