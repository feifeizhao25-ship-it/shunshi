import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text('隐私政策', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('隐私政策', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
          SizedBox(height: 16),
          Text(
            '顺时（ShunShi）隐私政策\n\n'
            '最后更新日期：2025年1月\n\n'
            '1. 信息收集\n我们收集以下信息以提供更好的服务：\n• 基本账户信息（昵称、头像）\n• 健康相关数据（体质测试结果、养生偏好）\n• 使用数据（功能使用频率、对话记录）\n\n'
            '2. 信息使用\n您的数据仅用于：\n• 提供个性化养生建议\n• 改善服务质量\n• 家庭成员健康状态共享（经您授权）\n\n'
            '3. 信息保护\n• 所有数据传输使用SSL加密\n• AI对话记录加密存储\n• 严格的内部访问控制\n\n'
            '4. 信息共享\n我们不会向第三方出售或共享您的个人数据，除非：\n• 获得您的明确同意\n• 法律法规要求\n\n'
            '5. 您的权利\n根据GDPR等数据保护法规，您有权：\n• 访问您的个人数据\n• 导出您的数据\n• 删除您的数据\n• 撤回同意\n\n'
            '6. 数据保留\n账户删除后，我们将在30天内清除所有相关数据。\n\n'
            '7. 联系我们\n数据保护相关问题：privacy@shunshi.app',
            style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.8),
          ),
        ],
      ),
    );
  }
}
