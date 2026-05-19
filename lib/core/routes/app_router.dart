import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/widgets/auth/auth_guard_page.dart';
import '../routes/app_routes.dart';
import '../../features/auth/presentation/views/splash_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/home/presentation/views/home_screen.dart';
import '../../features/home/presentation/views/search_results_screen.dart';
import '../../features/home/presentation/cubit/search_cubit.dart';
import '../../features/home/presentation/cubit/category_cubit.dart';
import '../../features/vendor/presentation/views/vendor_profile_screen.dart';
import '../../features/vendor/presentation/views/vendor_dashboard_screen.dart';
import '../../features/vendor/presentation/views/vendor_supported_brands_screen.dart';
import '../../features/vendor/presentation/cubit/vendor_profile_cubit.dart';
import '../../features/chat/presentation/views/chat_list_screen.dart';
import '../../features/chat/presentation/views/chat_room_screen.dart';
import '../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../features/subscription/presentation/views/subscription_plans_screen.dart';
import '../../features/subscription/presentation/views/plan_details_screen.dart';
import '../../features/profile/presentation/views/user_profile_screen.dart';
import '../../features/profile/presentation/cubit/user_profile_cubit.dart';
import '../../features/notifications/presentation/views/notifications_screen.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/vendor/presentation/views/vendor_incoming_requests_screen.dart';
import '../../features/vendor/presentation/views/vendor_location_edit_screen.dart';
import '../../features/vendor/presentation/cubit/vendor_requests_cubit.dart';
import '../../features/my_ads/presentation/views/create_ad_screen.dart';
import '../../features/ads/presentation/cubit/my_ads_cubit.dart';
import '../../features/ads/presentation/cubit/ads_list_cubit.dart';
import '../../features/ads/presentation/cubit/create_ad_cubit.dart';
import '../../features/my_ads/presentation/views/create_ad_photos_screen.dart';
import '../../features/my_ads/presentation/views/edit_ad_screen.dart';
import '../../features/ads/presentation/cubit/ad_details_cubit.dart';
import '../../features/ad_details/presentation/views/ad_details_screen.dart';
import '../../features/ads/data/models/ad_model.dart';
import '../../features/orders/presentation/views/orders_screen.dart';
import '../../features/permissions/presentation/views/permissions_screen.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';
import '../../features/home/presentation/views/my_search_requests_screen.dart';
import '../../features/home/presentation/cubit/search_requests_cubit.dart';

