import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';

/// Opens the App Store support URL (shared by customer profile and vendor dashboard).
class SupportLinkTile extends StatelessWidget {
  final bool embeddedInAccountCard;

  const SupportLinkTile({
    super.key,
    this.embeddedInAccountCard = false,
  });

  Future<void> _open() async {
    final uri = Uri.parse(AppConstants.supportUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (embeddedInAccountCard) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _open,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent_outlined,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الدعم والمساعدة',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConstants.supportUrl,
                        style: AppTextStyles.caption.copyWith(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: context.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.inputBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.support_agent_outlined,
                color: AppColors.info,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدعم والمساعدة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppConstants.supportUrl,
                    style: AppTextStyles.caption.copyWith(
                      color: context.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
