import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

/// Wellness馆 - 分类Details页
/// 根据 type 展示具体内容列表
class WellnessCategoryPage extends StatelessWidget {
  final String type;
  const WellnessCategoryPage({super.key, this.type = 'food_therapy'});

  static const _categoryMeta = {
    'constitution': _Meta(Icons.favorite_rounded, 'Body Type Care', 'Discover Your Body Type — Different Approaches for Different Bodies'),
    'food_therapy': _Meta(Icons.restaurant_menu, 'Solar TermRecipes', 'Follow the Solar Term, Eat Seasonally'),
    'tea': _Meta(Icons.emoji_food_beverage, 'Wellness Tea', 'Nourish the Heart with Tea, Moisturize for Wellness'),
    'acupressure': _Meta(Icons.accessibility_new, 'MeridianAcupressure', 'Unblock Meridians, Strengthen the Body'),
    'exercise': _Meta(Icons.self_improvement, 'Traditional Qigong', 'Balance Movement and Stillness, Cultivate Within and Without'),
    'sleep': _Meta(Icons.headphones, 'Sleep Audio', 'Audio guides for pre-sleep relaxation'),
  };

  static const _items = {
    'constitution': [
      _Item('Balanced', 'Yin and Yang in harmony, well-proportioned body, radiant complexion. Easygoing and cheerful, highly adaptable.', 'Maintain regular routines and a balanced diet.'),
      _Item('Qi Deficient', 'Low energy, easily fatigued, soft voice. Prone to colds, slow recovery.', 'Recommended: astragalus, codonopsis, yam — foods that boost Qi.'),
      _Item('Yang Deficient', 'Yang deficiency, cold hands and feet, aversion to cold. Pale complexion, prefers warm foods.', 'Recommended: lamb, ginger, longan — warming nourishing foods.'),
      _Item('Yin Deficient', 'Yin deficiency, dry mouth and throat, warm palms. Often thin, prefers cold drinks.', 'Recommended: tremella, lily bulb, goji berry — foods that nourish Yin.'),
      _Item('Phlegm-Damp', 'Phlegm-damp accumulation, overweight, full abdomen. Oily skin, sticky sweat.', 'Recommended: coix seed, winter melon, lotus leaf — foods that transform phlegm and eliminate dampness.'),
      _Item('Damp-Heat', 'Damp-heat accumulation, oily face, prone to acne. Bitter taste, body heaviness.', 'Recommended: mung bean, coix seed, bitter melon — foods that clear heat and promote diuresis.'),
      _Item('Blood Stasis', 'Poor blood circulation, dull complexion, easy bruising. Dark lips, dark circles.', 'Recommended: hawthorn, black bean, vinegar — foods that invigorate Blood.'),
      _Item('Qi Stagnant', 'Qi stagnation, prone to worry and low mood. Often thin-built.', 'Recommended: rose, tangerine peel, bergamot — foods that soothe Liver Qi and relieve stagnation.'),
      _Item('Special', 'Congenital sensitivity, allergic constitution. Poor seasonal adaptation.', 'Recommended: light, balanced foods; avoid allergens.'),
    ],
    'food_therapy': [
      _Item('Chrysanthemum Tea', 'Clears heat and brightens the eyes, disperses wind-heat. Ideal for spring, relieves eye fatigue.', 'Use 5-6 Hangzhou white chrysanthemums, steep in boiling water for 5 minutes.', image: 'assets/images/foods/juhua.png'),
      _Item('Qingtuan (green rice ball)', 'Clear and Bright seasonal treat — mugwort and glutinous rice create a fragrant, soft texture.', 'Mix mugwort juice with glutinous rice flour, fill with red bean paste, steam 15 min.', image: 'assets/images/foods/qingtuan.png'),
      _Item('Mugwort', 'Warms meridians and stops bleeding, scatters cold and eliminates dampness. Pick tender mugwort in spring.', 'Can be made into mugwort cakes or mugwort egg soup.', image: 'assets/images/foods/aicao.png'),
      _Item('River Shrimp', 'High protein, low fat — tonifies Kidneys and strengthens Yang. River shrimp are at their plumpest in spring.', 'Stir-fry river shrimp or make river shrimp tofu soup — delicious and nutritious.', image: 'assets/images/foods/hexia.png'),
      _Item('River Snail', 'Clear and Bright: river snails outshine fatty goose. Clears heat, promotes diuresis, brightens eyes, and reduces jaundice.', 'Stir-fry with scallion and ginger or in savory sauce — delicious.', image: 'assets/images/foods/luosi.png'),
      _Item('Jujube Longan Porridge', 'Tonifies blood and nourishes the Heart, calms the spirit and aids sleep. Ideal for Qi-Blood deficiency and insomnia.', '10 jujubes, 15g longan flesh, 100g rice — cook together into porridge.'),
    ],
    'tea': [
      _Item('Rose Tea', 'Soothes Liver Qi and relieves stagnation, invigorates Blood and disperses stasis. Ideal for low mood and chest stuffiness.', 'Use 5-8 dried roses, steep in boiling water. May add honey to taste.'),
      _Item('Tangerine Peel Pu-erh Tea', 'Regulates Qi and strengthens the Spleen, transforms phlegm and reduces blood lipids. Ideal for indigestion.', '3g tangerine peel, 5g Pu-erh tea — steep in boiling water.'),
      _Item('Jujube Longan Tea', 'Boosts Qi and nourishes Blood, calms the spirit and steadies the mind. Ideal for Qi-Blood deficiency.', '5 jujubes, 10g longan flesh — steep in boiling water for 10 minutes.'),
      _Item('chrysanthemumGoji Tea', 'Clears Liver heat and brightens the eyes, nourishes Liver and Kidneys. Ideal for those who overuse their eyes.', '5 chrysanthemum flowers, 10g goji berry — steep in boiling water.'),
      _Item('Ginger Jujube Tea', 'Warms the middle and disperses cold, restores Yang and unblocks meridians. Ideal for those who are Yang Deficient and fear cold.', '3 slices of ginger, 5 jujubes — simmer in water for 15 minutes.'),
      _Item('Lotus Leaf Hawthorn Tea', 'Aids digestion and removes accumulation, reduces fat and aids weight loss. Ideal for Phlegm-Damp body types.', '5g dried lotus leaf, 10g hawthorn — steep in boiling water.'),
    ],
    'acupressure': [
      _Item('Hegu', 'Located in the web between thumb and index finger. Calms and relieves pain, unblocks meridians.', 'Press and knead with thumb for 3-5 minutes, moderate pressure. Relieves headache and toothache.'),
      _Item('Zusanli', 'Located four finger-widths below the outer knee. Regulates Spleen and Stomach, tonifies middle and boosts Qi.', 'Massage for 5 minutes daily to enhance immunity and improve digestion.'),
      _Item('Sanyinjiao', 'Located four finger-widths above the inner ankle. Strengthens Spleen and benefits Blood, regulates Liver and tonifies Kidneys.', 'Press and knead for 3-5 minutes. Particularly effective for gynecological health.'),
      _Item('Yongquan', 'Located in the depression at the front of the sole. Guides fire downward, nourishes Yin and benefits Kidneys.', 'Rub Yongquan 100 times before sleep to improve sleep quality.'),
      _Item('Taichong', 'Located between the first and second toes on the top of the foot. Soothes Liver Qi, clears Liver and drains fire.', 'Press and knead for 3-5 minutes. Ideal for when feeling emotionally agitated.'),
      _Item('Neiguan', 'Located three finger-widths above the wrist crease. Calms the Heart and spirit, harmonizes Stomach and descends rebellion.', 'Press for 3 minutes to relieve palpitations and nausea.'),
    ],
    'exercise': [
      _Item('Baduanjin', 'Eight movements, simple to learn. Exercises the organs, strengthens the body.', 'Practice for 15 minutes every morning — movements are gentle, breathing natural.'),
      _Item('Tai Chi', 'Cultivates both interior and exterior, blending hardness and softness. Balances Yin and Yang, harmonizes Qi and Blood.', 'Recommended: learn with a qualified instructor, practice 30 minutes daily.'),
      _Item('Wuqinxi', 'Imitates five animals: tiger, deer, bear, ape, and bird. Loosens tendons and invigorates meridians, strengthens body.', 'Practice 20 minutes daily. Note: movements should be extended naturally.'),
      _Item('Yijinjing', 'Twelve movement Qigong. Strengthens tendons and bones, cultivates the interior.', 'Suitable for those with some foundation; movements coordinated with breathing.'),
      _Item('Liuzijue', 'Uses six syllable sounds: Xu, He, Hu, Si, Chui, Xi. Exercises the five Zang and six Fu organs.', 'Practice every morning; each sound 6 times, coordinated with breathing.'),
    ],
    'sleep': [
      _Item('Rain White Noise', 'Continuous, steady rain sounds create a tranquil atmosphere to aid sleep.', 'Recommended: play 30 minutes before bed, keep volume low, set a timer to close.'),
      _Item('Guqin for Sleep', 'The distant, pure timbre of the guqin calms the spirit and soothes the body and mind.', 'Choose slow-tempo pieces such as Wild Geese Descending on the Sand.'),
      _Item('Nature Meditation', 'Guided meditation with natural sound effects — relaxes body and mind.', 'Follow the audio guidance, focus on breathing, gradually relax the whole body.'),
      _Item('Singing Bowl Therapy', 'The resonant overtones of singing bowls deeply relax the nervous system.', 'Headphones enhance the effect; can be combined with diaphragmatic breathing.'),
      _Item('Forest Stream', 'Babbling streams and birdsong — return to nature.', 'Ideal for afternoon rest or nighttime — creates a natural sleep environment.'),
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
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).t('wellness_got_it'), style: TextStyle(color: ShunShiColors.primary)))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = _categoryMeta[type] ?? _categoryMeta['food_therapy']!;
    final items = _items[type] ?? [];
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        title: Text(meta.title, style: const TextStyle(fontFamily: ShunShiTypography.serifFamily)),
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
