import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'online_indicator.dart';

/// Chat Item Widget – fully theme-aware
class ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String timestamp;
  final String? imageUrl;
  final bool isOnline;
  final bool isVerified;
  final int? unreadCount;
  final bool isRead;
  final VoidCallback? onTap;

  const ChatItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    this.imageUrl,
    this.isOnline = false,
    this.isVerified = false,
    this.unreadCount,
    this.isRead = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile Picture
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withOpacity(0.1),
                  ),
                  child: imageUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildPlaceholder(cs),
                            errorWidget: (_, __, ___) => _buildPlaceholder(cs),
                          ),
                        )
                      : _buildPlaceholder(cs),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: OnlineIndicator(isOnline: true, size: 14),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: AppColors.primaryColor,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        timestamp,
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount != null && unreadCount! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else if (isRead)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: cs.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Icon(
      Icons.person,
      color: cs.primary.withOpacity(0.6),
      size: 28,
    );
  }
}
