import 'package:flutter/material.dart';
import '../../../core/controllers/user_type_controller.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Debug widget to switch between user types
class UserTypeSwitcher extends StatelessWidget {
  const UserTypeSwitcher({super.key});

  /// Show user type switcher dialog
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserTypeSwitcherDialog(),
    );
  }

  /// Show as bottom sheet
  static void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const UserTypeSwitcherBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserTypeController(),
      builder: (context, child) {
        final controller = UserTypeController();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: controller.isVendor
                  ? AppColors.accentColor
                  : AppColors.primaryColor,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isVendor ? Icons.store : Icons.person,
                size: 16,
                color: controller.isVendor
                    ? AppColors.accentColor
                    : AppColors.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                controller.userTypeDisplayName,
                style: AppTextStyles.caption.copyWith(
                  color: controller.isVendor
                      ? AppColors.accentColor
                      : AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.swap_horiz,
                size: 14,
                color: context.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dialog version of user type switcher
class UserTypeSwitcherDialog extends StatelessWidget {
  const UserTypeSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserTypeController();
    
    return Dialog(
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تبديل نوع المستخدم',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'النوع الحالي: ${controller.userTypeDisplayName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeOption(
                    context,
                    controller,
                    AppConstants.userTypeCustomer,
                    'مستخدم',
                    Icons.person,
                    AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUserTypeOption(
                    context,
                    controller,
                    AppConstants.userTypeVendor,
                    'تاجر',
                    Icons.store,
                    AppColors.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: AppTextStyles.link,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(
    BuildContext context,
    UserTypeController controller,
    String userType,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = controller.currentUserType == userType;
    
    return InkWell(
      onTap: () async {
        if (userType == AppConstants.userTypeCustomer) {
          await controller.switchToCustomer();
        } else {
          await controller.switchToVendor();
        }
        Navigator.of(context).pop();
        // Show snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم التبديل إلى: $label'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.inputBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : context.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? color : context.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                'نشط',
                style: AppTextStyles.captionSmall.copyWith(
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet version of user type switcher
class UserTypeSwitcherBottomSheet extends StatelessWidget {
  const UserTypeSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserTypeController();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'تبديل نوع المستخدم',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'النوع الحالي: ${controller.userTypeDisplayName}',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSwitchButton(
                  context,
                  controller,
                  AppConstants.userTypeCustomer,
                  'مستخدم',
                  Icons.person,
                  AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSwitchButton(
                  context,
                  controller,
                  AppConstants.userTypeVendor,
                  'تاجر',
                  Icons.store,
                  AppColors.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await controller.toggleUserType();
              Navigator.of(context).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم التبديل إلى: ${controller.userTypeDisplayName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swap_horiz, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تبديل',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchButton(
    BuildContext context,
    UserTypeController controller,
    String userType,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = controller.currentUserType == userType;
    
    return InkWell(
      onTap: () async {
        if (userType == AppConstants.userTypeCustomer) {
          await controller.switchToCustomer();
        } else {
          await controller.switchToVendor();
        }
        Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم التبديل إلى: $label'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.inputBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? color : context.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? color : context.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

