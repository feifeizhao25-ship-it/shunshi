// Solar term data model + 24 solar terms mock data
// Extracted from solar_term_page.dart for maintainability

import 'package:flutter/material.dart';

class SolarTermInfo {
  final String name;
  final String date;
  final int month;
  final int day;
  final String season;
  final String emoji;
  final String poem;
  final List<String> diet;
  final List<String> acupoint;
  final List<String> exercise;
  final List<String> emotion;
  final int durationDays;

  const SolarTermInfo({
    required this.name,
    required this.date,
    required this.month,
    required this.day,
    required this.season,
    required this.emoji,
    required this.poem,
    required this.diet,
    required this.acupoint,
    required this.exercise,
    required this.emotion,
    this.durationDays = 15,
  });

  String get seasonLabel {
    switch (season) {
      case 'spring': return '春季';
      case 'summer': return '夏季';
      case 'autumn': return '秋季';
      case 'winter': return '冬季';
      default: return '';
    }
  }

  String get seasonShort {
    switch (season) {
      case 'spring': return '春';
      case 'summer': return '夏';
      case 'autumn': return '秋';
      case 'winter': return '冬';
      default: return '';
    }
  }
}

const List<SolarTermInfo> kAllSolarTerms = [
  SolarTermInfo(name: '立春', date: '二月四日', month: 2, day: 4, season: 'spring', emoji: '🌱', poem: '东风送暖立春来，万物复苏百花开', diet: ['葱白姜汤', '韭菜炒鸡蛋', '辛甘发散食物'], acupoint: ['太冲穴', '足三里', '风池穴'], exercise: ['散步', '太极拳', '拉伸运动'], emotion: ['保持心情舒畅', '多与朋友交流']),
  SolarTermInfo(name: '雨水', date: '二月十九日', month: 2, day: 19, season: 'spring', emoji: '🌧️', poem: '好雨知时节，当春乃发生', diet: ['小米粥', '红枣山药', '蜂蜜水'], acupoint: ['三阴交', '阴陵泉', '太白穴'], exercise: ['慢跑', '瑜伽', '八段锦'], emotion: ['保持心情平和', '避免忧郁过度']),
  SolarTermInfo(name: '惊蛰', date: '三月六日', month: 3, day: 6, season: 'spring', emoji: '⚡', poem: '春雷响万物长，惊蛰时节养生忙', diet: ['梨', '菠菜', '荠菜'], acupoint: ['太冲穴', '合谷穴', '曲池穴'], exercise: ['踏青', '放风筝', '太极拳'], emotion: ['疏肝解郁', '保持乐观开朗']),
  SolarTermInfo(name: '春分', date: '三月二十一日', month: 3, day: 21, season: 'spring', emoji: '🌸', poem: '春分昼夜平分时，阴阳调和养身体', diet: ['春笋', '香椿', '草莓'], acupoint: ['期门穴', '太冲穴', '足三里'], exercise: ['郊游', '慢跑', '瑜伽'], emotion: ['保持情绪稳定', '避免大喜大悲']),
  SolarTermInfo(name: '清明', date: '四月五日', month: 4, day: 5, season: 'spring', emoji: '🍃', poem: '清明时节雨纷纷，踏青赏花好时辰', diet: ['青团', '清明螺', '绿茶'], acupoint: ['太冲穴', '期门穴', '胆俞穴'], exercise: ['踏青', '登山', '放风筝'], emotion: ['舒缓情志', '亲近自然']),
  SolarTermInfo(name: '谷雨', date: '四月二十日', month: 4, day: 20, season: 'spring', emoji: '🌾', poem: '谷雨前后种瓜豆，养生重在健脾湿', diet: ['香椿', '谷雨茶', '薏仁粥'], acupoint: ['阴陵泉', '足三里', '太白穴'], exercise: ['散步', '八段锦', '太极拳'], emotion: ['调畅情志', '避免思虑过度']),
  SolarTermInfo(name: '立夏', date: '五月六日', month: 5, day: 6, season: 'summer', emoji: '☀️', poem: '立夏养生重在心，清淡饮食保安宁', diet: ['绿豆汤', '莲子粥', '苦瓜'], acupoint: ['内关穴', '神门穴', '心俞穴'], exercise: ['游泳', '清晨散步', '瑜伽'], emotion: ['养心安神', '戒躁戒怒']),
  SolarTermInfo(name: '小满', date: '五月二十一日', month: 5, day: 21, season: 'summer', emoji: '🌡️', poem: '小满未满万物茂，清热祛湿最重要', diet: ['冬瓜', '丝瓜', '绿豆'], acupoint: ['阴陵泉', '足三里', '中脘穴'], exercise: ['散步', '游泳', '太极'], emotion: ['保持心静', '避免焦躁不安']),
  SolarTermInfo(name: '芒种', date: '六月六日', month: 6, day: 6, season: 'summer', emoji: '🌿', poem: '芒种忙种莫忘养，清热解暑身体棒', diet: ['西瓜', '酸梅汤', '荷叶粥'], acupoint: ['曲池穴', '合谷穴', '大椎穴'], exercise: ['清晨运动', '游泳', '拉伸'], emotion: ['清热降火', '保持心情愉悦']),
  SolarTermInfo(name: '夏至', date: '六月二十一日', month: 6, day: 21, season: 'summer', emoji: '🌞', poem: '夏至阳极阴始生，养心护阳保安宁', diet: ['凉面', '绿豆汤', '莲子羹'], acupoint: ['内关穴', '神门穴', '足三里'], exercise: ['清晨散步', '游泳', '避免烈日运动'], emotion: ['养心安神', '切忌大喜过望']),
  SolarTermInfo(name: '小暑', date: '七月七日', month: 7, day: 7, season: 'summer', emoji: '🔥', poem: '小暑炎热防中暑，清淡饮食保脾胃', diet: ['西瓜', '黄瓜', '苦瓜'], acupoint: ['百会穴', '内关穴', '足三里'], exercise: ['清晨或傍晚运动', '游泳', '瑜伽'], emotion: ['心静自然凉', '避免情绪波动']),
  SolarTermInfo(name: '大暑', date: '七月二十三日', month: 7, day: 23, season: 'summer', emoji: '🌡️', poem: '大暑一年最热时，避暑养阴正当时', diet: ['绿豆汤', '薏仁粥', '荷叶茶'], acupoint: ['涌泉穴', '太溪穴', '肾俞穴'], exercise: ['室内运动', '游泳', '清晨散步'], emotion: ['养心静气', '避免暴怒狂躁']),
  SolarTermInfo(name: '立秋', date: '八月七日', month: 8, day: 7, season: 'autumn', emoji: '🍂', poem: '立秋养生重养肺，润燥生津保安康', diet: ['梨', '银耳', '百合'], acupoint: ['肺俞穴', '列缺穴', '太渊穴'], exercise: ['登山', '慢跑', '太极'], emotion: ['收敛神气', '避免悲忧伤肺']),
  SolarTermInfo(name: '处暑', date: '八月二十三日', month: 8, day: 23, season: 'autumn', emoji: '🌤️', poem: '处暑天凉好个秋，滋阴润燥记心头', diet: ['百合粥', '莲子羹', '蜂蜜'], acupoint: ['太溪穴', '肺俞穴', '三阴交'], exercise: ['散步', '登山', '瑜伽'], emotion: ['保持心情平和', '避免秋悲']),
  SolarTermInfo(name: '白露', date: '九月八日', month: 9, day: 8, season: 'autumn', emoji: '💧', poem: '白露秋分夜渐凉，润燥养肺最得当', diet: ['梨', '银耳羹', '莲藕'], acupoint: ['肺俞穴', '太渊穴', '列缺穴'], exercise: ['慢跑', '登山', '太极'], emotion: ['收敛情志', '保持心态平和']),
  SolarTermInfo(name: '秋分', date: '九月二十三日', month: 9, day: 23, season: 'autumn', emoji: '🍁', poem: '秋分昼夜又平分，阴阳平衡养身心', diet: ['山药', '百合', '蜂蜜'], acupoint: ['足三里', '三阴交', '太溪穴'], exercise: ['散步', '瑜伽', '太极'], emotion: ['调和情志', '保持心境平和']),
  SolarTermInfo(name: '寒露', date: '十月八日', month: 10, day: 8, season: 'autumn', emoji: '❄️', poem: '寒露时节渐转寒，保暖润燥养肺肝', diet: ['芝麻', '核桃', '银耳'], acupoint: ['肺俞穴', '肾俞穴', '太溪穴'], exercise: ['登山', '慢跑', '太极'], emotion: ['防秋悲', '保持乐观心态']),
  SolarTermInfo(name: '霜降', date: '十月二十三日', month: 10, day: 23, season: 'autumn', emoji: '🧊', poem: '霜降渐寒补脾胃，冬令进补好时机', diet: ['柿子', '栗子', '羊肉'], acupoint: ['足三里', '中脘穴', '脾俞穴'], exercise: ['登山', '慢跑', '太极'], emotion: ['防忧郁', '保持心情开朗']),
  SolarTermInfo(name: '立冬', date: '十一月七日', month: 11, day: 7, season: 'winter', emoji: '❄️', poem: '立冬进补养藏精，温补为主保安宁', diet: ['羊肉汤', '黑芝麻', '核桃'], acupoint: ['肾俞穴', '命门穴', '太溪穴'], exercise: ['太极拳', '散步', '室内运动'], emotion: ['养藏为主', '保持心态宁静']),
  SolarTermInfo(name: '小雪', date: '十一月二十二日', month: 11, day: 22, season: 'winter', emoji: '🌨️', poem: '小雪时节温补肾，早睡晚起养阳气', diet: ['羊肉', '黑豆', '桂圆'], acupoint: ['肾俞穴', '涌泉穴', '命门穴'], exercise: ['太极拳', '室内运动', '散步'], emotion: ['保持乐观', '避免冬季抑郁']),
  SolarTermInfo(name: '大雪', date: '十二月七日', month: 12, day: 7, season: 'winter', emoji: '⛄', poem: '大雪纷飞寒气重，温阳补肾要记清', diet: ['羊肉', '栗子', '枸杞粥'], acupoint: ['命门穴', '肾俞穴', '关元穴'], exercise: ['室内运动', '太极拳', '拉伸'], emotion: ['养藏为主', '保持心境安宁']),
  SolarTermInfo(name: '冬至', date: '十二月二十二日', month: 12, day: 22, season: 'winter', emoji: '🌙', poem: '冬至一阳生，进补养藏最当时', diet: ['饺子', '羊肉汤', '汤圆'], acupoint: ['关元穴', '命门穴', '涌泉穴'], exercise: ['室内运动', '太极拳', '散步'], emotion: ['养藏为主', '保持心态平和']),
  SolarTermInfo(name: '小寒', date: '一月六日', month: 1, day: 6, season: 'winter', emoji: '🥶', poem: '小寒大寒最冷时，温补阳气防寒袭', diet: ['羊肉', '生姜红糖水', '核桃'], acupoint: ['关元穴', '命门穴', '涌泉穴'], exercise: ['室内运动', '太极拳', '拉伸'], emotion: ['保持温暖', '避免情绪低落']),
  SolarTermInfo(name: '大寒', date: '一月二十日', month: 1, day: 20, season: 'winter', emoji: '🧊', poem: '大寒将至春不远，养藏温补待新年', diet: ['羊肉', '红枣', '枸杞粥'], acupoint: ['命门穴', '肾俞穴', '足三里'], exercise: ['室内运动', '太极拳', '散步'], emotion: ['保持乐观', '期待春天到来']),
];

Color getSeasonColor(String season) {
  switch (season) {
    case 'spring': return const Color(0xFF7CB342);
    case 'summer': return const Color(0xFFFF7043);
    case 'autumn': return const Color(0xFFD4613C);
    case 'winter': return const Color(0xFF5C6BC0);
    default: return const Color(0xFF7CB342);
  }
}
