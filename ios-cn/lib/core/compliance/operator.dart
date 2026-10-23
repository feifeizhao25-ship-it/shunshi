/// 国内版运营主体与备案公示。
///
/// 编号用编译参数传入，不写进仓库：
/// `--dart-define=SHUNSHI_ICP_NUMBER=...`
/// `--dart-define=SHUNSHI_APP_FILING_NUMBER=...`
/// `--dart-define=SHUNSHI_AI_FILING_NUMBER=...`
class DomesticOperator {
  static const name = '北京艾瑞见时科技有限公司';

  static const icpNumber = String.fromEnvironment('SHUNSHI_ICP_NUMBER');
  static const appFilingNumber = String.fromEnvironment('SHUNSHI_APP_FILING_NUMBER');
  static const aiFilingNumber = String.fromEnvironment('SHUNSHI_AI_FILING_NUMBER');

  static String line(String label, String value) =>
      value.isEmpty ? '$label：核准后公示' : '$label：$value';
}
