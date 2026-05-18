import 'package:flutter/material.dart';
import '../../../core/services/account_deletion_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/auth_session.dart';

/// Destructive action to permanently delete the signed-in account.
class DeleteAccountButton extends StatefulWidget {
  const DeleteAccountButton({super.key});

  @override
  State<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy || !AuthSession.isLoggedIn) return;
    setState(() => _busy = true);
    try {
      await AccountDeletionService.confirmAndDeleteAccount(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isLoggedIn) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: _busy ? 0.6 : 1,
      child: IgnorePointer(
        ignoring: _busy,
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                else
                  const Icon(Icons.delete_forever_outlined,
                      color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Text(
                  _busy ? 'جاري حذف الحساب...' : 'حذف الحساب',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
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
