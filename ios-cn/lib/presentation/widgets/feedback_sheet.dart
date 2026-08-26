import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../design_system/theme.dart';

/// 底部弹出反馈卡片: "这条建议对你有帮助吗?" 👍👎
class FeedbackSheet extends StatefulWidget {
  final String contentId;
  final String type;

  const FeedbackSheet({super.key, required this.contentId, this.type = 'chat'});

  static Future<void> show(BuildContext context, {required String contentId, String type = 'chat'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedbackSheet(contentId: contentId, type: type),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  int? _rating;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == null) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'guest';
      await Dio().post(
        'https://api.shunshi.app/api/v1/feedback',
        data: {
          'user_id': userId,
          'type': widget.type,
          'rating': _rating,
          'comment': _commentController.text.trim(),
          'content_id': widget.contentId,
        },
      );
      final count = prefs.getInt('feedback_count') ?? 0;
      await prefs.setInt('feedback_count', count + 1);
      if (mounted) {
        Navigator.pop(context);
        if (count + 1 >= 3 && (count + 1) % 3 == 0) {
          _showEncouragement();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交失败，请稍后重试'), duration: Duration(seconds: 2)),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _showEncouragement() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ShunShiColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('感谢你的反馈！',
            style: TextStyle(fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.primary, fontSize: 18)),
        content: const Text('你的每一条反馈都在帮助我们变得更好，为用户提供更优质的养生体验。',
            style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: 14, color: ShunShiColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('很高兴能帮忙！', style: TextStyle(color: ShunShiColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: ShunShiColors.border, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          const Text('这条建议对你有帮助吗？',
              style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 20,
                  fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            _thumbButton(Icons.thumb_up_outlined, 1),
            const SizedBox(width: 12),
            _thumbButton(Icons.thumb_down_outlined, -1),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '补充建议（可选）',
              hintStyle: const TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
              filled: true,
              fillColor: ShunShiColors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating == null || _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ShunShiColors.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('提交', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbButton(IconData icon, int value) {
    final selected = _rating == value;
    return GestureDetector(
      onTap: () => setState(() => _rating = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? ShunShiColors.primary.withValues(alpha: 0.1) : ShunShiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? ShunShiColors.primary : ShunShiColors.border),
        ),
        child: Icon(icon, color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary, size: 28),
      ),
    );
  }
}
