import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

/// 养生馆 - 分类详情页
/// 根据 type 展示具体内容列表
class WellnessCategoryPage extends StatelessWidget {
  final String type;
  const WellnessCategoryPage({super.key, this.type = 'food_therapy'});

  static const _categoryMeta = {
    'constitution': _Meta(Icons.favorite_rounded, 'Constitution care', 'Learn the nine constitutions and care for yourself accordingly'),
    'food_therapy': _Meta(Icons.restaurant_menu, 'Seasonal recipes', 'Eat with the seasons'),
    'tea': _Meta(Icons.emoji_food_beverage, 'Wellness teas', 'Nourish the heart with tea and moisten dryness'),
    'acupressure': _Meta(Icons.accessibility_new, 'Meridians & acupoints', 'Open the meridians, stay strong'),
    'exercise': _Meta(Icons.self_improvement, 'Traditional practices', 'Balance movement and stillness, inside and out'),
    'sleep': _Meta(Icons.headphones, 'Sleep audio', 'Guided audio to relax before bed'),
  };

  static const _items = {
    'constitution': [
      _Item('Balanced', 'Yin and yang, qi and blood are in harmony; build is moderate and complexion glows. Easygoing and cheerful, adapts well.', 'Keep a regular routine and eat a balanced diet.'),
      _Item('Qi Deficiency', 'Low vital energy, easily tired, weak voice. Catches colds easily and recovers slowly.', 'Good foods: astragalus, codonopsis, Chinese yam and other qi-tonifying foods.'),
      _Item('Yang Deficiency', 'Insufficient yang; cold hands and feet, dislikes cold. Pale complexion, prefers warm food and drink.', 'Good foods: lamb, ginger, longan and other warming foods.'),
      _Item('Yin Deficiency', 'Low yin fluids; dry mouth and throat, warm palms and soles. Leaner build, prefers cold drinks.', 'Good foods: tremella, lily bulb, goji berry and other yin-nourishing foods.'),
      _Item('Phlegm-Dampness', 'Phlegm and dampness accumulate; heavier build, full abdomen. Oily face, sweats a lot and is sticky.', 'Good foods: coix seed, winter melon, lotus leaf and other foods that resolve phlegm and dampness.'),
      _Item('Damp-Heat', 'Damp-heat inside; oily face, prone to acne. Bitter, dry mouth, heavy and sleepy.', 'Good foods: mung bean, coix seed, bitter melon and other foods that clear heat and dampness.'),
      _Item('Blood Stasis', 'Blood flows poorly; dull complexion, prone to bruising. Dark purple lips and dark circles.', 'Good foods: hawthorn, black beans, vinegar and other foods that move blood and clear stasis.'),
      _Item('Qi Stagnation', 'Qi flow is stuck; low mood, anxious and fragile. Mostly a slim build.', 'Good foods: rose, tangerine peel, finger citron and other foods that soothe the liver and ease stagnation.'),
      _Item('Special Constitution', 'Inherited sensitivity; allergic constitution. Adapts poorly to seasons and old problems flare easily.', 'Eat light, balanced food and avoid allergens.'),
    ],
    'food_therapy': [
      _Item('Chrysanthemum tea', 'Clears heat and brightens the eyes. Good in spring to relieve eye strain.', 'Steep 5–6 Hangzhou chrysanthemum flowers in boiling water for 5 minutes.', image: 'assets/images/foods/juhua.png'),
      _Item('Qingtuan (green rice balls)', 'A Qingming seasonal sweet: mugwort and glutinous rice, fragrant and soft.', 'Mix mugwort juice into glutinous rice flour, wrap sweet bean paste, steam for 15 minutes.', image: 'assets/images/foods/qingtuan.png'),
      _Item('Mugwort', 'Warms the channels and stops bleeding, dispels cold and dampness. Pick fresh tender mugwort in spring.', 'Can be made into mugwort cakes or mugwort egg soup.', image: 'assets/images/foods/aicao.png'),
      _Item('River shrimp', 'High protein, low fat; supports the kidneys. River shrimp are at their best in spring.', 'Stir-fried river shrimp or river shrimp and tofu soup — tasty and nutritious.', image: 'assets/images/foods/hexia.png'),
      _Item('Snails', 'Qingming snails are said to be fatter than goose. Clear heat, promote urination, brighten eyes.', 'Stir-fry with scallion and ginger, or in bean sauce — fresh and tasty.', image: 'assets/images/foods/luosi.png'),
      _Item('Red date and longan congee', 'Nourishes blood and the heart, calms the mind and helps sleep. Good for low qi and blood and for insomnia.', '10 red dates, 15 g longan flesh and 100 g rice cooked into congee.'),
    ],
    'tea': [
      _Item('Rose tea', 'Soothes the liver, eases stagnation and moves blood. Good for low mood and a tight chest.', 'Steep 5–8 dried rose buds in boiling water; add honey if you like.'),
      _Item('Tangerine peel pu-erh', 'Regulates qi, supports digestion and reduces lipids. Good for indigestion.', '3 g dried tangerine peel and 5 g pu-erh tea, steeped in boiling water.'),
      _Item('Red date and longan tea', 'Boosts qi and nourishes blood, calms the spirit. Good for deficiency of both qi and blood.', '5 red dates and 10 g longan flesh, steeped in boiling water for 10 minutes.'),
      _Item('Chrysanthemum and goji tea', 'Clears the liver and brightens the eyes, nourishes the liver and kidneys. Good after long screen time.', '5 chrysanthemum flowers and 10 g goji berries, steeped in boiling water.'),
      _Item('Ginger and red date tea', 'Warms the middle and dispels cold. Good if you are cold-prone with low yang.', '3 slices of ginger and 5 red dates, simmered in water for 15 minutes.'),
      _Item('Lotus leaf and hawthorn tea', 'Aids digestion and reduces lipids. Good for a phlegm-dampness constitution.', '5 g dried lotus leaf and 10 g hawthorn, steeped in boiling water.'),
    ],
    'acupressure': [
      _Item('Hegu (LI4)', 'On the back of the hand, in the web between thumb and index finger. Calms and relieves pain, opens the channels.', 'Press with the thumb for 3–5 minutes with moderate pressure. May ease headaches and toothache.'),
      _Item('Zusanli (ST36)', 'Four finger-widths below the outer knee eye. Regulates the spleen and stomach and tonifies qi.', 'Press for 5 minutes a day to support immunity and digestion.'),
      _Item('Sanyinjiao (SP6)', 'Four finger-widths above the inner ankle bone. Supports the spleen, nourishes blood, balances liver and kidney.', 'Press with the thumb for 3–5 minutes; especially helpful for women\'s health.'),
      _Item('Yongquan (KI1)', 'In the hollow at the front of the sole. Draws fire downward and nourishes yin and kidneys.', 'Rub Yongquan 100 times before bed to help sleep.'),
      _Item('Taichong (LV3)', 'On the top of the foot between the first and second toes. Soothes the liver and clears liver heat.', 'Press for 3–5 minutes; useful when you feel irritable.'),
      _Item('Neiguan (PC6)', 'Three finger-widths above the wrist crease. Calms the heart and settles the stomach.', 'Press for 3 minutes to ease palpitations and nausea.'),
    ],
    'exercise': [
      _Item('Baduanjin', 'Eight simple movements that are easy to learn. Regulate the organs and build strength.', 'Practise for 15 minutes each morning, with slow movements and natural breathing.'),
      _Item('Tai chi', 'Works inside and out, firm yet gentle. Balances yin and yang and harmonises qi and blood.', 'Learn with a qualified teacher and practise 30 minutes a day.'),
      _Item('Wuqinxi (Five Animals)', 'Imitates the tiger, deer, bear, ape and bird. Loosens the sinews and strengthens the body.', 'Practise 20 minutes a day, keeping the movements open and natural.'),
      _Item('Yijinjing (Muscle-Tendon Change)', 'A twelve-posture guided practice. Strengthens sinews and bones and builds inner vitality.', 'Suited to those with some experience; coordinate movement with breath.'),
      _Item('Six Healing Sounds', 'Six sounds — xu, he, hu, si, chui, xi — to regulate the five organs and six viscera.', 'Practise at dawn, six repetitions per sound, with the breath.'),
    ],
    'sleep': [
      _Item('Rain white noise', 'A steady rain sound creates a calm atmosphere and helps you fall asleep.', 'Play it 30 minutes before bed at low volume with a timer.'),
      _Item('Guqin for sleep', 'The guqin\'s deep, distant tone calms the mind and eases body and spirit.', 'Choose slow pieces such as "Wild Geese Landing on the Sandbank".'),
      _Item('Nature meditation', 'Guided meditation with nature sounds to relax body and mind.', 'Follow the voice guidance, focus on your breath and relax gradually.'),
      _Item('Singing bowl therapy', 'The overtones of singing bowls deeply relax the nervous system.', 'Better with headphones; pair with belly breathing.'),
      _Item('Forest stream', 'A babbling brook and birdsong, returning to nature.', 'Good for naps or night-time; creates a natural sleep setting.'),
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
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it', style: TextStyle(color: ShunShiColors.primary)))],
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
