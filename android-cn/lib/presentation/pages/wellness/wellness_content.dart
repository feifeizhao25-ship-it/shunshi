/// 养生馆分类内容（离线内容库）。
/// 全部为传统文化与生活方式介绍，不含疗效/诊断声明；每个条目配有插画。
library;

class WellnessEntry {
  final String name;
  final String desc;
  final String tip;
  final String image;
  const WellnessEntry(this.name, this.desc, this.tip, this.image);
}

const String _w = 'assets/images/wellness/';

const Map<String, List<WellnessEntry>> kWellnessEntries = {
  'constitution': [
    WellnessEntry('平和质', '九种体质分类中的平和状态：体态适中，精力充沛，作息饮食规律。', '保持规律作息，饮食均衡，适度运动。', '${_w}cat_con_pinghe.webp'),
    WellnessEntry('气虚质', '传统体质分类之一，常见描述为容易疲乏、气短、声音偏低。', '作息规律，量力运动，避免过度劳累。', '${_w}cat_con_qixu.webp'),
    WellnessEntry('阳虚质', '传统体质分类之一，常见描述为手足偏凉、比较怕冷。', '注意保暖，饮食温热适量。', '${_w}cat_con_yangxu.webp'),
    WellnessEntry('阴虚质', '传统体质分类之一，常见描述为口干、手足心偏热、体型偏瘦。', '避免熬夜，饮食清淡，多补充水分。', '${_w}cat_con_yinxu.webp'),
    WellnessEntry('痰湿质', '传统体质分类之一，常见描述为体形偏胖、身体困重、面部油脂较多。', '饮食清淡，坚持日常活动。', '${_w}cat_con_tanshi.webp'),
    WellnessEntry('湿热质', '传统体质分类之一，常见描述为面部油光、容易长痘、口苦口干。', '少油腻辛辣，规律作息。', '${_w}cat_con_shire.webp'),
    WellnessEntry('血瘀质', '传统体质分类之一，常见描述为肤色偏暗、容易出现瘀斑。', '适度活动，保持心情舒畅。', '${_w}cat_con_xueyu.webp'),
    WellnessEntry('气郁质', '传统体质分类之一，常见描述为情绪偏低落、容易忧虑、形体偏瘦。', '多与人交流，经常到户外散步。', '${_w}cat_con_qiyu.webp'),
    WellnessEntry('特禀质', '传统体质分类之一，常见描述为对环境或食物比较敏感。', '留意个人过敏原，尽量避免接触。', '${_w}cat_con_tebing.webp'),
  ],
  'tea': [
    WellnessEntry('玫瑰花茶', '以干玫瑰花蕾冲泡的花茶，香气柔和，色泽粉润。', '干玫瑰花 5–8 朵，沸水冲泡，可按口味加蜂蜜。', '${_w}cat_tea_rose.webp'),
    WellnessEntry('陈皮普洱', '陈皮与普洱同泡，是广东等地常见的搭配，口感醇厚带柑香。', '陈皮 3 g、普洱 5 g，沸水冲泡。', '${_w}cat_tea_chenpi.webp'),
    WellnessEntry('红枣桂圆茶', '红枣与桂圆干同煮的甜茶，味道温润。', '红枣 5 枚、桂圆肉 10 g，沸水冲泡 10 分钟。', '${_w}cat_tea_hongzao.webp'),
    WellnessEntry('菊花枸杞茶', '菊花与枸杞同泡，是常见的家常茶饮，色泽清亮。', '菊花 5 朵、枸杞 10 g，沸水冲泡。', '${_w}cat_tea_juhua.webp'),
    WellnessEntry('生姜红枣茶', '生姜片与红枣同煮的热饮，辛甜暖口。', '生姜 3 片、红枣 5 枚，煮约 15 分钟。', '${_w}cat_tea_shengjiang.webp'),
  ],
  'acupressure': [
    WellnessEntry('合谷穴', '位于手背第一、二掌骨之间，约在虎口处，是传统按摩中常提到的穴位。', '用拇指轻柔按揉，力度以舒适为宜，每次约 3 分钟。', '${_w}cat_acu_hegu.webp'),
    WellnessEntry('足三里', '位于外膝眼下四横指、胫骨外侧一横指处。', '每日轻轻按揉约 5 分钟，同时放松小腿。', '${_w}cat_acu_zusanli.webp'),
    WellnessEntry('三阴交', '位于内踝尖上四横指、胫骨内侧缘后方。', '用拇指轻柔按揉 3–5 分钟；孕期请先咨询医生。', '${_w}cat_acu_sanyinjiao.webp'),
    WellnessEntry('涌泉穴', '位于足底前部凹陷处，约在足底前三分之一处。', '睡前可轻轻搓揉足底，以舒适为宜。', '${_w}cat_acu_yongquan.webp'),
    WellnessEntry('太冲穴', '位于足背第一、二跖骨结合部之前的凹陷中。', '按揉 3–5 分钟，力度由轻到适中。', '${_w}cat_acu_taichong.webp'),
    WellnessEntry('内关穴', '位于前臂掌侧，腕横纹上约三横指、两筋之间。', '轻柔按揉约 3 分钟，不适请立即停止。', '${_w}cat_acu_neiguan.webp'),
  ],
  'exercise': [
    WellnessEntry('八段锦', '由八个舒缓动作组成的传统健身功法，简单易学。', '晨起练习约 15 分钟，动作舒缓，呼吸自然。', '${_w}cat_ex_baduanjin.webp'),
    WellnessEntry('太极拳', '讲究松柔缓慢、以意领动，是流传很广的传统拳术。', '建议跟随专业老师学习，每次约 30 分钟。', '${_w}cat_ex_taiji.webp'),
    WellnessEntry('五禽戏', '模仿虎、鹿、熊、猿、鸟五种动物姿态的传统导引功法。', '每次约 20 分钟，动作舒展自然。', '${_w}cat_ex_wuqinxi.webp'),
    WellnessEntry('易筋经', '以十二势为主的传统导引功法，动作配合呼吸。', '适合有一定基础者，量力而行。', '${_w}cat_ex_yijinjing.webp'),
    WellnessEntry('六字诀', '以“嘘、呵、呼、呬、吹、嘻”六个字音配合呼吸的传统吐纳功法。', '清晨练习，每个字音约 6 次，配合呼吸。', '${_w}cat_ex_liuzijue.webp'),
  ],
  'sleep': [
    WellnessEntry('雨声白噪音', '持续稳定的雨声，营造安静的睡前氛围。', '建议睡前 30 分钟播放，音量调低并设置定时关闭。', '${_w}cat_sl_rain.webp'),
    WellnessEntry('古琴静听', '古琴音色悠远，适合在夜里安静聆听。', '选择节奏缓慢的曲目，如《平沙落雁》。', '${_w}cat_sl_guqin.webp'),
    WellnessEntry('自然冥想', '引导式冥想配合自然音效，帮助放松心情。', '跟随语音引导，关注呼吸，逐步放松全身。', '${_w}cat_sl_meditation.webp'),
    WellnessEntry('颂钵音', '颂钵的共鸣泛音绵长，适合安静独处时聆听。', '使用耳机效果更佳，可配合腹式呼吸。', '${_w}cat_sl_bowl.webp'),
    WellnessEntry('森林溪流', '溪水潺潺、鸟鸣清脆，把自然带进房间。', '适合午休或夜间使用。', '${_w}cat_sl_stream.webp'),
  ],
};

/// 分类封面插画
String wellnessCoverAsset(String type) => '${_w}cover_$type.webp';

/// 按名称查找条目插画（API 返回的条目没有图片时使用）。
String? wellnessImageForName(String name) {
  for (final list in kWellnessEntries.values) {
    for (final e in list) {
      if (e.name == name) return e.image;
    }
  }
  return null;
}
