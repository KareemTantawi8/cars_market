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
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Load chats when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatCubit>().getChats();
    });
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    // TODO: Implement proper date formatting
    return 'منذ قليل';
  }

  String _getChatName(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    if (userType == AppConstants.userTypeVendor) {
      // Vendor sees customer name
      return chat['customer']?['name'] ?? 'عميل';
    } else {
      // Customer sees vendor company name
      return chat['vendor']?['company_name'] ?? 'تاجر';
    }
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
                        final lastMessage = chat['last_message'] as Map<String, dynamic>?;
                        final lastMessageBody = lastMessage?['body']?.toString() ?? '';
                        final lastMessageAt = chat['last_message_at']?.toString() ?? '';
                        final unreadCount = chat['unread_count'] as int? ?? 0;
                        final isOnline = chat['vendor']?['is_online'] ?? false;

                        return ChatItem(
                          name: chatName,
                          lastMessage: lastMessageBody,
                          timestamp: _formatTimestamp(lastMessageAt),
                          isOnline: isOnline,
                          unreadCount: unreadCount > 0 ? unreadCount : null,
                          isRead: unreadCount == 0,
                  imageUrl: null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                                'chatId': chatId, // Use actual chat ID from API
                                'chatName': chatName,
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

