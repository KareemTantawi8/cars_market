import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Custom Segment Control Widget
class SegmentControl<T> extends StatelessWidget {
  final List<SegmentItem<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  const SegmentControl({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.inputBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final isSelected = segment.value == selectedValue;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(segment.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.buttonPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.buttonPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    segment.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: isSelected ? 15 : 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Segment Item Model
class SegmentItem<T> {
  final T value;
  final String label;

  const SegmentItem({
    required this.value,
    required this.label,
  });
}

