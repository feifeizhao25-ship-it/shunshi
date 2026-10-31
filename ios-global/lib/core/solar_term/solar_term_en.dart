// English names for the 24 solar terms. The keys are the canonical Chinese term names from the generated
// solar_term_table.dart (data keys, never shown to the user); every value shown in the app is English.
import 'solar_term_table.dart';

const Map<String, (String, String)> kSolarTermEn = {
  '小寒': ('Minor Cold', 'Deep winter. Keep warm, sleep a little longer and favour warm, cooked meals.'),
  '大寒': ('Major Cold', 'The coldest stretch of the year. Stay warm and keep gentle indoor movement.'),
  '立春': ('Start of Spring', 'Days lengthen. Ease into more outdoor light and lighter meals.'),
  '雨水': ('Rain Water', 'Damp, changeable weather. Layer clothing and keep a steady routine.'),
  '惊蛰': ('Awakening of Insects', 'Spring energy rises. A good time to restart regular exercise.'),
  '春分': ('Spring Equinox', 'Day and night are equal. Aim for balanced sleep and meals.'),
  '清明': ('Clear and Bright', 'Fresh, mild weather. Walk outdoors and enjoy seasonal greens.'),
  '谷雨': ('Grain Rain', 'Late spring rain. Keep active and avoid heavy, greasy food.'),
  '立夏': ('Start of Summer', 'Warmer days begin. Hydrate well and keep meals light.'),
  '小满': ('Grain Buds', 'Early summer humidity. Stay hydrated and rest in the heat of midday.'),
  '芒种': ('Grain in Ear', 'Busy, humid days. Keep a regular sleep schedule.'),
  '夏至': ('Summer Solstice', 'The longest day. Get morning light and avoid the midday sun.'),
  '小暑': ('Minor Heat', 'Heat builds. Drink water steadily and choose cooling seasonal produce.'),
  '大暑': ('Major Heat', 'Peak heat. Slow down, rest well and stay cool.'),
  '立秋': ('Start of Autumn', 'Heat begins to ease. Gradually return to fuller routines.'),
  '处暑': ('End of Heat', 'Cooler evenings. A good time for longer walks.'),
  '白露': ('White Dew', 'Dry air arrives. Keep skin and throat hydrated.'),
  '秋分': ('Autumn Equinox', 'Day and night are equal again. Keep sleep and meals regular.'),
  '寒露': ('Cold Dew', 'Mornings turn chilly. Add a layer and warm drinks.'),
  '霜降': ('Frost Descent', 'Late autumn. Keep warm, sleep earlier and enjoy warm seasonal food.'),
  '立冬': ('Start of Winter', 'Winter begins. Prioritise rest and warm, nourishing meals.'),
  '小雪': ('Minor Snow', 'Cold sets in. Get daylight when you can to support mood.'),
  '大雪': ('Major Snow', 'Deep cold. Keep moving indoors and stay warm.'),
  '冬至': ('Winter Solstice', 'The shortest day. Rest well and seek morning light.'),
};

/// Today's solar term in English (Beijing calendar). Returns null outside the table range.
(String, String)? currentSolarTermEn() {
  final zh = currentSolarTermName();
  return zh == null ? null : kSolarTermEn[zh];
}
