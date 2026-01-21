import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';

/// Vendor Dashboard Screen
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _selectedNavIndex = 0;

  // Sample data for the graph
  final List<double> weeklyData = [120, 80, 150, 90, 140, 100, 130];

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
          'لوحة التحكم',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildStoreInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
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
                    color: AppColors.textSecondary,
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
                  color: AppColors.surfaceColor,
                ),
                child: const Icon(
                  Icons.store,
                  color: AppColors.textSecondary,
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
            color: AppColors.cardColor,
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
                      const Text(
                        '٤.٨/٥',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
        color: AppColors.cardColor,
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
              color: AppColors.textSecondary,
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
        color: AppColors.cardColor,
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
        color: AppColors.cardColor,
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
                  backgroundColor: AppColors.surfaceColor,
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
          color: AppColors.cardColor,
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
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
              _buildNavItem(Icons.home, 'الرئيسية', 0, () {}),
              _buildNavItem(Icons.chat_bubble, 'المحادثات', 1, () {
                Navigator.pushNamed(context, AppRoutes.chatList);
              }),
              _buildNavItem(Icons.add, 'أضف قطعة', 2, () {}),
              _buildNavItem(Icons.bar_chart, 'التقارير', 3, () {}),
              _buildNavItem(Icons.person, 'نشاط', 4, () {}),
              _buildNavItem(Icons.account_circle, 'الحساب', 5, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, VoidCallback onTap) {
    final isSelected = index == _selectedNavIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedNavIndex = index);
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.captionSmall.copyWith(
                  color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

