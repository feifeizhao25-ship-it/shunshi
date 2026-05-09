import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
        title: const Text('隐私政策',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _sectionTitle('顺时（ShunShi）隐私政策'),
          _body('最后更新日期：2025年5月\n生效日期：2025年5月', textColor),
          const SizedBox(height: 12),
          _sectionTitle('一、信息收集范围'),
          _body(
            '我们收集以下类型的信息，以向您提供养生服务：\n\n'
            '1.1 账户信息\n'
            '• 注册信息：手机号码、微信/OpenID、昵称、头像\n'
            '• 认证信息：登录凭证、设备标识符\n\n'
            '1.2 健康与养生数据\n'
            '• 体质测试结果（中医九种体质分类）\n'
            '• 养生偏好（节气调养、饮食、运动）\n'
            '• 每日打卡数据（睡眠、运动、饮食记录）\n'
            '• AI 对话记录（养生咨询内容）\n\n'
            '1.3 设备与技术信息\n'
            '• 设备型号、操作系统版本\n'
            '• 应用版本、语言设置\n'
            '• 网络状态（WiFi/移动数据）\n'
            '• 崩溃日志与性能数据\n\n'
            '1.4 位置信息\n'
            '• 粗略位置（城市级别），用于提供节气与时令建议\n'
            '• 我们不会收集精确GPS定位',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('二、信息使用目的'),
          _body(
            '您的信息仅用于以下目的：\n\n'
            '2.1 核心服务\n'
            '• 提供个性化养生建议和节气调养方案\n'
            '• 生成 AI 对话回答和体质分析报告\n'
            '• 家庭成员健康状态共享（需您明确授权）\n\n'
            '2.2 服务改进\n'
            '• 分析使用数据以改善产品体验\n'
            '• 优化 AI 模型的养生推荐质量\n'
            '• 进行去标识化统计分析\n\n'
            '2.3 安全保障\n'
            '• 检测和防范欺诈、滥用行为\n'
            '• 身份验证和账户安全保护',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('三、第三方信息共享'),
          _body(
            '我们不会出售您的个人数据。在以下场景中，我们可能与第三方共享必要信息：\n\n'
            '3.1 服务提供商\n'
            '• 支付服务：用于处理订阅和购买（支付宝、微信支付）\n'
            '• 推送服务：用于发送通知（极光推送、APNs/FCM）\n'
            '• 云存储：用于数据备份与同步（阿里云/腾讯云）\n'
            '• AI 服务：用于生成养生建议（自研模型 + 第三方大模型）\n\n'
            '3.2 法律要求\n'
            '• 遵守法律法规、法院命令或政府要求\n'
            '• 保护我们和他人的权利、财产或安全\n\n'
            '3.3 共享限制\n'
            '所有第三方合作伙伴均需签署数据处理协议，确保其数据处理符合本隐私政策和适用法律。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('四、数据安全措施'),
          _body(
            '4.1 传输安全\n'
            '• 所有网络通信使用 TLS 1.2+ 加密\n'
            '• API 请求采用 HTTPS 协议\n\n'
            '4.2 存储安全\n'
            '• 用户密码采用 bcrypt 加盐哈希存储\n'
            '• AI 对话记录采用 AES-256 加密存储\n'
            '• 健康数据在本地设备加密存储（Keychain/Keystore）\n'
            '• 数据库访问采用最小权限原则\n\n'
            '4.3 运营安全\n'
            '• 定期进行安全审计与渗透测试\n'
            '• 员工访问敏感数据需多因素认证\n'
            '• 数据泄露应急预案已建立并定期演练',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('五、您的权利'),
          _body(
            '5.1 根据《个人信息保护法》（PIPL），您享有以下权利：\n\n'
            '• 知情权：了解我们收集、使用您个人信息的目的和方式\n'
            '• 访问权：查看我们持有的您的个人数据\n'
            '• 更正权：更正不准确的个人数据\n'
            '• 删除权：要求删除您的个人数据\n'
            '• 导出权：以通用格式导出您的数据\n'
            '• 撤回同意权：随时撤回对数据处理的同意\n'
            '• 自动化决策拒绝权：拒绝仅通过自动化决策做出的分析\n\n'
            '5.2 GDPR 附加权利（适用于欧盟/欧洲经济区用户）\n\n'
            '• 数据可携权\n'
            '• 限制处理权\n'
            '• 向监管机构投诉的权利\n\n'
            '5.3 行使权利\n'
            '您可以通过应用内「设置 > 隐私 > 数据管理」或联系 privacy@shunshi.app 行使上述权利。我们将在 15 个工作日内回复您的请求。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('六、数据保留'),
          _body(
            '• 账户存续期间：保留所有必要数据以提供服务\n'
            '• 账户删除后：30 天内清除所有个人数据\n'
            '• 法律要求：部分数据可能依法保留更长时间（如交易记录保留 5 年）\n'
            '• 匿名化数据：去标识化后的统计数据可无限期保留',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('七、未成年人保护'),
          _body(
            '我们不向 14 周岁以下未成年人提供服务。如果我们在不知情的情况下收集了未成年人的数据，将在发现后立即删除。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('八、隐私政策更新'),
          _body(
            '我们可能会不定期更新本隐私政策。重大变更将通过应用内通知或邮件方式告知您。继续使用本应用即表示您同意更新后的政策。',
            textColor,
          ),
          const SizedBox(height: 12),
          _sectionTitle('九、联系我们'),
          _body(
            '数据保护相关问题：\n'
            '• 邮箱：privacy@shunshi.app\n'
            '• 数据保护官：dpo@shunshi.app\n'
            '• 通信地址：[公司注册地址]\n\n'
            '我们将在 15 个工作日内回复您的请求。',
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
