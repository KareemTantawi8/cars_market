import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';

/// Prominent guest-entry control for the login screen.
class GuestBrowseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool compact;

  const GuestBrowseButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactGuestBrowseButton(
        onPressed: onPressed,
        isLoading: isLoading,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [
                      AppColors.primaryColor.withValues(alpha: 0.18),
                      AppColors.primaryDark.withValues(alpha: 0.35),
                    ]
                  : [
                      AppColors.primaryColor.withValues(alpha: 0.08),
                      AppColors.primaryLight.withValues(alpha: 0.16),
                    ],
            ),
            border: Border.all(
              color: AppColors.primaryColor.withValues(
                alpha: enabled ? 0.55 : 0.25,
              ),
              width: 1.2,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _IconBadge(enabled: enabled),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الدخول كضيف',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? context.textPrimary
                              : context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تصفح الإعلانات وابحث عن قطع الغيار فوراً',
                        style: AppTextStyles.caption.copyWith(
                          color: context.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: const [
                          _FeatureChip(
                            icon: Icons.directions_car_outlined,
                            label: 'الإعلانات',
                          ),
                          _FeatureChip(
                            icon: Icons.search,
                            label: 'البحث',
                          ),
                          _FeatureChip(
                            icon: Icons.lock_open_outlined,
                            label: 'بدون حساب',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(
                        alpha: enabled ? 0.2 : 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: enabled
                          ? AppColors.primaryColor
                          : context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final bool enabled;

  const _IconBadge({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: enabled
              ? [AppColors.primaryColor, AppColors.primaryDark]
              : [
                  AppColors.primaryColor.withValues(alpha: 0.4),
                  AppColors.primaryDark.withValues(alpha: 0.4),
                ],
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: const Icon(
        Icons.explore_outlined,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

/// Compact variant for the login header (always visible without scrolling).
class _CompactGuestBrowseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CompactGuestBrowseButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.45 : 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الدخول كضيف',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'تصفح الإعلانات والبحث بدون حساب',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
