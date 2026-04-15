import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// فقاعة رسالة دردشة — مرسل (أنت) مقابل مستلم (الطرف الآخر)، بعرض محدود ومحاذاة واضحة.
class MessageBubble extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool isSentByMe;
  final String? imageUrl;
  final String? senderImageUrl;

  /// اسم الطرف الآخر (يُعرض فوق رسائله فقط).
  final String? peerDisplayName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isSentByMe,
    this.imageUrl,
    this.senderImageUrl,
    this.peerDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildImageMessage(context);
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxW = MediaQuery.sizeOf(context).width * 0.8;

    final bubbleBg = isSentByMe
        ? AppColors.primaryColor
        : (isDark
            ? AppColors.chatBubbleVendor
            : AppColors.lightChatBubbleVendor);

    final textColor = isSentByMe ? Colors.white : cs.onSurface;

    final borderRadius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(isSentByMe ? 18 : 5),
      bottomEnd: Radius.circular(isSentByMe ? 5 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Align(
        alignment: isSentByMe
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: isSentByMe
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSentByMe)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: 4,
                    start: 2,
                    end: 2,
                  ),
                  child: Text(
                    'أنت',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                )
              else if (peerDisplayName != null &&
                  peerDisplayName!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: 4,
                    start: 2,
                    end: 2,
                  ),
                  child: Text(
                    peerDisplayName!.trim(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isSentByMe) ...[
                    _buildProfilePicture(context),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleBg,
                        borderRadius: borderRadius,
                        border: isSentByMe
                            ? null
                            : Border.all(
                                color: context.inputBorderColor.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: isSentByMe
                                ? AppColors.primaryColor.withValues(alpha: 0.22)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: isSentByMe ? 10 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.chatMessage.copyWith(
                          color: textColor,
                          height: 1.38,
                        ),
                      ),
                    ),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 8),
                    _buildProfilePicture(context),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: isSentByMe ? 4 : 0,
                  end: isSentByMe ? 0 : 4,
                ),
                child: Text(
                  timestamp,
                  style: AppTextStyles.chatTimestamp.copyWith(
                    color: context.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    final borderRadius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(16),
      topEnd: const Radius.circular(16),
      bottomStart: Radius.circular(isSentByMe ? 16 : 5),
      bottomEnd: Radius.circular(isSentByMe ? 5 : 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Align(
        alignment: isSentByMe
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: isSentByMe
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isSentByMe) ...[
                    _buildProfilePicture(context),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: context.surfaceBg,
                            child: Icon(
                              Icons.broken_image,
                              color: context.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 8),
                    _buildProfilePicture(context),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                timestamp,
                style: AppTextStyles.chatTimestamp.copyWith(
                  color: context.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSentByMe
            ? AppColors.primaryColor.withValues(alpha: 0.2)
            : context.surfaceBg,
        border: Border.all(
          color: context.inputBorderColor.withValues(alpha: 0.4),
        ),
      ),
      child: senderImageUrl != null && senderImageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: senderImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholder(context),
                errorWidget: (_, __, ___) => _buildPlaceholder(context),
              ),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 17,
      color: isSentByMe ? AppColors.primaryColor : context.textSecondary,
    );
  }
}

/// Date Separator Widget
class DateSeparator extends StatelessWidget {
  final String date;

  const DateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Theme.of(context).dividerColor),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              style: AppTextStyles.caption,
            ),
          ),
          Expanded(
            child: Divider(color: Theme.of(context).dividerColor),
          ),
        ],
      ),
    );
  }
}
