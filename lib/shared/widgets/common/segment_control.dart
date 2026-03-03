import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

/// Custom Segment Control Widget – fully theme-aware
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: segments.asMap().entries.map((entry) {
          final segment    = entry.value;
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
                  color: isSelected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
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
                      color: isSelected ? Colors.white : cs.onSurface.withOpacity(0.6),
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

  const SegmentItem({required this.value, required this.label});
}
