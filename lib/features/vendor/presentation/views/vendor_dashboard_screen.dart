import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Vendor Dashboard Screen
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Sample data for the graph
  final List<double> weeklyData = [120, 80, 150, 90, 140, 100, 130];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(
          'لوحة التحكم',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
            },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.notificationDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: context.textSecondary,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'لوحة التحكم'),
            Tab(text: 'الملف الشخصي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          _buildDashboardTab(),
          // Profile Tab
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Information Section
            _buildStoreInfoSection(),
            const SizedBox(height: 24),
            // Store Performance Section
            _buildPerformanceSection(),
            const SizedBox(height: 24),
            // Subscription Section
            _buildSubscriptionSection(),
            const SizedBox(height: 24),
            // Quick Links Section
            _buildQuickLinksSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and Info
            _buildProfileHeader(),
            const SizedBox(height: 24),
            // Store Information
            _buildProfileStoreInfo(),
            const SizedBox(height: 24),
            // Account Settings
            _buildProfileSettings(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.surfaceBg,
                ),
                child: Icon(
                  Icons.store,
                  color: context.textSecondary,
                  size: 50,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'قطع غيار الأهرام',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'بائع معتمد - القاهرة، مصر',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnlineIndicator(isOnline: true, size: 8),
                const SizedBox(width: 6),
                Text(
                  'متصل الآن',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStoreInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات المتجر',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone, 'رقم الهاتف', '01012345678'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'العنوان', 'القاهرة، مصر'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.star, 'التقييم', '4.8/5'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'سرعة الرد', '15 دقيقة'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.edit,
            title: 'تعديل الملف الشخصي',
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'الإشعارات',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.lock,
            title: 'تغيير كلمة المرور',
            onTap: () {
              // TODO: Navigate to change password
            },
          ),
          const Divider(height: 24),
          _buildThemeSettingItem(context),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            titleColor: AppColors.error,
            onTap: () {
              NavigationService.navigateToLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingItem(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = switch (themeCubit.state) {
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
      ThemeMode.system => 'تلقائي',
    };
    return InkWell(
      onTap: () => _showThemePicker(context, themeCubit),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المظهر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeCubit themeCubit) {
    final options = [
      (ThemeMode.light, 'فاتح', Icons.light_mode_outlined),
      (ThemeMode.dark, 'داكن', Icons.dark_mode_outlined),
      (ThemeMode.system, 'تلقائي', Icons.brightness_auto_outlined),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر المظهر',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                ...options.map((e) {
                  final (mode, label, icon) = e;
                  final isSelected = themeCubit.state == mode;
                  return ListTile(
                    leading: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(ctx).colorScheme.primary
                          : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary,
                            size: 24,
                          )
                        : null,
                    onTap: () {
                      themeCubit.setThemeMode(mode);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: titleColor ?? context.textPrimary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: titleColor ?? context.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً، قطع غيار الأهرام',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'بائع معتمد - القاهرة، مصر',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OnlineIndicator(isOnline: true, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        'متصل الآن',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.surfaceBg,
                ),
                child: Icon(
                  Icons.store,
                  color: context.textSecondary,
                  size: 32,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: OnlineIndicator(isOnline: true, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أداء المتجر',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        // Performance Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.access_time,
                iconColor: AppColors.warning,
                title: 'سرعة الرد',
                value: '١٥ دقيقة',
                change: '-5%',
                changeColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.chat_bubble,
                iconColor: AppColors.primaryColor,
                title: 'إجمالي المحادثات',
                value: '١,٢٥٠',
                change: '+۱۲%',
                changeColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Rating Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.ratingStar, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التقييم العام',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '٤.٨/٥',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RatingStars(rating: 4.8, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Weekly Activity Graph
        _buildWeeklyActivityGraph(),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String change,
    required Color changeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTextStyles.headingSmall,
              ),
              Text(
                change,
                style: AppTextStyles.caption.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نشاط المحادثات الأسبوعي',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    '٨٥٠ محادثة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+15%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 180,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDayLabel('سبت'),
              _buildDayLabel('أحد'),
              _buildDayLabel('اثنين'),
              _buildDayLabel('ثلاثاء'),
              _buildDayLabel('أربعاء'),
              _buildDayLabel('خميس'),
              _buildDayLabel('جمعة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String day) {
    return Text(
      day,
      style: AppTextStyles.captionSmall,
    );
  }

  Widget _buildSubscriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الاشتراك والخدمات',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.ratingStar, size: 20),
              const SizedBox(width: 8),
              Text(
                'الباقة الحالية: ',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'التاجر المميز (Gold)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.ratingStar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'صلاحية الاشتراك',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.5, // 14 days out of 28
                  backgroundColor: context.surfaceBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '١٤ يوم متبقية',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'تجديد الاشتراك أو الترقية',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.subscriptionPlans);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'روابط سريعة',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        _buildQuickLinkCard(
          icon: Icons.inventory_2,
          iconColor: AppColors.primaryColor,
          title: 'إدارة المخزون والقطع',
          onTap: () {
            // TODO: Navigate to inventory management
          },
        ),
        const SizedBox(height: 12),
        _buildQuickLinkCard(
          icon: Icons.store,
          iconColor: Colors.purple,
          title: 'تعديل ملف المتجر',
          onTap: () {
            // TODO: Navigate to edit store profile
          },
        ),
        const SizedBox(height: 12),
        _buildQuickLinkCard(
          icon: Icons.chat_bubble,
          iconColor: AppColors.primaryColor,
          title: 'المحادثات',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.chatList);
          },
        ),
        const SizedBox(height: 12),
        _buildQuickLinkCard(
          icon: Icons.inbox,
          iconColor: AppColors.warning,
          title: 'الطلبات الواردة',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.vendorIncomingRequests);
          },
        ),
        const SizedBox(height: 12),
        _buildQuickLinkCard(
          icon: Icons.headset_mic,
          iconColor: AppColors.success,
          title: 'الدعم الفني والشكاوى',
          onTap: () {
            // TODO: Navigate to support
          },
        ),
      ],
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

}

