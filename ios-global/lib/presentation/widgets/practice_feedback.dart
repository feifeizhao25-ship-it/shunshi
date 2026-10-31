import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

const _baseUrl = 'https://api.seasonsapp.com';

/// Show practice completion dialog with rating
Future<void> showPracticeFeedback(BuildContext context, {
  required String itemId,
  required String itemName,
}) async {
  int rating = 4;
  final noteController = TextEditingController();

  final result = await showDialog<bool>(context: context, builder: (dc) {
    return StatefulBuilder(builder: (dc, setDialogState) {
      return AlertDialog(
        backgroundColor: ShunShiColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('太棒了！你完成了$itemName', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary), textAlign: TextAlign.center),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('感觉如何？给这次练习打个分吧', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.textTertiary)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setDialogState(() => rating = i + 1),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < rating ? Colors.amber : ShunShiColors.textTertiary,
                size: 36,
              )),
            );
          })),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: ShunShiColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
            child: TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '有什么感受想记录的？',
                hintStyle: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(dc).pop(false), child: Text('取消', style: TextStyle(color: ShunShiColors.textTertiary))),
          ElevatedButton(
            onPressed: () => Navigator.of(dc).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: ShunShiColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('提交', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      );
    });
  });

  noteController.dispose();

  if (result == true && context.mounted) {
    try {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      await dio.post('/api/v1/user/feedback', data: {
        'action': 'completed_practice',
        'item_id': itemId,
        'rating': rating,
        'note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('太棒了！已记录到你的养生日志 🎉'), duration: Duration(seconds: 2), backgroundColor: ShunShiColors.primary),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已记录！'), duration: Duration(seconds: 1)),
        );
      }
    }
  }
}

/// A "我完成了！" button widget to add at the bottom of detail pages
class PracticeCompleteButton extends StatelessWidget {
  final String itemId;
  final String itemName;
  const PracticeCompleteButton({super.key, required this.itemId, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ElevatedButton.icon(
        onPressed: () => showPracticeFeedback(context, itemId: itemId, itemName: itemName),
        icon: const Text('🎉', style: TextStyle(fontSize: 18)),
        label: Text('我完成了！', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ShunShiColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
