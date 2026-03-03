import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'online_indicator.dart';
import 'rating_stars.dart';

/// Supplier Card Widget – fully theme-aware
class SupplierCard extends StatelessWidget {
  final String name;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final List<String> supportedBrands;
  final String location;
  final String distance;
  final String? imageUrl;
  final VoidCallback? onTap;

  const SupplierCard({
    super.key,
    required this.name,
    required this.isOnline,
    required this.rating,
    this.reviewCount = 0,
    required this.supportedBrands,
    required this.location,
    required this.distance,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(cs),
                        ),
                      )
                    : _buildPlaceholder(cs),
              ),
              const SizedBox(width: 16),
              // Supplier Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OnlineIndicator(isOnline: isOnline),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'متصل' : 'غير متصل',
                          style: AppTextStyles.caption.copyWith(
                            color: isOnline
                                ? AppColors.online
                                : cs.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    RatingStars(
                      rating: rating,
                      size: 14,
                      reviewCount: reviewCount,
                    ),
                    const SizedBox(height: 8),
                    // Supported Brands
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: supportedBrands.take(3).map((brand) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(brand, style: AppTextStyles.caption),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$location ($distance)',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Icons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.phone, color: cs.primary),
                    onPressed: () {
                      // TODO: Handle phone call
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.location_on, color: cs.primary),
                    onPressed: () {
                      // TODO: Handle location
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Icon(
      Icons.store,
      color: cs.primary.withOpacity(0.5),
      size: 40,
    );
  }
}