/// Application Router
class AppRouter {
  static Route<dynamic> _protectedRoute(
    RouteSettings settings, {
    required String guardTitle,
    required String guardDescription,
    required Widget child,
    IconData guardIcon = Icons.lock_outline,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthGuardPage(
        title: guardTitle,
        description: guardDescription,
        icon: guardIcon,
        child: child,
      ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => SearchCubit()),
              BlocProvider(create: (_) => CategoryCubit()),
              BlocProvider(create: (_) => MyAdsCubit()),
              BlocProvider(create: (_) => AdsListCubit()),
              BlocProvider(create: (_) => ChatCubit()),
            ],
            child: const HomeScreen(),
          ),
        );

      case AppRoutes.searchResults:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => SearchCubit(),
            child: SearchResultsScreen(
              searchRequest: args?['searchRequest'],
              searchResponse: args?['searchResponse'],
            ),
          ),
        );

      case AppRoutes.vendorProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        final vendorIdStr = args?['vendorId']?.toString() ?? '';
        final bySellerUserId = args?['vendorProfileByUserId'] == true;
        final parsedVendorOrUserId = int.tryParse(vendorIdStr) ?? 0;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => VendorProfileCubit()
              ..fetchVendorProfile(
                parsedVendorOrUserId,
                bySellerUserId: bySellerUserId,
              ),
            child: VendorProfileScreen(
              vendorId: vendorIdStr,
              vendorName: args?['vendorName'] as String?,
              bySellerUserId: bySellerUserId,
            ),
          ),
        );

      case AppRoutes.chatList:
        return _protectedRoute(
          settings,
          guardTitle: 'المحادثات',
          guardDescription:
              'سجّل الدخول لعرض محادثاتك والتواصل مع التجار.',
          guardIcon: Icons.chat_bubble_outline,
          child: BlocProvider(
            create: (_) => ChatCubit(),
            child: const ChatListScreen(),
          ),
        );

      case AppRoutes.chatRoom:
        final args = settings.arguments as Map<String, dynamic>?;
        int? peerVendorId;
        final rawVid = args?['peerVendorId'];
        if (rawVid is int) peerVendorId = rawVid;
        if (rawVid is num) peerVendorId = rawVid.toInt();
        if (rawVid is String) peerVendorId = int.tryParse(rawVid);
        return _protectedRoute(
          settings,
          guardTitle: 'المحادثة',
          guardDescription: 'سجّل الدخول لإرسال واستقبال الرسائل.',
          guardIcon: Icons.chat_bubble_outline,
          child: BlocProvider(
            create: (_) => ChatCubit(),
            child: ChatRoomScreen(
              chatId: args?['chatId'] ?? '1',
              chatName:
                  args?['chatName'] ??
                  args?['vendorName'] ??
                  'مركز النصر لقطع الغيار',
              peerPhone: args?['peerPhone'] as String?,
              peerIsVerified: args?['peerIsVerified'] == true,
              peerAvatarUrl: args?['peerAvatarUrl'] as String?,
              peerVendorId: peerVendorId,
            ),
          ),
        );

      case AppRoutes.subscriptionPlans:
        return _protectedRoute(
          settings,
          guardTitle: 'خطط الاشتراك',
          guardDescription: 'سجّل الدخول كتاجر لإدارة اشتراكك.',
          child: const SubscriptionPlansScreen(),
        );

      case AppRoutes.planDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return _protectedRoute(
          settings,
          guardTitle: 'تفاصيل الخطة',
          guardDescription: 'سجّل الدخول لعرض تفاصيل الاشتراك.',
          child: PlanDetailsScreen(planId: args?['planId'] ?? 0),
        );

      case AppRoutes.vendorDashboard:
        return _protectedRoute(
          settings,
          guardTitle: 'لوحة التاجر',
          guardDescription: 'سجّل الدخول بحساب تاجر للوصول إلى لوحة التحكم.',
          guardIcon: Icons.storefront_outlined,
          child: const VendorDashboardScreen(),
        );

      case AppRoutes.vendorSupportedBrands:
        final args = settings.arguments as Map<String, dynamic>?;
        final raw = args?['initialBrandIds'];
        final initial = <int>[];
        if (raw is List) {
          for (final e in raw) {
            if (e is int) {
              initial.add(e);
            } else if (e is num) {
              initial.add(e.toInt());
            } else {
              final p = int.tryParse(e?.toString() ?? '');
              if (p != null) initial.add(p);
            }
          }
        }
        return _protectedRoute(
          settings,
          guardTitle: 'الماركات المدعومة',
          guardDescription: 'سجّل الدخول كتاجر لتعديل الماركات المدعومة.',
          child: BlocProvider(
            create: (_) => CategoryCubit()..loadInitialData(),
            child: VendorSupportedBrandsScreen(initialBrandIds: initial),
          ),
        );

      case AppRoutes.vendorLocationEdit:
        final profile = settings.arguments as dynamic;
        if (profile == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Profile not found')),
            ),
          );
        }
        return _protectedRoute(
          settings,
          guardTitle: 'موقع المتجر',
          guardDescription: 'سجّل الدخول كتاجر لتعديل موقع متجرك.',
          child: VendorLocationEditScreen(profile: profile),
        );

      case AppRoutes.profile:
        return _protectedRoute(
          settings,
          guardTitle: 'الملف الشخصي',
          guardDescription:
              'سجّل الدخول لعرض ملفك الشخصي وإعدادات حسابك.',
          guardIcon: Icons.person_outline,
          child: BlocProvider(
            create: (_) => UserProfileCubit()..fetchCurrentUserProfile(),
            child: const UserProfileScreen(),
          ),
        );

      case AppRoutes.notifications:
        return _protectedRoute(
          settings,
          guardTitle: 'الإشعارات',
          guardDescription: 'سجّل الدخول لعرض إشعاراتك.',
          guardIcon: Icons.notifications_outlined,
          child: BlocProvider(
            create: (_) => NotificationsCubit(),
            child: const NotificationsScreen(),
          ),
        );

      case AppRoutes.vendorIncomingRequests:
        final incomingArgs = settings.arguments as Map<String, dynamic>?;
        final rawSr = incomingArgs?['searchRequestId'];
        final highlightId = rawSr is int
            ? rawSr
            : int.tryParse(rawSr?.toString() ?? '');
        return _protectedRoute(
          settings,
          guardTitle: 'طلبات العملاء',
          guardDescription: 'سجّل الدخول كتاجر لعرض الطلبات الواردة.',
          child: BlocProvider(
            create: (_) => VendorRequestsCubit(),
            child: VendorIncomingRequestsScreen(
              initialHighlightSearchRequestId: highlightId,
            ),
          ),
        );

      case AppRoutes.createAd:
        return _protectedRoute(
          settings,
          guardTitle: 'إضافة إعلان',
          guardDescription: 'سجّل الدخول لنشر إعلاناتك.',
          guardIcon: Icons.add_circle_outline,
          child: BlocProvider(
            create: (_) => CategoryCubit(),
            child: const CreateAdScreen(),
          ),
        );

      case AppRoutes.createAdPhotos:
        final formArgs = settings.arguments as Map<String, dynamic>?;
        return _protectedRoute(
          settings,
          guardTitle: 'إضافة إعلان',
          guardDescription: 'سجّل الدخول لنشر إعلاناتك.',
          child: BlocProvider(
            create: (_) => CreateAdCubit(),
            child: CreateAdPhotosScreen(formData: formArgs),
          ),
        );

      case AppRoutes.editAd:
        final ad = settings.arguments as AdModel?;
        if (ad == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('لا يوجد إعلان للتعديل')),
            ),
          );
        }
        return _protectedRoute(
          settings,
          guardTitle: 'تعديل الإعلان',
          guardDescription: 'سجّل الدخول لتعديل إعلاناتك.',
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CategoryCubit()),
              BlocProvider(create: (_) => CreateAdCubit()),
            ],
            child: EditAdScreen(ad: ad),
          ),
        );

      case AppRoutes.adDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final adId = args?['adId']?.toString();
        final id = adId != null && adId.isNotEmpty ? int.tryParse(adId) : null;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) {
              final cubit = AdDetailsCubit();
              if (id != null && id > 0) cubit.loadAd(id);
              return cubit;
            },
            child: AdDetailsScreen(adId: adId, ad: args?['ad']),
          ),
        );

      case AppRoutes.orders:
        final args = settings.arguments as Map<String, dynamic>?;
        int? orderId;
        if (args != null) {
          final id = args['orderId'] ?? args['order_id'];
          if (id is int) orderId = id;
          if (id is num) orderId = id.toInt();
        }
        final orderTitle =
            args?['orderTitle'] as String? ?? args?['order_title'] as String?;
        DateTime? createdAt;
        final rawCreatedAt = args?['createdAt'] ?? args?['created_at'];
        if (rawCreatedAt is DateTime) {
          createdAt = rawCreatedAt;
        } else if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
          createdAt = DateTime.tryParse(rawCreatedAt);
        }
        return _protectedRoute(
          settings,
          guardTitle: 'طلباتي',
          guardDescription: 'سجّل الدخول لعرض سجل طلباتك الشخصية.',
          guardIcon: Icons.shopping_bag_outlined,
          child: OrdersScreen(
            orderId: orderId,
            orderTitle: orderTitle,
            createdAt: createdAt,
          ),
        );

      case AppRoutes.permissions:
        return _protectedRoute(
          settings,
          guardTitle: 'الصلاحيات',
          guardDescription: 'سجّل الدخول للوصول إلى إدارة الصلاحيات.',
          child: BlocProvider(
            create: (_) => PermissionsCubit(),
            child: const PermissionsScreen(),
          ),
        );

      case AppRoutes.mySearchRequests:
        return _protectedRoute(
          settings,
          guardTitle: 'طلبات البحث',
          guardDescription: 'سجّل الدخول لعرض طلبات البحث الخاصة بك.',
          child: BlocProvider(
            create: (_) => SearchRequestsCubit()..getMySearchRequests(),
            child: const MySearchRequestsScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
