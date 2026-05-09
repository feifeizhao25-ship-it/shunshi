import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final textColor = isDark ? ShunShiColors.textPrimary : ShunShiColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('用户协议',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _sectionTitle('顺时（ShunShi）用户协议'),
          _body('最后更新日期：2025年5月\n生效日期：2025年5月', textColor),
          const SizedBox(height: 12),
          _sectionTitle('一、服务描述'),
          _body(
            '1.1 顺时（ShunShi）是一款基于中医养生理论的 AI 健康管理辅助工具。应用提供以下服务：\n'
            '• 基于二十四节气的个性化养生建议\n'
            '• 中医体质辨识测试与分析报告\n'
            '• AI 养生对话与咨询\n'
            '• 饮食、运动、穴位等养生方案推荐\n'
            '• 健康打卡与数据记录\n'
            '• 家庭养生空间（成员间共享）\n\n'
            '1.2 本应用通过订阅制提供增值服务（顺时 Pro），具体权益以应用内说明为准。\n\n'
            '1.3 我们保留随时修改、暂停或终止任何服务功能的权利，并将提前通知用户。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('二、用户行为规范'),
          _body(
            '2.1 您同意不会利用本应用进行以下行为：\n'
            '• 发布违法、虚假、侵权或不当内容\n'
            '• 冒充他人或虚假陈述身份\n'
            '• 上传含有恶意代码的内容\n'
            '• 尝试未授权访问系统或他人数据\n'
            '• 使用自动化工具批量操作\n'
            '• 将服务用于任何违法或侵权目的\n\n'
            '2.2 违规处理\n'
            '如发现违规行为，我们有权采取以下措施：\n'
            '• 警告\n'
            '• 限制或暂停账户功能\n'
            '• 终止服务并删除账户\n'
            '• 追究法律责任',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('三、知识产权'),
          _body(
            '3.1 所有权利归属\n'
            '本应用的所有内容，包括但不限于文字、图片、图标、界面设计、算法、AI 模型输出、音视频内容，均受中华人民共和国著作权法及相关国际知识产权条约保护。\n\n'
            '3.2 用户内容\n'
            '您在应用中输入的内容（对话、打卡记录等）归您所有。您授予我们非独占的、全球性的许可，以处理和存储这些内容来提供服务。\n\n'
            '3.3 限制\n'
            '未经书面授权，您不得：\n'
            '• 复制、修改、分发应用的任何部分\n'
            '• 对应用进行逆向工程或反编译\n'
            '• 将应用内容用于商业目的',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('四、免责声明'),
          _body(
            '4.1 本应用提供的所有内容（包括但不限于养生建议、节气调养方案、体质分析、AI 对话回答）均基于传统中医理论和 AI 算法生成，仅供健康养生参考，不构成医疗诊断、治疗或处方建议。\n\n'
            '4.2 本应用不是医疗机构，不提供医疗服务。对于因使用本应用内容而导致的任何健康问题或损失，开发者不承担直接或间接责任。\n\n'
            '4.3 本应用按"现状"提供服务，不作任何明示或暗示的保证，包括但不限于适销性、特定用途的适用性和非侵权性。\n\n'
            '4.4 对于因不可抗力、网络故障、系统维护等原因导致的服务中断，我们不承担责任。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('五、服务变更与终止'),
          _body(
            '5.1 我们有权根据业务需要调整服务内容、功能或定价，并通过应用内公告、推送通知等方式告知用户。\n\n'
            '5.2 您可以随时注销账户以终止使用服务。注销后：\n'
            '• 订阅服务将自动取消\n'
            '• 个人数据将在 30 天内删除（详见隐私政策）\n\n'
            '5.3 在以下情况下，我们有权终止向您提供服务：\n'
            '• 违反本协议\n'
            '• 账户长期未使用（连续 12 个月）\n'
            '• 法律法规要求',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('六、争议解决'),
          _body(
            '6.1 本协议适用中华人民共和国法律。\n\n'
            '6.2 因本协议产生的争议，双方应首先友好协商。协商不成的，任何一方均可向开发者所在地有管辖权的人民法院提起诉讼。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('七、其他'),
          _body(
            '7.1 本协议构成您与开发者之间关于使用本应用的完整协议。\n\n'
            '7.2 本协议的任何条款如被认定为无效或不可执行，不影响其他条款的效力。\n\n'
            '7.3 我们未行使任何权利不构成对该权利的放弃。\n\n'
            '如有疑问，请联系：legal@shunshi.app',
            textColor,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.textPrimary,
        ),
      ),
    );
  }

  Widget _body(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: color, height: 1.8),
    );
  }
}
