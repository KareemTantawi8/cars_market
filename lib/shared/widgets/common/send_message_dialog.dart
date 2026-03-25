import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/primary_button.dart';

/// Send Message to Customer Dialog
class SendMessageDialog extends StatefulWidget {
  final String customerName;

  const SendMessageDialog({
    super.key,
    this.customerName = 'العميل',
  });

  @override
  State<SendMessageDialog> createState() => _SendMessageDialogState();

  static Future<bool?> show(BuildContext context, {String? customerName}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => SendMessageDialog(customerName: customerName ?? 'العميل'),
    );
  }
}

class _SendMessageDialogState extends State<SendMessageDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رسالة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // TODO: Send message via Cubit/API
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال الرسالة بنجاح'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  Text(
                    'إرسال رسالة للعميل',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
              const SizedBox(height: 20),
              // Message Content Label
              Text(
                'محتوى الرسالة',
                style: AppTextStyles.inputLabel,
              ),
              const SizedBox(height: 8),
              // Text Input Area
              TextField(
                controller: _messageController,
                maxLines: 6,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'اكتب تفاصيل العرض أو استفسار للعميل...',
                  hintStyle: AppTextStyles.inputHint,
                  filled: true,
                  fillColor: context.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.inputBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.inputBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              // Send Button
              PrimaryButton(
                text: 'إرسال',
                onPressed: _handleSend,
              ),
              const SizedBox(height: 16),
              // Information Text
              Center(
                child: Text(
                  'سيتم تنبيه العميل بوجود رسالة جديدة منك',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

