import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/common/chat_item.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../cubit/chat_cubit.dart';

/// Chat List Screen
class ChatListScreen extends StatefulWidget {
  /// When false (e.g. inside [HomeScreen]'s [IndexedStack]), the parent should
  /// call [ChatCubit.getChats] when the tab becomes visible — otherwise the API
  /// would only run once at app launch while another tab is shown.
  final bool loadOnInit;

  const ChatListScreen({super.key, this.loadOnInit = true});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.loadOnInit) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatCubit>().getChats();
    });
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic>? _asChatMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inHours < 1) return 'منذ ${difference.inMinutes} د';
      if (difference.inDays < 1) return 'منذ ${difference.inHours} س';
      if (difference.inDays == 1) return 'أمس';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  String _getChatName(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    if (userType == AppConstants.userTypeVendor) {
      // Vendor sees customer name
      return chat['customer']?['name']?.toString() ?? 'عميل';
    } else {
      // Customer sees vendor company name
      return chat['vendor']?['company_name']?.toString() ?? 'تاجر';
    }
  }

  String _inboxPreviewLastMessage(Map<String, dynamic> chat) {
    final last = _asChatMap(chat['last_message']);
    final body = last?['body']?.toString();
    if (body != null && body.isNotEmpty) return body;
    return '';
  }

  String _inboxLastActivityAt(Map<String, dynamic> chat) {
    final direct = chat['last_message_at']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final last = _asChatMap(chat['last_message']);
    final nested = last?['created_at']?.toString();
    return nested ?? '';
  }

  bool _inboxPeerOnline(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    if (userType == AppConstants.userTypeVendor) {
      return chat['customer']?['is_online'] == true;
    }
    return chat['vendor']?['is_online'] == true;
  }

  String? _inboxAvatarUrl(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    final peer = userType == AppConstants.userTypeVendor
        ? (chat['customer'] ?? chat['buyer'] ?? chat['client'])
        : (chat['vendor'] ?? chat['seller'] ?? chat['shop']);
    if (peer is! Map) return null;
    for (final key in ['avatar', 'image_url', 'image', 'logo', 'photo', 'profile_image']) {
      final v = peer[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  bool _inboxPeerIsVerified(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    // Only vendors can be verified; customers never show a verified badge.
    if (userType == AppConstants.userTypeVendor) return false;
    final vendor = chat['vendor'] ?? chat['seller'] ?? chat['shop'];
    if (vendor is! Map) return false;
    return vendor['is_verified'] == true ||
        vendor['verified'] == true ||
        vendor['is_certified'] == true;
  }

  /// Returns the vendor record ID (vendors.id) for navigating to the vendor profile.
  /// Only meaningful when the current user is a customer.
  int? _inboxVendorId(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    if (userType == AppConstants.userTypeVendor) return null;
    final vendor = chat['vendor'] ?? chat['seller'] ?? chat['shop'];
    if (vendor is! Map) return null;
    final raw = vendor['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  String? _inboxPeerPhone(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    final peer = userType == AppConstants.userTypeVendor
        ? (chat['customer'] ?? chat['buyer'] ?? chat['client'])
        : (chat['vendor'] ?? chat['seller'] ?? chat['shop']);
    if (peer is! Map) return null;
    for (final key in [
      'phone',
      'mobile',
      'phone_number',
      'tel',
      'shop_phone',
      'shop_mobile',
      'company_phone',
    ]) {
      final v = peer[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final user = peer['user'];
    if (user is Map) {
      for (final key in ['phone', 'mobile', 'phone_number']) {
        final v = user[key]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: Navigate to settings
          },
        ),
        title: Text('المحادثات', style: AppTextStyles.headingMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state is ChatError) {
                  CustomToast.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatsLoaded) {
                  final chats = state.chats;

                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: context.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد محادثات بعد',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ChatCubit>().getChats();
                    },
                    child: ListView.separated(
                      itemCount: chats.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: AppColors.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final chatId = chat['id']?.toString() ?? '';
                        final chatName = _getChatName(chat);
                        final lastMessageBody = _inboxPreviewLastMessage(chat);
                        final lastMessageAt = _inboxLastActivityAt(chat);
                        final unreadCount = _toInt(chat['unread_count']);
                        final isOnline = _inboxPeerOnline(chat);
                        final isVerified = _inboxPeerIsVerified(chat);
                        final avatarUrl = _inboxAvatarUrl(chat);

                        return ChatItem(
                          name: chatName,
                          lastMessage: lastMessageBody,
                          timestamp: _formatTimestamp(lastMessageAt),
                          isOnline: isOnline,
                          isVerified: isVerified,
                          unreadCount: unreadCount > 0 ? unreadCount : null,
                          isRead: unreadCount == 0,
                          imageUrl: avatarUrl,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.chatRoom,
                              arguments: {
                                'chatId': chatId,
                                'chatName': chatName,
                                'peerPhone': _inboxPeerPhone(chat),
                                'peerIsVerified': isVerified,
                                'peerAvatarUrl': avatarUrl,
                                'peerVendorId': _inboxVendorId(chat),
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'إعادة المحاولة',
                          onPressed: () {
                            context.read<ChatCubit>().getChats();
                          },
                        ),
                      ],
                    ),
                    );
                }

                return const SizedBox.shrink();
              },
            ),
    );
  }
}

