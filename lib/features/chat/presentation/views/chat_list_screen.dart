import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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
  String _selectedFilter = 'الكل';
  int _currentNavIndex = 2; // Chats is at index 2

  final List<String> _filters = ['الكل', 'غير مقروءة', 'أرشيف'];

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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: Navigate to settings
          },
        ),
        title: Text(
          'المحادثات',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceColor,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? AppColors.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        filter,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Chat List
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
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
                  // Filter chats based on selected filter
                  List<Map<String, dynamic>> filteredChats = state.chats;
                  
                  if (_selectedFilter == 'غير مقروءة') {
                    filteredChats = state.chats.where((chat) {
                      final unreadCount = chat['unread_count'] as int? ?? 0;
                      return unreadCount > 0;
                    }).toList();
                  } else if (_selectedFilter == 'أرشيف') {
                    // TODO: Implement archive filter when API supports it
                    filteredChats = [];
                  }

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
              children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'غير مقروءة'
                                ? 'لا توجد محادثات غير مقروءة'
                                : _selectedFilter == 'أرشيف'
                                    ? 'لا توجد محادثات مؤرشفة'
                                    : 'لا توجد محادثات بعد',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
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
                      itemCount: filteredChats.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: AppColors.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new chat
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'الرئيسية',
                isSelected: false,
                onTap: () {
                  // Navigate based on user type
                  final userType = StorageService.getUserType();
                  if (userType == AppConstants.userTypeVendor) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.vendorDashboard,
                      (route) => false,
                    );
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.directions_car,
                label: 'سياراتي',
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to garage
                },
              ),
              // Spacer for FAB
              const SizedBox(width: 40),
              _buildNavItem(
                icon: Icons.chat_bubble,
                label: 'المحادثات',
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'حسابي',
                isSelected: false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

