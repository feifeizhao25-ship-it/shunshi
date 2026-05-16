// Solar term data model + 24 solar terms mock data
// Extracted from solar_term_page.dart for maintainability

import 'package:flutter/material.dart';
import '../../../../core/network/api_singleton.dart';

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
      case 'spring': return 'Spring';
      case 'summer': return 'Summer';
      case 'autumn': return 'Autumn';
      case 'winter': return 'Winter';
      default: return '';
    }
  }

  String get seasonShort {
    switch (season) {
      case 'spring': return 'Spr';
      case 'summer': return 'Sum';
      case 'autumn': return 'Aut';
      case 'winter': return 'Win';
      default: return '';
    }
  }
}

const List<SolarTermInfo> kAllSolarTerms = [
  SolarTermInfo(name: 'Start of Spring', date: 'Feb 4', month: 2, day: 4, season: 'spring', emoji: '🌱', poem: 'The east wind brings warmth as Spring begins, all things revive and flowers bloom', diet: ['Scallion ginger soup', 'Leek scrambled eggs', 'Pungent-sweet foods'], acupoint: ['Taichong', 'Zusanli', 'Fengchi'], exercise: ['Walking', 'Tai Chi', 'Stretching'], emotion: ['Stay cheerful', 'Connect with friends']),
  SolarTermInfo(name: 'Rain Water', date: 'Feb 19', month: 2, day: 19, season: 'spring', emoji: '🌧️', poem: 'Good rain knows the season, when Spring arrives it brings growth', diet: ['Millet porridge', 'Jujube yam', 'Honey water'], acupoint: ['Sanyinjiao', 'Yinlingquan', 'Taibai'], exercise: ['Jogging', 'Yoga', 'Baduanjin'], emotion: ['Stay calm', 'Avoid excessive worry']),
  SolarTermInfo(name: 'Awakening', date: 'Mar 6', month: 3, day: 6, season: 'spring', emoji: '⚡', poem: 'Spring thunder sounds, all things grow — time for seasonal wellness', diet: ['Pear', 'Spinach', 'Shepherd\'s purse'], acupoint: ['Taichong', 'Hegu', 'Quchi'], exercise: ['Outdoors', 'Kite flying', 'Tai Chi'], emotion: ['Liver soothing', 'Stay optimistic']),
  SolarTermInfo(name: 'Spring Equinox', date: 'Mar 21', month: 3, day: 21, season: 'spring', emoji: '🌸', poem: 'Spring Equinox — day and night equal, Yin-Yang in harmony for wellness', diet: ['Spring bamboo shoots', 'Toona', 'Strawberry'], acupoint: ['Qimen', 'Taichong', 'Zusanli'], exercise: ['Picnic', 'Jogging', 'Yoga'], emotion: ['Stay emotionally stable', 'Avoid extreme joy or sadness']),
  SolarTermInfo(name: 'Clear and Bright', date: 'Apr 5', month: 4, day: 5, season: 'spring', emoji: '🍃', poem: 'Clear and Bright brings spring showers, perfect time for outings and flower viewing', diet: ['Green rice ball', 'Qingming snail', 'Green tea'], acupoint: ['Taichong', 'Qimen', 'Danyu'], exercise: ['Hiking', 'Mountain climbing', 'Kite flying'], emotion: ['Soothe emotions', 'Connect with nature']),
  SolarTermInfo(name: 'Grain Rain', date: 'Apr 20', month: 4, day: 20, season: 'spring', emoji: '🌾', poem: 'Before and after Grain Rain, plant melons and beans — focus on strengthening the spleen and eliminating dampness', diet: ['Toona', 'Grain Rain tea', 'Coix seed porridge'], acupoint: ['Yinlingquan', 'Zusanli', 'Taibai'], exercise: ['Walking', 'Baduanjin', 'Tai Chi'], emotion: ['Balance emotions', 'Avoid overthinking']),
  SolarTermInfo(name: 'Start of Summer', date: 'May 6', month: 5, day: 6, season: 'summer', emoji: '☀️', poem: 'Start of Summer — focus on heart health, light diet for peace', diet: ['Mung bean soup', 'Lotus seed porridge', 'Bitter melon'], acupoint: ['Neiguan', 'Shenmen', 'Xinyu'], exercise: ['Swimming', 'Morning walk', 'Yoga'], emotion: ['Nourish heart and calm mind', 'Avoid irritability']),
  SolarTermInfo(name: 'Grain Buds', date: 'May 21', month: 5, day: 21, season: 'summer', emoji: '🌡️', poem: 'Grain Buds not yet full, all things thriving — clearing heat and eliminating dampness is key', diet: ['Winter melon', 'Sponge gourd', 'Mung bean'], acupoint: ['Yinlingquan', 'Zusanli', 'Zhongwan'], exercise: ['Walking', 'Swimming', 'Tai Chi'], emotion: ['Stay calm', 'Avoid restlessness']),
  SolarTermInfo(name: 'Grain in Ear', date: 'Jun 6', month: 6, day: 6, season: 'summer', emoji: '🌿', poem: 'Grain in Ear — busy planting but don\'t forget wellness, clearing heat prevents summer fatigue', diet: ['Watermelon', 'Sour plum soup', 'Lotus leaf porridge'], acupoint: ['Quchi', 'Hegu', 'Dazhui'], exercise: ['Morning exercise', 'Swimming', 'Stretching'], emotion: ['Clear heat and reduce fire', 'Stay happy']),
  SolarTermInfo(name: 'Summer Solstice', date: 'Jun 21', month: 6, day: 21, season: 'summer', emoji: '🌞', poem: 'Summer Solstice — Yang peaks and Yin begins, protect the heart and Yang for peace', diet: ['Cold noodles', 'Mung bean soup', 'Lotus seed soup'], acupoint: ['Neiguan', 'Shenmen', 'Zusanli'], exercise: ['Morning walk', 'Swimming', 'Avoid midday sun exercise'], emotion: ['Nourish heart and calm mind', 'Avoid over-excitement']),
  SolarTermInfo(name: 'Minor Heat', date: 'Jul 7', month: 7, day: 7, season: 'summer', emoji: '🔥', poem: 'Minor Heat brings heat — prevent heatstroke, light diet protects the spleen and stomach', diet: ['Watermelon', 'Cucumber', 'Bitter melon'], acupoint: ['Baihui', 'Neiguan', 'Zusanli'], exercise: ['Morning or evening exercise', 'Swimming', 'Yoga'], emotion: ['Calm mind beats the heat', 'Avoid emotional swings']),
  SolarTermInfo(name: 'Major Heat', date: 'Jul 23', month: 7, day: 23, season: 'summer', emoji: '🌡️', poem: 'Major Heat — hottest time of year, avoiding heat and nourishing Yin is the right time', diet: ['Mung bean soup', 'Coix seed porridge', 'Lotus leaf tea'], acupoint: ['Yongquan', 'Taixi', 'Shenyu'], exercise: ['Indoor exercise', 'Swimming', 'Morning walk'], emotion: ['Calm heart and vital energy', 'Avoid rage and agitation']),
  SolarTermInfo(name: 'Start of Autumn', date: 'Aug 7', month: 8, day: 7, season: 'autumn', emoji: '🍂', poem: 'Start of Autumn — focus on lung nourishment, moisten dryness and generate fluids for health', diet: ['Pear', 'Tremella', 'Lily bulb'], acupoint: ['Feiyu', 'Lieque', 'Taiyuan'], exercise: ['Hiking', 'Jogging', 'Tai Chi'], emotion: ['Gather vital energy', 'Avoid grief that injures the lung']),
  SolarTermInfo(name: 'End of Heat', date: 'Aug 23', month: 8, day: 23, season: 'autumn', emoji: '🌤️', poem: 'End of Heat — cool weather feels great in Autumn, remember to nourish Yin and moisten dryness', diet: ['Lily bulb porridge', 'Lotus seed soup', 'Honey'], acupoint: ['Taixi', 'Feiyu', 'Sanyinjiao'], exercise: ['Walking', 'Hiking', 'Yoga'], emotion: ['Stay emotionally balanced', 'Avoid autumn melancholy']),
  SolarTermInfo(name: 'White Dew', date: 'Sep 8', month: 9, day: 8, season: 'autumn', emoji: '💧', poem: 'White Dew and Autumn Equinox — nights grow cooler, moisten the lung is most appropriate', diet: ['Pear', 'Tremella soup', 'Lotus root'], acupoint: ['Feiyu', 'Taiyuan', 'Lieque'], exercise: ['Jogging', 'Hiking', 'Tai Chi'], emotion: ['Gather emotions', 'Stay mentally balanced']),
  SolarTermInfo(name: 'Autumn Equinox', date: 'Sep 23', month: 9, day: 23, season: 'autumn', emoji: '🍁', poem: 'Autumn Equinox — day and night divide again, Yin-Yang balance nurtures body and mind', diet: ['Yam', 'Lily bulb', 'Honey'], acupoint: ['Zusanli', 'Sanyinjiao', 'Taixi'], exercise: ['Walking', 'Yoga', 'Tai Chi'], emotion: ['Harmonize emotions', 'Keep a peaceful mindset']),
  SolarTermInfo(name: 'Cold Dew', date: 'Oct 8', month: 10, day: 8, season: 'autumn', emoji: '❄️', poem: 'Cold Dew — gradually turns cold, keep warm and moisten dryness to protect lung and liver', diet: ['Sesame', 'Walnut', 'Tremella'], acupoint: ['Feiyu', 'Shenyu', 'Taixi'], exercise: ['Hiking', 'Jogging', 'Tai Chi'], emotion: ['Prevent autumn sadness', 'Stay optimistic']),
  SolarTermInfo(name: 'Frost', date: 'Oct 23', month: 10, day: 23, season: 'autumn', emoji: '🧊', poem: 'Frost brings the cold — tonify the spleen and stomach, a good time for winter tonic', diet: ['Persimmon', 'Chestnut', 'Lamb'], acupoint: ['Zusanli', 'Zhongwan', 'Piyu'], exercise: ['Hiking', 'Jogging', 'Tai Chi'], emotion: ['Prevent melancholy', 'Stay cheerful']),
  SolarTermInfo(name: 'Start of Winter', date: 'Nov 7', month: 11, day: 7, season: 'winter', emoji: '❄️', poem: 'Start of Winter — tonify and store essence, warm tonification ensures peace', diet: ['Lamb soup', 'Black sesame', 'Walnut'], acupoint: ['Shenyu', 'Mingmen', 'Taixi'], exercise: ['Tai Chi', 'Walking', 'Indoor exercise'], emotion: ['Focus on storage', 'Stay calm']),
  SolarTermInfo(name: 'Minor Snow', date: 'Nov 22', month: 11, day: 22, season: 'winter', emoji: '🌨️', poem: 'Minor Snow — warm tonify the kidney, sleep early and rise late to nurture Yang', diet: ['Lamb', 'Black bean', 'Longan'], acupoint: ['Shenyu', 'Yongquan', 'Mingmen'], exercise: ['Tai Chi', 'Indoor exercise', 'Walking'], emotion: ['Stay optimistic', 'Avoid winter depression']),
  SolarTermInfo(name: 'Major Snow', date: 'Dec 7', month: 12, day: 7, season: 'winter', emoji: '⛄', poem: 'Major Snow brings heavy cold — warm Yang and tonify kidney must be clear', diet: ['Lamb', 'Chestnut', 'Goji berry porridge'], acupoint: ['Mingmen', 'Shenyu', 'Guanyuan'], exercise: ['Indoor exercise', 'Tai Chi', 'Stretching'], emotion: ['Focus on storage', 'Stay peaceful']),
  SolarTermInfo(name: 'Winter Solstice', date: 'Dec 22', month: 12, day: 22, season: 'winter', emoji: '🌙', poem: 'Winter Solstice — Yang begins to rise, tonify and store is most timely', diet: ['Dumplings', 'Lamb soup', 'Glutinous rice ball'], acupoint: ['Guanyuan', 'Mingmen', 'Yongquan'], exercise: ['Indoor exercise', 'Tai Chi', 'Walking'], emotion: ['Focus on storage', 'Stay balanced']),
  SolarTermInfo(name: 'Minor Cold', date: 'Jan 6', month: 1, day: 6, season: 'winter', emoji: '🥶', poem: 'Minor Cold and Major Cold — coldest time, warm tonify Yang and prevent cold attacks', diet: ['Lamb', 'Ginger brown sugar water', 'Walnut'], acupoint: ['Guanyuan', 'Mingmen', 'Yongquan'], exercise: ['Indoor exercise', 'Tai Chi', 'Stretching'], emotion: ['Stay warm', 'Avoid low mood']),
  SolarTermInfo(name: 'Major Cold', date: 'Jan 20', month: 1, day: 20, season: 'winter', emoji: '🧊', poem: 'Major Cold approaches Spring is near, store and warm tonify to welcome the New Year', diet: ['Lamb', 'Jujube', 'Goji berry porridge'], acupoint: ['Mingmen', 'Shenyu', 'Zusanli'], exercise: ['Indoor exercise', 'Tai Chi', 'Walking'], emotion: ['Stay optimistic', 'Look forward to Spring']),
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
