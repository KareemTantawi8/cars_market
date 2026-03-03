import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Message Bubble Widget
class MessageBubble extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool isSentByMe;
  final String? imageUrl;
  final String? senderImageUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isSentByMe,
    this.imageUrl,
    this.senderImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return _buildImageMessage(context);
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            _buildProfilePicture(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSentByMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSentByMe
                        ? AppColors.chatBubbleUser
                        : (isDark
                            ? AppColors.chatBubbleVendor
                            : AppColors.lightChatBubbleVendor),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSentByMe ? 4 : 16),
                      bottomRight: Radius.circular(isSentByMe ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    message,
                    style: AppTextStyles.chatMessage.copyWith(
                      color: isSentByMe ? Colors.white : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: AppTextStyles.chatTimestamp.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 8),
            _buildProfilePicture(context),
          ],
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stackTrace) {
                        return Container(
                          height: 200,
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
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: AppTextStyles.chatTimestamp.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildProfilePicture(context),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.surfaceBg,
      ),
      child: senderImageUrl != null
          ? ClipOval(
              child: Image.network(
                senderImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) =>
                    _buildPlaceholder(context),
              ),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 20,
      color: context.textSecondary,
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
