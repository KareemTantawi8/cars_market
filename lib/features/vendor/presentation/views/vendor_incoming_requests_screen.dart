import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../cubit/vendor_requests_cubit.dart';
import '../../../home/data/repositories/search_requests_repository.dart';

/// Vendor Incoming Requests Screen
/// Shows pending search requests that match vendor's profile
class VendorIncomingRequestsScreen extends StatefulWidget {
  const VendorIncomingRequestsScreen({super.key});

  @override
  State<VendorIncomingRequestsScreen> createState() =>
      _VendorIncomingRequestsScreenState();
}

class _VendorIncomingRequestsScreenState
    extends State<VendorIncomingRequestsScreen> {
  final SearchRequestsRepository _searchRequestsRepo = SearchRequestsRepository();

  @override
  void initState() {
    super.initState();
    // Load incoming requests when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorRequestsCubit>().getIncomingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'طلبات جديدة',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications
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
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // TODO: Open menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: context.surfaceBg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'مباشر',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'طلبات بحث نشطة في منطقتك',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Requests List
          Expanded(
            child: BlocConsumer<VendorRequestsCubit, VendorRequestsState>(
              listener: (context, state) {
                if (state is VendorRequestsError) {
                  CustomToast.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is VendorRequestsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VendorRequestsLoaded) {
                  if (state.requests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: context.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات جديدة',
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
                      context.read<VendorRequestsCubit>().getIncomingRequests();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: state.requests.asMap().entries.map((entry) {
                        final request = entry.value;
                        final index = entry.key;
                        return Column(
                          children: [
                            if (index > 0) const SizedBox(height: 16),
                            _buildRequestCardFromData(request),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }

                if (state is VendorRequestsError) {
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
                            context.read<VendorRequestsCubit>().getIncomingRequests();
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
    );
  }

  Widget _buildRequestCard({
    required String requestId,
    required String customerName,
    required bool isOnline,
    required String timeAgo,
    required String status,
    required String partName,
    required String carDetails,
    required String remainingTime,
    required bool isUrgent,
    required IconData icon,
    bool isCertified = false,
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer
              Row(
                children: [
                  Icon(
                    isUrgent ? Icons.timer : Icons.timer_outlined,
                    color: isUrgent ? AppColors.error : AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'متبقي: $remainingTime د',
                    style: AppTextStyles.caption.copyWith(
                      color: isUrgent ? AppColors.error : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer Info Row
          Row(
            children: [
              // Profile Picture
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.surfaceBg,
                    ),
                    child: Center(
                      child: Text(
                        customerName[0],
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: OnlineIndicator(isOnline: true, size: 12),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isOnline)
                          Row(
                            children: [
                              OnlineIndicator(isOnline: true, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                'متصل',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.online,
                                ),
                              ),
                            ],
                          )
                        else if (isCertified)
                          Text(
                            'تاجر معتمد',
                            style: AppTextStyles.caption.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.primaryColor.withOpacity(0.2)
                                : context.surfaceBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: AppTextStyles.caption.copyWith(
                              color: isOnline
                                  ? AppColors.primaryColor
                                  : context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Part Info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القطعة المطلوبة',
                      style: AppTextStyles.caption.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: context.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          carDetails,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleReject(requestId),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: context.surfaceBg,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'تجاهل',
                    style: AppTextStyles.button.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'قبول',
                  icon: Icons.check,
                  onPressed: () => _handleAccept(requestId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCardFromData(Map<String, dynamic> request) {
    final requestId = request['id']?.toString() ?? '';
    final customer = request['customer'] as Map<String, dynamic>? ?? {};
    final customerName = customer['name']?.toString() ?? 'عميل';
    final partText = request['part_text']?.toString() ?? '';
    final brand = request['brand'] as Map<String, dynamic>?;
    final model = request['model'] as Map<String, dynamic>?;
    final carDetails = '${brand?['name'] ?? ''} ${model?['name'] ?? ''}';
    final createdAt = request['created_at']?.toString() ?? '';
    
    // Calculate time ago (simplified - you might want to use a date package)
    final timeAgo = 'منذ قليل';
    
    return _buildRequestCard(
      requestId: requestId,
      customerName: customerName,
      isOnline: false, // You can add online status if available in API
      timeAgo: timeAgo,
      status: 'جاهز للرد',
      partName: partText,
      carDetails: carDetails,
      remainingTime: '05:00', // You can calculate this from created_at
      isUrgent: true,
      icon: Icons.build,
    );
  }

  void _handleAccept(String requestId) {
    // Show accept modal with message input
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AcceptRequestModal(
        requestId: requestId,
        onAccept: (message) async {
          Navigator.pop(context);
          try {
            final response = await _searchRequestsRepo.acceptSearchRequest(
              requestId: int.parse(requestId),
              comment: message,
            );
            
            // Show success toast
            CustomToast.showSuccess(context, 'تم قبول الطلب بنجاح');
            
            // Refresh requests list
            context.read<VendorRequestsCubit>().getIncomingRequests();
            
            // Navigate to chat room if chat_id is in response
            final chatId = response['data']?['chat']?['id'];
            if (chatId != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.chatRoom,
                arguments: {
                  'chatId': chatId.toString(),
                },
              );
            }
          } catch (e) {
            CustomToast.showError(
              context,
              e.toString().replaceAll('Exception: ', ''),
            );
          }
        },
      ),
    );
  }

  void _handleReject(String requestId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text(
          'تجاهل الطلب',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'هل أنت متأكد من تجاهل هذا الطلب؟',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTextStyles.link,
            ),
          ),
          PrimaryButton(
            text: 'تجاهل',
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _searchRequestsRepo.rejectSearchRequest(int.parse(requestId));
                CustomToast.showSuccess(context, 'تم تجاهل الطلب');
                // Refresh requests list
                context.read<VendorRequestsCubit>().getIncomingRequests();
              } catch (e) {
                CustomToast.showError(
                  context,
                  e.toString().replaceAll('Exception: ', ''),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AcceptRequestModal extends StatefulWidget {
  final String requestId;
  final Function(String) onAccept;

  const _AcceptRequestModal({
    required this.requestId,
    required this.onAccept,
  });

  @override
  State<_AcceptRequestModal> createState() => _AcceptRequestModalState();
}

class _AcceptRequestModalState extends State<_AcceptRequestModal> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قبول الطلب',
                style: AppTextStyles.headingSmall,
              ),
              IconButton(
                icon: Icon(Icons.close, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Message Input
          Text(
            'اكتب رسالتك الأولى للعميل',
            style: AppTextStyles.inputLabel,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              hintText: 'اكتب رسالتك هنا...',
              hintStyle: AppTextStyles.inputHint,
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
          // Accept Button
          PrimaryButton(
            text: 'قبول وإرسال',
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                widget.onAccept(_messageController.text.trim());
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

