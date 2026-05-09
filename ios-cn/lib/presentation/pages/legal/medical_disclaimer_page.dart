import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class MedicalDisclaimerPage extends StatelessWidget {
  const MedicalDisclaimerPage({super.key});

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
        title: const Text('医疗免责声明',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _sectionTitle('医疗免责声明'),
          _body('最后更新日期：2025年5月', textColor),
          const SizedBox(height: 16),
          _warningCard(),
          const SizedBox(height: 16),
          _sectionTitle('一、服务性质说明'),
          _body(
            '1.1 顺时（ShunShi）是一款基于传统中医养生理论和人工智能技术的健康管理辅助工具。\n\n'
            '1.2 本应用提供的所有内容，包括但不限于：\n'
            '• 节气养生建议\n'
            '• 体质辨识分析\n'
            '• 饮食、运动、穴位推荐\n'
            '• AI 对话回答\n\n'
            '均为基于传统养生知识的信息参考，不构成医疗诊断、治疗或处方建议。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('二、不构成医疗建议'),
          _body(
            '2.1 本应用提供的养生建议不能替代以下专业医疗服务：\n'
            '• 医生的诊断或治疗方案\n'
            '• 专业医疗机构的检查或检验\n'
            '• 药物处方或用药指导\n'
            '• 心理治疗或心理咨询\n'
            '• 任何形式的医疗程序\n\n'
            '2.2 AI 生成的内容可能存在不准确或不适用于您个人情况的情况。在做出任何健康相关决策前，请务必咨询合格的医疗专业人员。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('三、特殊人群提示'),
          _body(
            '3.1 孕妇及哺乳期女性\n'
            '• 部分养生建议（如穴位按压、药膳食疗）可能不适用于孕期\n'
            '• 使用本应用前请务必咨询产科医生\n'
            '• 如出现任何不适，请立即停止使用并就医\n\n'
            '3.2 慢性病患者\n'
            '• 患有高血压、糖尿病、心脏病等慢性疾病的用户，应在医生指导下使用本应用\n'
            '• 本应用的养生建议不能替代或修改医生制定的治疗方案\n'
            '• 不要根据本应用的建议自行调整药物剂量\n\n'
            '3.3 术后康复期\n'
            '• 术后恢复期用户应严格遵循医嘱\n'
            '• 运动和饮食建议需与主治医生确认后再执行\n\n'
            '3.4 儿童\n'
            '• 本应用不面向 14 周岁以下儿童\n'
            '• 青少年使用应在监护人陪同和指导下进行',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('四、紧急情况'),
          _body(
            '如出现以下情况，请立即拨打 120 急救电话或前往最近的医疗机构：\n\n'
            '• 胸痛、呼吸困难\n'
            '• 严重出血或外伤\n'
            '• 突发剧烈头痛、意识模糊\n'
            '• 严重过敏反应（呼吸困难、肿胀）\n'
            '• 高烧不退（39°C 以上）\n'
            '• 其他任何危及生命的症状\n\n'
            '本应用不提供紧急医疗服务，不能用于处理紧急健康状况。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('五、责任限制'),
          _body(
            '5.1 您理解并同意，因使用本应用的内容导致的任何直接或间接损失，开发者不承担责任。\n\n'
            '5.2 您有责任根据自身健康状况合理使用本应用，并在必要时寻求专业医疗帮助。\n\n'
            '5.3 如您因本应用的养生建议而产生健康疑虑，请立即咨询医生。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('六、联系方式'),
          _body(
            '如有关于医疗免责声明的问题：\n'
            '• 邮箱：legal@shunshi.app\n'
            '• 客服：support@shunshi.app',
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

  Widget _warningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: ShunShiColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '重要提示：本应用提供的是传统养生建议，不构成医疗诊断。如有健康问题，请咨询专业医生。',
              style: TextStyle(
                fontSize: 14,
                color: ShunShiColors.warning,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
