import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';
import '../../../../shared/widgets/common/supplier_card.dart';

/// Home Screen (User)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _partNameController = TextEditingController();
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedYear;
  String? _selectedGovernorate;
  int _currentNavIndex = 0;

  @override
  void dispose() {
    _partNameController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    // Navigate to search results screen
    Navigator.pushNamed(context, AppRoutes.searchResults);
  }

  Future<void> _showSelectionDialog({
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text(title, style: AppTextStyles.headingSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(option, style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context, option),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const Text(
                    'سوق القطع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  // Notification Icon
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          // TODO: Navigate to notifications
                        },
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Section
                    Text(
                      'ابحث عن قطع غيار',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حدد مواصفات سيارتك للوصول لأفضل الموردين',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    // Part Name Field
                    TextFormField(
                      controller: _partNameController,
                      decoration: InputDecoration(
                        labelText: 'اسم القطعة',
                        hintText: 'مثال: تيل فرامل، مساعدين...',
                        hintStyle: AppTextStyles.inputHint,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorderFocused,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Brand and Model Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectionField(
                            label: 'الماركة',
                            value: _selectedBrand ?? 'تويوتا',
                            onTap: () {
                              _showSelectionDialog(
                                title: 'اختر الماركة',
                                options: ['تويوتا', 'هيونداي', 'نيسان', 'ميتسوبيشي'],
                                onSelected: (value) {
                                  setState(() => _selectedBrand = value);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectionField(
                            label: 'الموديل',
                            value: _selectedModel ?? 'كورولا',
                            onTap: () {
                              _showSelectionDialog(
                                title: 'اختر الموديل',
                                options: ['كورولا', 'كامري', 'لاندكروزر'],
                                onSelected: (value) {
                                  setState(() => _selectedModel = value);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Year and Governorate Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectionField(
                            label: 'السنة',
                            value: _selectedYear ?? '2024',
                            onTap: () {
                              final years = List.generate(
                                10,
                                (index) => (2024 - index).toString(),
                              );
                              _showSelectionDialog(
                                title: 'اختر السنة',
                                options: years,
                                onSelected: (value) {
                                  setState(() => _selectedYear = value);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectionField(
                            label: 'المحافظة',
                            value: _selectedGovernorate ?? 'القاهرة',
                            onTap: () {
                              _showSelectionDialog(
                                title: 'اختر المحافظة',
                                options: ['القاهرة', 'الجيزة', 'الإسكندرية'],
                                onSelected: (value) {
                                  setState(() => _selectedGovernorate = value);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search Button
                    PrimaryButton(
                      text: 'ابحث الآن',
                      icon: Icons.search,
                      onPressed: _handleSearch,
                    ),
                    const SizedBox(height: 32),
                    // Available Suppliers Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الموردين المتاحين',
                          style: AppTextStyles.headingSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to all suppliers
                          },
                          child: Text(
                            'عرض الكل',
                            style: AppTextStyles.link,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Suppliers List
                    SupplierCard(
                      name: 'مصر لقطع الغيار',
                      isOnline: true,
                      rating: 4.8,
                      reviewCount: 120,
                      supportedBrands: ['تويوتا', 'هيونداي', 'ميتسوبيشي'],
                      location: 'حي الدقي، الجيزة',
                      distance: '3.2 كم',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.vendorProfile,
                          arguments: {
                            'vendorId': 'vendor_1',
                            'vendorName': 'مصر لقطع الغيار',
                          },
                        );
                      },
                    ),
                    SupplierCard(
                      name: 'مركز الأمل للصيانة',
                      isOnline: false,
                      rating: 4.5,
                      reviewCount: 85,
                      supportedBrands: ['بي إم دبليو', 'مرسيدس'],
                      location: 'مدينة نصر، القاهرة',
                      distance: '5.7 كم',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.vendorProfile,
                          arguments: {
                            'vendorId': 'vendor_2',
                            'vendorName': 'مركز الأمل للصيانة',
                          },
                        );
                      },
                    ),
                    SupplierCard(
                      name: 'المتحدة للاستيراد',
                      isOnline: true,
                      rating: 4.2,
                      reviewCount: 42,
                      supportedBrands: ['أوبل', 'سكودا'],
                      location: 'حي المعادي، القاهرة',
                      distance: '8.1 كم',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.vendorProfile,
                          arguments: {
                            'vendorId': 'vendor_3',
                            'vendorName': 'المتحدة للاستيراد',
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          // Handle navigation based on index
          if (index == 0) {
            // Home - stay on current screen
          } else if (index == 1) {
            // Orders - TODO: Navigate to orders screen
          } else if (index == 2) {
            // Garage - TODO: Navigate to garage screen
          } else if (index == 3) {
            // Profile
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
        items: const [
          BottomNavItem(
            label: 'الرئيسية',
            icon: Icons.home,
            route: '/home',
          ),
          BottomNavItem(
            label: 'طلباتي',
            icon: Icons.shopping_cart,
            route: '/orders',
          ),
          BottomNavItem(
            label: 'جراجي',
            icon: Icons.directions_car,
            route: '/garage',
          ),
          BottomNavItem(
            label: 'حسابي',
            icon: Icons.person,
            route: AppRoutes.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTextStyles.inputLabel,
            ),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.input,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

