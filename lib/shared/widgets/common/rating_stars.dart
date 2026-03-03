import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';

/// Rating Stars Widget
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final int reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.reviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final filled = index < rating.floor();
          final halfFilled = index == rating.floor() && rating % 1 >= 0.5;
          
          return Icon(
            filled
                ? Icons.star
                : halfFilled
                    ? Icons.star_half
                    : Icons.star_border,
            color: AppColors.ratingStar,
            size: size,
          );
        }),
        if (reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

