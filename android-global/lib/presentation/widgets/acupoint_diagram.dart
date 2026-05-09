import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/theme_helper.dart';

/// Acupressure定位图数据
class _AcupointDiagramData {
  final String name;
  final String code;
  final String bodyPart; // Body part
  final IconData bodyIcon;
  final String location;
  final String positioning;
  final String effect;
  final String method;
  final String duration;
  final String frequency;
  final double dotX; // 0.0-1.0 Relative position
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
    name: 'Hegu',
    code: 'LI4',
    bodyPart: 'Back of Hand',
    bodyIcon: Icons.back_hand,
    location: 'Between 1st and 2nd metacarpal bones, highest point of web',
    positioning: 'Press thumb and index finger together, the highest point in the web',
    effect: 'Calms pain, unblocks meridians, clears heat',
    method: 'Press opposite Hegu with thumb, gradually increasing pressure',
    duration: '2-3min',
    frequency: '2-3 times per week',
    dotX: 0.5,
    dotY: 0.4,
  ),
  _AcupointDiagramData(
    name: 'Zusanli (ST36)',
    code: 'ST36',
    bodyPart: 'Outer Lower Leg',
    bodyIcon: Icons.accessibility_new,
    location: '3 cun below Dubi, one finger-width lateral to anterior tibial crest',
    positioning: 'Four finger-widths below the outer knee cap',
    effect: 'Tonifies Spleen, strengthens Stomach, the "Longevity Point"',
    method: 'Press firmly with thumb, may combine with moxibustion',
    duration: '5-10min',
    frequency: '1-2 times per week',
    dotX: 0.55,
    dotY: 0.35,
  ),
  _AcupointDiagramData(
    name: 'Yongquan (KI1)',
    code: 'KI1',
    bodyPart: 'Sole Front 1/3',
    bodyIcon: Icons.do_not_step,
    location: 'Depression at front 1/3 of the sole',
    positioning: 'Curl toes, find the depression at front 1/3 of sole',
    effect: 'Awakens the brain, nourishes Yin, tonifies Kidney, draws fire to source',
    method: 'Rub or press, best after a warm foot soak before bed',
    duration: '5-10min',
    frequency: 'Once nightly before bed',
    dotX: 0.5,
    dotY: 0.65,
  ),
  _AcupointDiagramData(
    name: 'Taichong',
    code: 'LR3',
    bodyPart: 'Top of Foot',
    bodyIcon: Icons.arrow_upward,
    location: 'Depression posterior to 1st-2nd metatarsal space on dorsum',
    positioning: 'Push upward between big toe and second toe until you feel the depression',
    effect: 'Pacifies Liver, extinguishes wind, clears heat, resolves dampness',
    method: 'Press with thumb, gradually increasing pressure',
    duration: '3-5min',
    frequency: '1-2 times per week',
    dotX: 0.5,
    dotY: 0.3,
  ),
  _AcupointDiagramData(
    name: 'Sanyinjiao (SP6)',
    code: 'SP6',
    bodyPart: 'Above Inner Ankle',
    bodyIcon: Icons.accessibility,
    location: '3 cun above medial malleolus, posterior to medial tibial border',
    positioning: 'Four finger-widths above the inner ankle bone',
    effect: 'Strengthens Spleen, nourishes blood, regulates Liver, tonifies Kidney',
    method: 'Press with thumb, may use circular rotation',
    duration: '3-5min',
    frequency: '1-2 times per week',
    dotX: 0.4,
    dotY: 0.45,
  ),
  _AcupointDiagramData(
    name: 'Neiguan',
    code: 'PC6',
    bodyPart: 'Inner Forearm',
    bodyIcon: Icons.front_hand,
    location: '2 cun above wrist crease, between two tendons',
    positioning: 'Three finger-widths above the wrist crease',
    effect: 'Calms the mind, soothes the spirit, regulates Qi, relieves pain',
    method: 'Press with thumb, use small circular rubbing motion',
    duration: '3-5min',
    frequency: '2-3 times per week',
    dotX: 0.5,
    dotY: 0.45,
  ),
];

/// Acupressure定位图 Widget
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
            'Key Acupressure Points Map',
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
                        'Tap for Details →',
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
                _detailSection(context, 'Location', data.location),
                _detailSection(context, 'How to Find', data.positioning),
                _detailSection(context, 'Benefits', data.effect),
                _detailSection(context, 'Pressing Method', data.method),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _detailSection(context, 'Duration', data.duration)),
                    const SizedBox(width: 12),
                    Expanded(child: _detailSection(context, 'Frequency', data.frequency)),
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
