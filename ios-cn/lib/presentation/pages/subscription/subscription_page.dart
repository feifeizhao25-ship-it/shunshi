import '../../../core/router/safe_pop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/theme_helper.dart';

const _baseUrl = 'http://116.62.32.43:4000';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> with SingleTickerProviderStateMixin {
  int _selectedPlan = 1;
  bool _isLoading = false;
  bool _isSubscribed = false;
  bool _hasError = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  final _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  static const _plans = [
    _Plan('月度会员', '¥28', '/月'),
    _Plan('季度会员', '¥68', '/季'),
    _Plan('年度会员', '¥198', '/年'),
  ];

  static const _coreValues = [
    ('AI 无限对话', '免费每天3次，SVIP 不限次数'),
    ('个性化养生方案', '根据体质、节气、情绪动态调整'),
    ('家庭共享', '最多 5 人同步养生数据'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final res = await _dio.get('/api/v1/subscription/status',
          queryParameters: {'user_id': token.isNotEmpty ? token : 'guest'});
      if (res.data != null) {
        final isActive = res.data['is_active'] as bool? ??
            (res.data['state'] != null && res.data['state'] != 'free');
        setState(() { _isSubscribed = isActive; });
        await prefs.setBool('is_subscribed', isActive);
        return;
      }
    } catch (_) {}
    setState(() => _isSubscribed = prefs.getBool('is_subscribed') ?? false);
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('auth_token') ?? 'guest_\${DateTime.now().millisecondsSinceEpoch}';
      final res = await _dio.post('/api/v1/payment/create', data: {
        'plan_id': ['monthly', 'quarterly', 'yearly'][_selectedPlan],
        'user_id': userId,
        'payment_method': 'alipay',
      });
      if (res.statusCode == 200 && mounted) {
        await prefs.setBool('is_subscribed', true);
        await prefs.setString('subscription_plan', ['monthly', 'quarterly', 'yearly'][_selectedPlan]);
        setState(() { _isLoading = false; _isSubscribed = true; });
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShunShiColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, size: 36, color: ShunShiColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('订阅成功！', style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily, fontSize: 22, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('畅享全部养生智慧', textAlign: TextAlign.center, style: TextStyle(
            fontSize: 14, color: ShunShiColors.textSecondary, height: 1.5)),
        ]),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); if (mounted) safePop(context); },
            style: ElevatedButton.styleFrom(
              backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('开始体验'),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background(context);
    final tp = AppColors.textPrimary(context);
    final ts = AppColors.textSecondary(context);
    final tt = AppColors.textTertiary(context);
    final primary = AppColors.primary(context);
    final surface = AppColors.surfaceContainerLowest(context);
    final borderC = AppColors.border(context);

    if (_hasError && !_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => safePop(context)),
          title: Text('顺时会员', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, color: tp)),
          backgroundColor: bg, elevation: 0,
          actions: [IconButton(icon: Icon(Icons.close, color: tt), onPressed: () => safePop(context))],
        ),
        body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: tt),
            const SizedBox(height: 16),
            Text('网络开小差', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
            const SizedBox(height: 8),
            Text('请检查网络后重试', style: TextStyle(fontSize: 14, color: tt)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _hasError = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              child: const Text('重新加载', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ))),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => safePop(context)),
        title: Text('顺时会员', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, color: tp)),
        backgroundColor: bg, elevation: 0,
        actions: [IconButton(icon: Icon(Icons.close, color: tt), onPressed: () => safePop(context))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. VIP Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4C3605), Color(0xFF74593C)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const Icon(Icons.workspace_premium, size: 48, color: ShunShiColors.goldLight),
                  const SizedBox(height: 10),
                  Text(_isSubscribed ? '顺时 SVIP 已激活' : '顺时 SVIP', style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: ShunShiTypography.serifFamily)),
                  const SizedBox(height: 6),
                  Text(_isSubscribed ? '享受全部养生智慧' : '解锁全部养生智慧 · 7天免费体验',
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 24),
              // 2. 选择方案
              Text('选择方案', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ts, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              ...List.generate(_plans.length, (i) {
                final p = _plans[i];
                final selected = _selectedPlan == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlan = i),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? primary : borderC, width: selected ? 2 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? primary : Colors.transparent,
                            border: Border.all(color: selected ? primary : tt, width: 2),
                          ),
                          child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Row(children: [
                          Text(p.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: ShunShiTypography.serifFamily, color: tp)),
                          if (i == 1) ...[const SizedBox(width: 8), _buildTag('最热门', ShunShiColors.error)],
                          if (i == 2) ...[const SizedBox(width: 8), _buildTag('最划算', ShunShiColors.primary)],
                        ])),
                        RichText(text: TextSpan(children: [
                          TextSpan(text: p.price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: selected ? primary : tp, fontFamily: ShunShiTypography.serifFamily)),
                          TextSpan(text: p.period, style: TextStyle(fontSize: 13, color: tt)),
                        ])),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // 3. 核心权益
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderC)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SVIP 专属权益', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: ShunShiTypography.serifFamily, color: tp)),
                  const SizedBox(height: 14),
                  ..._coreValues.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 20, height: 20,
                        decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.check, size: 12, color: primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
                        Text(v.$2, style: TextStyle(fontSize: 12, color: ts)),
                      ])),
                    ]),
                  )),
                ]),
              ),
              const SizedBox(height: 28),
              // 4. 订阅按钮
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isSubscribed ? null : _handleSubscribe),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary, foregroundColor: Colors.white,
                    disabledBackgroundColor: ShunShiColors.textDisabled,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isSubscribed ? '已订阅 · 畅享全部权益' : '立即订阅 · 7天免费体验',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              Center(child: Text('可随时取消，取消后仍可使用至当期结束', style: TextStyle(fontSize: 12, color: tt))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Divider(color: borderC)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('更多选项', style: TextStyle(fontSize: 12, color: tt))),
                Expanded(child: Divider(color: borderC)),
              ]),
              const SizedBox(height: 8),
              _LinkRow(label: '恢复购买', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('正在检查购买记录…'), duration: Duration(seconds: 2)));
              }),
              _LinkRow(label: '管理订阅', onTap: _showSubscriptionManagementSheet),
              _LinkRow(label: '恢复购买', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('正在检查购买记录…'), duration: Duration(seconds: 2)));
              }),
              _LinkRow(label: '用户协议', onTap: () => _showLegalSheet(context, '用户协议')),
              _LinkRow(label: '隐私政策', onTap: () => _showLegalSheet(context, '隐私政策')),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  void _showSubscriptionManagementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ShunShiColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.8, expand: false,
        builder: (_, scrollController) => Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Text('订阅管理', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(ctx))),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          Divider(height: 1, color: ShunShiColors.border),
          Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.all(20), children: [
            // 订阅状态卡
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4C3605), Color(0xFF74593C)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.workspace_premium, size: 36, color: ShunShiColors.goldLight),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_isSubscribed ? '顺时 SVIP 已激活' : '您当前为免费用户', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(_isSubscribed ? '到期时间：当期结束前可续订' : '订阅解锁全部养生智慧', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            // 订阅方案信息
            _ManagementRow(icon: Icons.calendar_today_outlined, label: '当前方案', value: _isSubscribed ? ['月度会员', '季度会员', '年度会员'][_selectedPlan] : '免费版'),
            _ManagementRow(icon: Icons.payment_outlined, label: '支付方式', value: _isSubscribed ? '支付宝' : '-'),
            _ManagementRow(icon: Icons.access_time, label: '下次扣款', value: _isSubscribed ? '到期自动续费' : '-'),
            const SizedBox(height: 24),
            // 操作按钮
            if (_isSubscribed) ...[
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请前往手机系统设置管理订阅取消'), duration: Duration(seconds: 3)));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ShunShiColors.error,
                  side: const BorderSide(color: ShunShiColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('取消订阅'),
              )),
              const SizedBox(height: 10),
            ],
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭', style: TextStyle(color: ShunShiColors.textSecondary)),
            )),
          ])),
        ]),
      ),
    );
  }
}

