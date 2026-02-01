import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';
import '../../../../shared/widgets/common/supplier_card.dart';
import '../../../../shared/widgets/common/app_logo.dart';
import '../cubit/search_cubit.dart';
import '../cubit/category_cubit.dart';
import '../../data/models/category_models.dart';

/// Home Screen (User)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _partNameController = TextEditingController();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data (brands and governorates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryCubit>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _partNameController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final categoryState = context.read<CategoryCubit>().state;
    final searchCubit = context.read<SearchCubit>();

    if (categoryState is CategoryLoaded) {
      searchCubit.searchSuppliers(
        partName: _partNameController.text.trim().isEmpty
            ? null
            : _partNameController.text.trim(),
        brandId: categoryState.selectedBrand?.id,
        modelId: categoryState.selectedModel?.id,
        yearId: categoryState.selectedYear?.id,
        governorateId: categoryState.selectedGovernorate?.id,
        brandName: categoryState.selectedBrand?.displayName,
        modelName: categoryState.selectedModel?.displayName,
        yearName: categoryState.selectedYear?.displayName,
        governorateName: categoryState.selectedGovernorate?.displayName,
      );
    }
  }

  void _showBrandSelectionDialog(CategoryLoaded state) {
    _showSelectionBottomSheet<BrandModel>(
      title: 'اختر الماركة',
      items: state.brands,
      selectedItem: state.selectedBrand,
      getDisplayName: (brand) => brand.displayName,
      onSelected: (brand) {
        context.read<CategoryCubit>().selectBrand(brand);
      },
    );
  }

  void _showModelSelectionDialog(CategoryLoaded state) {
    if (state.selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الماركة أولاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (state.models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل الموديلات...'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    _showSelectionBottomSheet<CarModelModel>(
      title: 'اختر الموديل',
      items: state.models,
      selectedItem: state.selectedModel,
      getDisplayName: (model) => model.displayName,
      onSelected: (model) {
        context.read<CategoryCubit>().selectModel(model);
      },
    );
  }

  void _showYearSelectionDialog(CategoryLoaded state) {
    if (state.selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الموديل أولاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (state.years.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل السنوات...'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    _showSelectionBottomSheet<YearModel>(
      title: 'اختر السنة',
      items: state.years,
      selectedItem: state.selectedYear,
      getDisplayName: (year) => year.displayName,
      onSelected: (year) {
        context.read<CategoryCubit>().selectYear(year);
      },
    );
  }

  void _showGovernorateSelectionDialog(CategoryLoaded state) {
    _showSelectionBottomSheet<GovernorateModel>(
      title: 'اختر المحافظة',
      items: state.governorates,
      selectedItem: state.selectedGovernorate,
      getDisplayName: (governorate) => governorate.displayName,
      onSelected: (governorate) {
        context.read<CategoryCubit>().selectGovernorate(governorate);
      },
    );
  }

  void _showSelectionBottomSheet<T>({
    required String title,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) getDisplayName,
    required Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: AppTextStyles.headingSmall,
              ),
            ),
            const Divider(color: AppColors.dividerColor),
            // Items list
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد بيانات',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == selectedItem;
                        return ListTile(
                          title: Text(
                            getDisplayName(item),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                )
                              : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SearchCubit, SearchState>(
          listener: (context, state) {
            if (state is SearchSuccess) {
              Navigator.pushNamed(
                context,
                AppRoutes.searchResults,
                arguments: {
                  'searchRequest': state.request,
                  'searchResponse': state.response,
                },
              );
            } else if (state is SearchError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
        BlocListener<CategoryCubit, CategoryState>(
          listener: (context, state) {
            if (state is CategoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Section
                      _buildSearchSection(),
                      const SizedBox(height: 32),
                      // Available Suppliers Section
                      _buildSuppliersSection(),
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
            if (index == 3) {
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo
          const AppLogo(size: 40, withGlow: false),
          const Text(
            'سوق القطع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          // Chat Icon
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.chatList);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
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
        // Category Selection Fields
        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is CategoryLoaded) {
              return Column(
                children: [
                  // Brand and Model Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectionField(
                          label: 'الماركة',
                          value: state.selectedBrand?.displayName ?? 'اختر الماركة',
                          isPlaceholder: state.selectedBrand == null,
                          onTap: () => _showBrandSelectionDialog(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionField(
                          label: 'الموديل',
                          value: state.selectedModel?.displayName ?? 'اختر الموديل',
                          isPlaceholder: state.selectedModel == null,
                          onTap: () => _showModelSelectionDialog(state),
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
                          value: state.selectedYear?.displayName ?? 'اختر السنة',
                          isPlaceholder: state.selectedYear == null,
                          onTap: () => _showYearSelectionDialog(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionField(
                          label: 'المحافظة',
                          value: state.selectedGovernorate?.displayName ?? 'اختر المحافظة',
                          isPlaceholder: state.selectedGovernorate == null,
                          onTap: () => _showGovernorateSelectionDialog(state),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            if (state is CategoryError) {
              return Center(
                child: Column(
                  children: [
                    Text(
                      'حدث خطأ في تحميل البيانات',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        context.read<CategoryCubit>().loadInitialData();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 24),
        // Search Button
        BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final isLoading = state is SearchLoading;
            return PrimaryButton(
              text: 'ابحث الآن',
              icon: Icons.search,
              onPressed: isLoading ? null : _handleSearch,
              isLoading: isLoading,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.inputLabel.copyWith(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: isPlaceholder
                        ? AppTextStyles.inputHint
                        : AppTextStyles.input,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuppliersSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الموردين المتاحين',
              style: AppTextStyles.headingSmall,
            ),
            TextButton(
              onPressed: () {
                // Navigate to all suppliers
              },
              child: Text(
                'عرض الكل',
                style: AppTextStyles.link,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Suppliers List (sample data - will be replaced with real data)
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
    );
  }
}
