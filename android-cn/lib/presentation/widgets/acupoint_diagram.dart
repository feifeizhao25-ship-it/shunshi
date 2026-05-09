import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/theme_helper.dart';

/// 穴位定位图数据
class _AcupointDiagramData {
  final String name;
  final String code;
  final String bodyPart; // 身体部位
  final IconData bodyIcon;
  final String location;
  final String positioning;
  final String effect;
  final String method;
  final String duration;
  final String frequency;
  final double dotX; // 0.0-1.0 相对位置
  final double dotY;

  const _AcupointDiagramData({
    required this.name,
    required this.code,
    required this.bodyPart,
    required this.bodyIcon,
    required this.location,
    required this.positioning,
    required this.effect,
    required this.method,
    required this.duration,
    required this.frequency,
    required this.dotX,
    required this.dotY,
  });
}

const List<_AcupointDiagramData> _kKeyAcupoints = [
  _AcupointDiagramData(
    name: '合谷穴',
    code: 'LI4',
    bodyPart: '手背虎口',
    bodyIcon: Icons.back_hand,
    location: '第1、2掌骨之间，虎口最高点',
    positioning: '拇指与食指并拢，虎口处最高点即是',
    effect: '镇静止痛、通经活络、清热解表',
    method: '拇指按压对侧合谷，由轻到重',
    duration: '2-3分钟',
    frequency: '每日2-3次',
    dotX: 0.5,
    dotY: 0.4,
  ),
  _AcupointDiagramData(
    name: '足三里穴',
    code: 'ST36',
    bodyPart: '小腿外侧',
    bodyIcon: Icons.accessibility_new,
    location: '犊鼻穴下3寸，胫骨前嵴外一横指',
    positioning: '膝盖骨下缘外侧向下量四横指',
    effect: '补脾健胃、扶正培元，"长寿穴"',
    method: '拇指用力按压，可配合艾灸',
    duration: '5-10分钟',
    frequency: '每日1-2次',
    dotX: 0.55,
    dotY: 0.35,
  ),
  _AcupointDiagramData(
    name: '涌泉穴',
    code: 'KI1',
    bodyPart: '足底前1/3',
    bodyIcon: Icons.do_not_step,
    location: '足底前1/3凹陷处',
    positioning: '蜷足，足底前1/3处的凹陷中',
    effect: '醒脑开窍、滋阴益肾、引火归元',
    method: '搓揉或按压，睡前泡脚后最佳',
    duration: '5-10分钟',
    frequency: '每晚睡前1次',
    dotX: 0.5,
    dotY: 0.65,
  ),
  _AcupointDiagramData(
    name: '太冲穴',
    code: 'LR3',
    bodyPart: '足背',
    bodyIcon: Icons.arrow_upward,
    location: '足背第1、2跖骨间隙后方凹陷',
    positioning: '大拇趾与二趾之间向上推至凹陷',
    effect: '平肝息风、清热利湿',
    method: '拇指按压，由轻到重',
    duration: '3-5分钟',
    frequency: '每日1-2次',
    dotX: 0.5,
    dotY: 0.3,
  ),
  _AcupointDiagramData(
    name: '三阴交穴',
    code: 'SP6',
    bodyPart: '内踝上方',
    bodyIcon: Icons.accessibility,
    location: '内踝尖上3寸，胫骨内侧缘后方',
    positioning: '内踝骨最高点向上量四横指',
    effect: '健脾益血、调肝补肾',
    method: '拇指按压，可做旋转按揉',
    duration: '3-5分钟',
    frequency: '每日1-2次',
    dotX: 0.4,
    dotY: 0.45,
  ),
  _AcupointDiagramData(
    name: '内关穴',
    code: 'PC6',
    bodyPart: '前臂掌侧',
    bodyIcon: Icons.front_hand,
    location: '腕横纹上2寸，两筋之间',
    positioning: '手腕横纹向上量三横指宽',
    effect: '宁心安神、理气止痛',
    method: '拇指按压，做小幅旋转按揉',
    duration: '3-5分钟',
    frequency: '每日2-3次',
    dotX: 0.5,
    dotY: 0.45,
  ),
];

/// 穴位定位图 Widget
class AcupointDiagram extends StatelessWidget {
  const AcupointDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            '重点穴位定位图',
            style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        SizedBox(
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _kKeyAcupoints.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _AcupointDiagramCard(data: _kKeyAcupoints[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _AcupointDiagramCard extends StatelessWidget {
  final _AcupointDiagramData data;

  const _AcupointDiagramCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailDialog(context),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
            // Diagram area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Body part icon
                    Center(
                      child: Icon(
                        data.bodyIcon,
                        size: 80,
                        color: ShunShiColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    // Acupoint dot
                    Positioned(
                      left: data.dotX * 176 - 6,
                      top: data.dotY * (MediaQuery.of(context).size.height * 0.15) - 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: ShunShiColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Label line
                    Positioned(
                      left: data.dotX * 176 + 8,
                      top: data.dotY * (MediaQuery.of(context).size.height * 0.15) - 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ShunShiColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.name,
                          style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: ShunShiColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data.code,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: ShunShiColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.bodyPart,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: ShunShiColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '点击查看详情 →',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: ShunShiColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(data.bodyIcon, size: 36, color: ShunShiColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.name,
                            style: TextStyle(
                              fontFamily: ShunShiTypography.serifFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            '${data.code} · ${data.bodyPart}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailSection(context, '定位', data.location),
                _detailSection(context, '取穴方法', data.positioning),
                _detailSection(context, '功效', data.effect),
                _detailSection(context, '按压方法', data.method),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _detailSection(context, '时长', data.duration)),
                    const SizedBox(width: 12),
                    Expanded(child: _detailSection(context, '频率', data.frequency)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
