import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/bottom_nav_bar.dart';
import '../../../my_ads/presentation/views/my_ads_screen.dart';
import '../../../browse_ads/presentation/views/browse_ads_screen.dart';
import '../../../chat/presentation/views/chat_list_screen.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../profile/presentation/views/user_profile_screen.dart';
import '../cubit/search_cubit.dart';
import '../cubit/category_cubit.dart';
import '../../data/models/category_models.dart';
import '../../../../shared/widgets/common/notification_bell.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../../core/utils/constants.dart';

/// Home Screen (User)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _partNameController = TextEditingController();
  int _currentNavIndex = 0;

  // Rate limiting: max 10 requests total, 30s cooldown between each
  static const int _maxRequests = 10;
  static const Duration _cooldown = Duration(seconds: 30);
  final List<DateTime> _requestTimestamps = [];
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  /// Bottom nav order: الرئيسية، الإعلانات، إعلاناتي، المحادثات، حسابي
  static const int _chatsTabIndex = 3;

  @override
  void initState() {
    super.initState();
    // Load initial data (brands and governorates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryCubit>().loadInitialData();
      _bindCustomerRealtime();
    });
  }

  void _bindCustomerRealtime() {
    if (StorageService.getUserType() == AppConstants.userTypeVendor) return;
    RealtimeService.instance.onCustomerSearchAccepted = _onSearchRequestAccepted;
    RealtimeService.instance.onCustomerNewMessage = _onNewMessageFromReverb;
    unawaited(RealtimeService.instance.start());
  }

  Future<void> _onSearchRequestAccepted(Map<String, dynamic> data) async {
    InAppNotificationService.showSearchAcceptedReverb(data);
  }

  Future<void> _onNewMessageFromReverb(Map<String, dynamic> data) async {
    InAppNotificationService.showNewMessageReverb(data);
    if (!mounted) return;
    if (_currentNavIndex == _chatsTabIndex) {
      try {
        context.read<ChatCubit>().getChats();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (StorageService.getUserType() != AppConstants.userTypeVendor) {
      RealtimeService.instance.onCustomerSearchAccepted = null;
      RealtimeService.instance.onCustomerNewMessage = null;
    }
    _partNameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleSearch() {
    if (_requestTimestamps.length >= _maxRequests) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد وصلت للحد الأقصى (١٠ طلبات). يرجى التواصل مع الدعم.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_requestTimestamps.isNotEmpty) {
      final lastRequest = _requestTimestamps.last;
      final diff = DateTime.now().difference(lastRequest);
      if (diff < _cooldown) {
        return;
      }
    }

    final categoryState = context.read<CategoryCubit>().state;
    final searchCubit = context.read<SearchCubit>();

    if (categoryState is! CategoryLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل البيانات، يرجى الانتظار قليلاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (categoryState.selectedBrand == null ||
        categoryState.selectedModel == null ||
        categoryState.selectedYear == null ||
        categoryState.selectedGovernorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء اختيار الماركة والموديل وسنة السيارة والمحافظة',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    searchCubit.searchSuppliers(
      partName: _partNameController.text.trim().isEmpty
          ? null
          : _partNameController.text.trim(),
      brandId: categoryState.selectedBrand!.id,
      modelId: categoryState.selectedModel!.id,
      yearId: categoryState.selectedYear!.id,
      governorateId: categoryState.selectedGovernorate!.id,
      brandName: categoryState.selectedBrand!.displayName,
      modelName: categoryState.selectedModel!.displayName,
      yearName: categoryState.selectedYear!.displayName,
      governorateName: categoryState.selectedGovernorate!.displayName,
    );
  }

  /// Rate limit applies only after the server accepts the search (see [BlocListener]).
  void _registerSuccessfulSearchRequest() {
    if (!mounted) return;
    setState(() {
      _requestTimestamps.add(DateTime.now());
    });
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إرسال طلبك (${_requestTimestamps.length}/$_maxRequests). سيتواصل معك التجار قريباً.',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = _cooldown.inSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds <= 0) {
          _countdownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  bool get _isInCooldown => _countdownSeconds > 0;

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
      backgroundColor: context.cardBg,
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
                color: context.textHint,
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
                          color: context.textSecondary,
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
                                  : context.textPrimary,
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
              _registerSuccessfulSearchRequest();
              context.read<SearchCubit>().clearSearch();
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeContent(),
            const BrowseAdsScreen(),
            const MyAdsScreen(),
            const ChatListScreen(loadOnInit: false),
            const UserProfileScreen(isEmbeddedInTab: true),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() => _currentNavIndex = index);
            if (index == _chatsTabIndex) {
              context.read<ChatCubit>().getChats();
            }
          },
          items: const [
            BottomNavItem(
              label: 'الرئيسية',
              icon: Icons.home,
              route: '/home',
            ),
            BottomNavItem(
              label: 'الإعلانات',
              icon: Icons.directions_car_outlined,
              route: '/browse-ads',
            ),
            BottomNavItem(
              label: 'إعلاناتي',
              icon: Icons.sell_outlined,
              route: '/my-ads',
            ),
            BottomNavItem(
              label: 'المحادثات',
              icon: Icons.chat_bubble,
              route: '/chat',
            ),
            BottomNavItem(
              label: 'حسابي',
              icon: Icons.person,
              route: '/profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                ],
              ),
            ),
          ),
        ],
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
          NotificationBell(iconColor: context.textPrimary),
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
            child: Icon(
              Icons.directions_car,
              color: context.textPrimary,
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
            color: context.textSecondary,
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
            suffixIcon: Icon(
              Icons.search,
              color: context.textSecondary,
            ),
            filled: true,
            fillColor: context.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.inputBorderColor),
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
                          value:
                              state.selectedBrand?.displayName ?? 'اختر الماركة',
                          isPlaceholder: state.selectedBrand == null,
                          onTap: () => _showBrandSelectionDialog(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionField(
                          label: 'الموديل',
                          value:
                              state.selectedModel?.displayName ?? 'اختر الموديل',
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
                          value: state.selectedGovernorate?.displayName ??
                              'اختر المحافظة',
                          isPlaceholder: state.selectedGovernorate == null,
                          onTap: () => _showGovernorateSelectionDialog(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionField(
                          label: 'السنة',
                          value: state.selectedYear?.displayName ?? 'اختر السنة',
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
        // Submit Button with countdown
        BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final isLoading = state is SearchLoading;
            final requestCount = _requestTimestamps.length;
            return Column(
              children: [
                if (_isInCooldown) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'يمكنك الإرسال بعد $_countdownSeconds ثانية  ($requestCount/$_maxRequests طلبات)',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (requestCount >= _maxRequests) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Text(
                      'وصلت للحد الأقصى ($requestCount/$_maxRequests طلبات)',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                PrimaryButton(
                  text: _isInCooldown
                      ? 'انتظر $_countdownSeconds ث...'
                      : requestCount >= _maxRequests
                          ? 'تم الوصول للحد الأقصى'
                          : 'إرسال الطلب الآن',
                  icon: Icons.arrow_forward,
                  onPressed: (isLoading || _isInCooldown || requestCount >= _maxRequests) ? null : _handleSearch,
                  isLoading: isLoading,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        // Info Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.inputBorderColor,
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
                        color: context.textSecondary,
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
          color: context.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.inputBorderColor),
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
            Icon(
              Icons.arrow_drop_down,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

}
