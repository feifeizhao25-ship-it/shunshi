import 'package:flutter/material.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '内容由AI生成，仅供养生参考，不构成医疗诊断。如有不适请及时就医。',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
