import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/chat_item.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';

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
            child: ListView(
              children: [
                ChatItem(
                  name: 'المهندس لقطع الغيار',
                  lastMessage: 'متوفر عندنا مساعدين تويوتا أصلي بالضمان...',
                  timestamp: '١١:١٥ ص',
                  isOnline: true,
                  unreadCount: 3,
                  imageUrl: null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                        'chatId': 'chat_1',
                        'vendorName': 'المهندس لقطع الغيار',
                      },
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
                ChatItem(
                  name: 'محمد كمال',
                  lastMessage: 'شكراً جزيلاً، هيوصل امتى؟',
                  timestamp: '١٠:٠٥ ص',
                  isOnline: false,
                  unreadCount: 1,
                  imageUrl: null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                        'chatId': 'chat_2',
                        'vendorName': 'محمد كمال',
                      },
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
                ChatItem(
                  name: 'مركز صيانة الأمل',
                  lastMessage: 'تم حجز موعد تغيير الزيت ليوم الثلاثاء.',
                  timestamp: 'أمس',
                  isOnline: false,
                  isRead: true,
                  imageUrl: null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                        'chatId': 'chat_3',
                        'vendorName': 'مركز صيانة الأمل',
                      },
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
                ChatItem(
                  name: 'سارة المنصوري',
                  lastMessage: 'هل السعر قابل للتفاوض البسيط؟',
                  timestamp: 'أمس',
                  isOnline: false,
                  isRead: true,
                  imageUrl: null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                        'chatId': 'chat_4',
                        'vendorName': 'سارة المنصوري',
                      },
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
                ChatItem(
                  name: 'عالم الإطارات',
                  lastMessage: 'تم شحن الطلب رقم #٤٤٣٢',
                  timestamp: 'الأحد',
                  isOnline: false,
                  isRead: true,
                  imageUrl: null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatRoom,
                      arguments: {
                        'chatId': 'chat_5',
                        'vendorName': 'عالم الإطارات',
                      },
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.dividerColor),
              ],
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
      decoration: const BoxDecoration(
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
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
                  // TODO: Navigate to profile
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

