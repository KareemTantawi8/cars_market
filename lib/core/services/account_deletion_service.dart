import 'package:flutter/material.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../navigation/root_navigator.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/auth_session.dart';
import '../utils/extensions.dart';
import 'session_service.dart';

/// In-app account deletion flow (App Store Guideline 5.1.1(v)).
class AccountDeletionService {
  AccountDeletionService._();

  static final _authRepository = AuthRepository();
  static bool _isDeleting = false;
  static bool _loadingVisible = false;

  /// Shows confirmation dialogs, attempts server deletion, then clears local data.
  static Future<void> confirmAndDeleteAccount(BuildContext context) async {
    if (_isDeleting) return;

    if (!AuthSession.isLoggedIn) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حذف الحساب', style: AppTextStyles.headingSmall),
        content: Text(
          'سيتم حذف حسابك وبياناتك المرتبطة به نهائياً. لا يمكن التراجع عن هذا الإجراء.\n\nهل تريد المتابعة؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.bodySmall.copyWith(
                color: ctx.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'متابعة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final finalConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('تأكيد الحذف', style: AppTextStyles.headingSmall),
        content: Text(
          'اضغط «حذف حسابي» لتأكيد حذف الحساب بشكل نهائي.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.bodySmall.copyWith(
                color: ctx.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'حذف حسابي',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !context.mounted) return;

    _isDeleting = true;
    _showLoadingOverlay();

    try {
      try {
        await _authRepository.deleteAccount();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      try {
        await _authRepository.logout();
      } catch (_) {}

      await SessionService.clearLocalSession();

      _loadingVisible = false;

      final navigator = rootNavigatorKey.currentState;
      if (navigator != null) {
        await navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
      } else if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messengerContext = rootNavigatorKey.currentContext;
        if (messengerContext == null) return;
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          const SnackBar(
            content: Text('تم حذف حسابك بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      });
    } finally {
      if (_loadingVisible) _dismissLoadingOverlay();
      _isDeleting = false;
    }
  }

  static void _showLoadingOverlay() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    _loadingVisible = true;
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  static void _dismissLoadingOverlay() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null || !_loadingVisible) return;
    if (navigator.canPop()) {
      navigator.pop();
    }
    _loadingVisible = false;
  }
}
