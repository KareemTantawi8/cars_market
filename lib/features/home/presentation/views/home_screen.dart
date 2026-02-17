import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';
import '../../../../shared/widgets/common/supplier_card.dart';
import '../../../../shared/widgets/common/app_logo.dart';
import '../../../../shared/widgets/common/rating_stars.dart';
import '../cubit/search_cubit.dart';
import '../cubit/category_cubit.dart';
import '../../data/models/category_models.dart';
import '../../data/models/supplier_model.dart';

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
            if (state is SearchError) {
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
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, searchState) {
                    // Show search results if search was successful
                    if (searchState is SearchSuccess) {
                      return _buildSearchResultsView(searchState);
                    }
                    
                    // Otherwise show the search form and available suppliers
                    return SingleChildScrollView(
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
                    );
                  },
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
            switch (index) {
              case 0:
                // Home - stay on current screen
                break;
              case 1:
                // My Ads - TODO: Navigate to My Ads screen
                break;
              case 2:
                // Chat - Navigate to Chat List
                Navigator.pushNamed(context, AppRoutes.chatList);
                break;
              case 3:
                // Profile
                Navigator.pushNamed(context, AppRoutes.profile);
                break;
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
              label: 'المحادثات',
              icon: Icons.chat_bubble,
              route: AppRoutes.chatList,
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
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
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
          // Title
          Text(
            'سوق القطع',
            style: AppTextStyles.headingMedium,
          ),
          // Car Icon
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
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Title
        Text(
          'طلب قطعة غيار',
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          'املأ البيانات وسيقوم التجار بالرد عليك فوراً',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        // Part Name Field
        Text(
          'ما هي القطعة التي تبحث عنها؟',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _partNameController,
          decoration: InputDecoration(
            hintText: 'مثال: تيل فرامل، مساعدين، فانوس...',
            hintStyle: AppTextStyles.inputHint,
            suffixIcon: const Icon(
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
                  // Brand and Model Row (Left: Brand, Right: Model)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectionField(
                          label: 'الماركة',
                          value: state.selectedBrand?.displayName ?? 'تويوتا',
                          isPlaceholder: state.selectedBrand == null,
                          onTap: () => _showBrandSelectionDialog(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionField(
                          label: 'الموديل',
                          value: state.selectedModel?.displayName ?? 'كورولا',
                          isPlaceholder: state.selectedModel == null,
                          onTap: () => _showModelSelectionDialog(state),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Year and Governorate Row (Left: Governorate, Right: Year)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectionField(
                          label: 'المحافظة',
                          value: state.selectedGovernorate?.displayName ?? 'القاهرة',
                          isPlaceholder: state.selectedGovernorate == null,
                          onTap: () => _showGovernorateSelectionDialog(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionField(
                          label: 'السنة',
                          value: state.selectedYear?.displayName ?? '2024',
                          isPlaceholder: state.selectedYear == null,
                          onTap: () => _showYearSelectionDialog(state),
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
        // Submit Button
        BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final isLoading = state is SearchLoading;
            return PrimaryButton(
              text: 'إرسال الطلب الآن',
              icon: Icons.arrow_forward,
              onPressed: isLoading ? null : _handleSearch,
              isLoading: isLoading,
            );
          },
        ),
        const SizedBox(height: 32),
        // Info Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.inputBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اطلب قطعتك بسهولة',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اطلب قطعتك وهيوصلك ردود من التجار في دقايق بأفضل الأسعار',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildSearchResultsView(SearchSuccess state) {
    final suppliers = state.response.suppliers;
    final request = state.request;
    
    // Get active filters
    final activeFilters = <String>[];
    if (request.partName != null && request.partName!.isNotEmpty) {
      activeFilters.add(request.partName!);
    }
    if (request.brandName != null && request.brandName!.isNotEmpty) {
      activeFilters.add(request.brandName!);
    }
    if (request.modelName != null && request.modelName!.isNotEmpty) {
      activeFilters.add(request.modelName!);
    }
    if (request.yearName != null && request.yearName!.isNotEmpty) {
      activeFilters.add(request.yearName!);
    }
    if (request.governorateName != null && request.governorateName!.isNotEmpty) {
      activeFilters.add(request.governorateName!);
    }

    return Column(
      children: [
        // Search Form (Collapsed/Summary)
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نتائج البحث',
                    style: AppTextStyles.headingMedium,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Clear search and show form again
                      context.read<SearchCubit>().clearSearch();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('تعديل البحث'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              if (activeFilters.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeFilters.map((filter) {
                    return Chip(
                      label: Text(
                        filter,
                        style: AppTextStyles.bodySmall,
                      ),
                      backgroundColor: AppColors.cardColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        // Search Results
        Expanded(
          child: suppliers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد نتائج',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'لم نجد موردين يطابقون معايير البحث',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'تعديل البحث',
                        onPressed: () {
                          context.read<SearchCubit>().clearSearch();
                        },
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildSearchResultCard(supplier),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(SupplierModel supplier) {
    return Card(
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: supplier.imageUrl != null
                    ? Image.network(
                        supplier.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              // Online Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: supplier.isOnline ? AppColors.success : AppColors.offline,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        supplier.isOnline ? 'أونلاين' : 'أوفلاين',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  supplier.name,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 8),
                // Rating
                Row(
                  children: [
                    RatingStars(
                      rating: supplier.rating,
                      size: 16,
                      reviewCount: supplier.reviewCount,
                    ),
                  ],
                ),
                if (supplier.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier.distance != null
                              ? '${supplier.location} (${supplier.distance})'
                              : supplier.location,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                if (supplier.supportedBrands.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Brands
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'الماركات: ${supplier.supportedBrands.join('، ')}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Contact Button
                PrimaryButton(
                  text: 'تواصل مع التاجر',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.vendorProfile,
                      arguments: {
                        'vendorId': supplier.id.toString(),
                        'vendorName': supplier.name,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: AppColors.surfaceColor,
      child: const Icon(
        Icons.store,
        size: 64,
        color: AppColors.textSecondary,
      ),
    );
  }
}
