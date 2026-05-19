import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';

/// Friendly login prompt shown when a guest tries account-only actions.
class LoginRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final String loginButtonLabel;

  const LoginRequiredDialog({
    super.key,
    this.title = 'تسجيل الدخول مطلوب',
    this.message =
        'هذه الميزة مرتبطة بحسابك. سجّل الدخول أو أنشئ حساباً للمتابعة.',
    this.loginButtonLabel = 'تسجيل الدخول',
  });

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    String? loginButtonLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => LoginRequiredDialog(
        title: title ?? 'تسجيل الدخول مطلوب',
        message: message ??
            'هذه الميزة مرتبطة بحسابك. سجّل الدخول أو أنشئ حساباً للمتابعة.',
        loginButtonLabel: loginButtonLabel ?? 'تسجيل الدخول',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: AppTextStyles.headingSmall),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: context.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'لاحقاً',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: Text(loginButtonLabel),
        ),
      ],
    );
  }
}
