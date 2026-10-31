/// 节气封面插画资源映射（assets/images/solar/<pinyin>.webp）。
const Map<String, String> _solarCoverPinyin = {
  '立春': 'lichun', '雨水': 'yushui', '惊蛰': 'jingzhe', '春分': 'chunfen', '清明': 'qingming', '谷雨': 'guyu',
  '立夏': 'lixia', '小满': 'xiaoman', '芒种': 'mangzhong', '夏至': 'xiazhi', '小暑': 'xiaoshu', '大暑': 'dashu',
  '立秋': 'liqiu', '处暑': 'chushu', '白露': 'bailu', '秋分': 'qiufen', '寒露': 'hanlu', '霜降': 'shuangjiang',
  '立冬': 'lidong', '小雪': 'xiaoxue', '大雪': 'daxue', '冬至': 'dongzhi', '小寒': 'xiaohan', '大寒': 'dahan',
};

/// 返回节气封面资源路径；未知节气时返回 [fallback]。
String solarCoverAsset(String? termName, {String fallback = 'assets/images/solar/lichun.webp'}) {
  final p = termName == null ? null : _solarCoverPinyin[termName];
  return p == null ? fallback : 'assets/images/solar/$p.webp';
}