class _Plan {
  final String title;
  final String price;
  final String period;
  const _Plan(this.title, this.price, this.period);
}

class _ManagementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ManagementRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary(context)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context))),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
      ]),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context))),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary(context)),
          ],
        ),
      ),
    );
  }
}

void _showLegalSheet(BuildContext context, String title) {
  final content = title == '用户协议' ? _userAgreementText : _privacyPolicyText;
  showModalBottomSheet(
    context: context,
    backgroundColor: ShunShiColors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (_, scrollController) => Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Text(title, style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context))),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
        Divider(height: 1, color: ShunShiColors.border),
        Expanded(child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Text(content, style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.6)),
        )),
      ]),
    ),
  );
}

const _userAgreementText = '''
顺时用户协议

更新时间：2026年1月1日
生效时间：2026年1月1日

欢迎使用顺时（以下简称"本应用"）。

一、服务说明
顺时是一款结合传统养生智慧与AI技术的个性化健康建议应用，基于节气、体质、情绪等维度提供养生内容推荐。

二、使用规范
1. 您确认在使用本应用时年满18周岁。
2. 您承诺不将本应用用于任何违法或不当目的。
3. 您的账号信息应当真实有效。

三、订阅与付费
1. 本应用提供免费试用和付费订阅两种模式。
2. 订阅价格以页面展示为准，支持支付宝支付。
3. 订阅为自动续约，您可随时取消。
4. 取消后您仍可使用已订阅期间的服务。

四、免责声明
1. 本应用提供的健康建议仅供参考，不构成医疗诊断或治疗。
2. 如有健康问题，请咨询专业医疗机构。
3. 因用户不当使用造成的后果，由用户自行承担。

五、知识产权
本应用的所有内容、设计、代码等知识产权归本团队所有。

六、协议修订
我们保留随时修改本协议的权利，修改后的协议将公开发布。

七、联系方式
如有问题，请通过应用内客服联系我们。
''';

const _privacyPolicyText = '''
顺时隐私政策

更新时间：2026年1月1日

一、信息收集
1. 账户信息：您主动提供的手机号、昵称等。
2. 健康数据：您主动填写的体质、情绪、饮食、运动等养生相关数据。
3. 使用数据：应用使用时长、功能偏好等匿名统计信息。

二、信息使用
1. 用于提供个性化养生建议。
2. 用于改进产品体验。
3. 在法律规定范围内用于服务优化。

三、信息共享
未经您同意，我们不会与任何第三方共享您的个人信息。

四、信息存储
您的数据存储在中华人民共和国境内的服务器上。

五、数据安全
我们采用行业标准的安全措施保护您的数据。

六、您的权利
1. 您有权随时查看、导出您的个人数据。
2. 您有权要求删除您的账户及关联数据。

七、未成年人
本应用不面向未满18周岁的未成年人。

八、联系我们
如对隐私政策有疑问，请通过应用内客服联系我们。
''';

