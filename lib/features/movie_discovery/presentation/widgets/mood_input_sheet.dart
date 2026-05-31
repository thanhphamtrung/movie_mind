import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MoodInputSheet extends StatefulWidget {
  final Function(String) onSubmitted;

  const MoodInputSheet({required this.onSubmitted, super.key});

  @override
  State<MoodInputSheet> createState() => _MoodInputSheetState();
}

class _MoodInputSheetState extends State<MoodInputSheet> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _quickMoods = [
    '🎬 Trinh thám hack não',
    '🍿 Muốn khóc thật to',
    '😂 Hài hước giải trí',
    '🌌 Viễn tưởng phiêu lưu',
    '🧸 Nhẹ nhàng ấm áp',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tâm trạng hiện tại của bạn?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mô tả tâm trạng thực tế của bạn bằng tiếng Việt hoặc tiếng Anh, AI sẽ gợi ý các tác phẩm điện ảnh xuất sắc tương ứng.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: "Tôi đang hơi buồn và muốn xem một bộ phim trinh thám hack não nhưng kết thúc ấm áp..."',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gợi ý nhanh:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _quickMoods.map((mood) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        mood,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: AppColors.surfaceElevated,
                      side: const BorderSide(color: AppColors.glassBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () {
                        _controller.text = mood.substring(2); // strip emoji
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    widget.onSubmitted(_controller.text.trim());
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Tìm Phim Ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
}
