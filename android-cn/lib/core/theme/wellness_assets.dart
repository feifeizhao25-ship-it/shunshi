// lib/core/theme/wellness_assets.dart
//
// 养生内容分类图片映射 — 根据内容 type 自动匹配本地 asset 图片

import 'dart:math';
import '../../data/acupoint_images.dart';

/// 根据内容 type 返回一个随机本地 asset 图片路径
/// 用于没有 image_url 或图片加载失败时的 fallback
class WellnessAssets {
  static const _typeImages = <String, List<String>>{
    'food_therapy': [
      'assets/images/wellness/food_yam_porridge.jpg',
      'assets/images/wellness/food_lotus_soup.jpg',
      'assets/images/wellness/food_red_bean_porridge.jpg',
      'assets/images/wellness/food_medicine_bowl.jpg',
      'assets/images/wellness/food_spring_salad.jpg',
      'assets/images/wellness/food_winter_stew.jpg',
    ],
    'recipe': [
      'assets/images/wellness/food_yam_porridge.jpg',
      'assets/images/wellness/food_lotus_soup.jpg',
      'assets/images/wellness/food_medicine_bowl.jpg',
    ],
    'tea': [
      'assets/images/wellness/tea_green_tea.jpg',
      'assets/images/wellness/tea_goji_chrysanthemum.jpg',
      'assets/images/wellness/tea_hawthorn.jpg',
      'assets/images/wellness/tea_chamomile.jpg',
      'assets/images/wellness/tea_longan.jpg',
      'assets/images/wellness/tea_rose.jpg',
    ],
    'exercise': [
      'assets/images/wellness/exercise_yoga_nature.jpg',
      'assets/images/wellness/exercise_taichi.jpg',
      'assets/images/wellness/exercise_baduanjin.jpg',
      'assets/images/wellness/exercise_morning_stretch.jpg',
      'assets/images/wellness/exercise_walking.jpg',
      'assets/images/wellness/exercise_sleep_relax.jpg',
    ],
    'acupoint': [
      'assets/images/wellness/acupoint_hand_massage.jpg',
      'assets/images/wellness/acupoint_foot_reflexology.jpg',
    ],
    'acupressure': [
      'assets/images/wellness/acupoint_hand_massage.jpg',
      'assets/images/wellness/acupoint_foot_reflexology.jpg',
    ],
    'sleep_tip': [
      'assets/images/wellness/sleep_quality.jpg',
      'assets/images/wellness/sleep_pillow_moon.jpg',
      'assets/images/wellness/sleep_herbal_pillow.jpg',
    ],
    'emotion': [
      'assets/images/wellness/emotion_meditation.jpg',
      'assets/images/wellness/emotion_meditation_bowl.jpg',
      'assets/images/wellness/emotion_journal_writing.jpg',
    ],
    'tips': [
      'assets/images/wellness/wellness_herbs.jpg',
      'assets/images/wellness/wellness_seasonal.jpg',
    ],
    'solar_term': [
      'assets/images/wellness/wellness_seasonal.jpg',
      'assets/images/wellness/wellness_herbs.jpg',
    ],
  };

  /// 根据 type 和可选的 id 获取确定性图片路径
  static String getImageForType(String type, [String? id]) {
    final images = _typeImages[type] ?? _typeImages['tips']!;
    if (images.isEmpty) return images.first;
    if (id != null && id.isNotEmpty) {
      final index = id.hashCode.abs() % images.length;
      return images[index];
    }
    return images[Random().nextInt(images.length)];
  }

  /// 根据穴位名称查找已有穴位图
  static String? getAcupointImage(String acupointName) {
    return AcupointImages.getImage(acupointName);
  }

  /// 获取所有通用养生图片
  static const List<String> generalImages = [
    'assets/images/wellness/wellness_herbs.jpg',
    'assets/images/wellness/wellness_seasonal.jpg',
  ];
}
