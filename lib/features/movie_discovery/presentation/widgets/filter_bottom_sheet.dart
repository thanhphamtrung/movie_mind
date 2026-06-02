import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedFormat = 'Phim lẻ';
  final List<String> _selectedGenres = ['Viễn tưởng', 'Trinh thám'];
  String _selectedCountry = 'Mỹ & Anh';

  static const Color pinkGlow = Color(0xFFFF7EB3);
  static const Color purpleGlow = Color(0xFF8A2BE2);

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFormatToggle() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ['Phim lẻ', 'Phim bộ'].map((format) {
          final isSelected = _selectedFormat == format;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFormat = format),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [pinkGlow, purpleGlow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: purpleGlow.withValues(alpha: 0.3),
                            blurRadius: 15,
                          )
                        ],
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  format,
                  style: TextStyle(
                    color: isSelected ? CupertinoColors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectableChips({
    required List<String> options,
    required bool Function(String) isSelected,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final selected = isSelected(option);
        return GestureDetector(
          onTap: () => onTap(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: selected
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [pinkGlow, purpleGlow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: purpleGlow.withValues(alpha: 0.3),
                        blurRadius: 15,
                      )
                    ],
                  )
                : BoxDecoration(
                    color: AppColors.glassBackground,
                    border: Border.all(color: AppColors.glassBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
            child: Text(
              option,
              style: TextStyle(
                color: selected ? CupertinoColors.white : AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.5), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.8),
              blurRadius: 50,
              offset: const Offset(0, -20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 16),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32), // Spacer
                  const Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(
                        CupertinoIcons.clear,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Định dạng'),
                    _buildFormatToggle(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Thể loại'),
                    _buildSelectableChips(
                      options: [
                        'Viễn tưởng', 'Hành động', 'Trinh thám',
                        'Hài hước', 'Tâm lý', 'Kinh dị'
                      ],
                      isSelected: (option) => _selectedGenres.contains(option),
                      onTap: (option) {
                        setState(() {
                          if (_selectedGenres.contains(option)) {
                            _selectedGenres.remove(option);
                          } else {
                            _selectedGenres.add(option);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Quốc gia'),
                    _buildSelectableChips(
                      options: [
                        'Mỹ & Anh', 'Hàn Quốc', 'Nhật Bản', 'Pháp', 'Tất cả'
                      ],
                      isSelected: (option) => _selectedCountry == option,
                      onTap: (option) => setState(() => _selectedCountry = option),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.5)),
                ),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context, {
                  'format': _selectedFormat,
                  'genres': _selectedGenres,
                  'country': _selectedCountry,
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [pinkGlow, purpleGlow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: purpleGlow.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.wand_rays, color: CupertinoColors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Áp dụng bộ lọc',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
