import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
      return _buildImageMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            _buildProfilePicture(),
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
                        : AppColors.chatBubbleVendor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSentByMe ? 4 : 16),
                      bottomRight: Radius.circular(isSentByMe ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    message,
                    style: AppTextStyles.chatMessage,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: AppTextStyles.chatTimestamp,
                ),
              ],
            ),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 8),
            _buildProfilePicture(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageMessage() {
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: AppColors.surfaceColor,
                          child: const Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: AppTextStyles.chatTimestamp,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildProfilePicture(),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceColor,
      ),
      child: senderImageUrl != null
          ? ClipOval(
              child: Image.network(
                senderImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return const Icon(
      Icons.person,
      size: 20,
      color: AppColors.textSecondary,
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
          Expanded(child: Divider(color: AppColors.dividerColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              style: AppTextStyles.caption,
            ),
          ),
          Expanded(child: Divider(color: AppColors.dividerColor)),
        ],
      ),
    );
  }
}

