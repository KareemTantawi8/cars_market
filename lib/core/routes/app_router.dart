import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
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
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
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
        return MaterialPageRoute(
          builder: (_) => const SubscriptionPlansScreen(),
        );

      case AppRoutes.planDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PlanDetailsScreen(planId: args?['planId'] ?? 0),
        );

      case AppRoutes.vendorDashboard:
        return MaterialPageRoute(builder: (_) => const VendorDashboardScreen());

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
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => CategoryCubit()..loadInitialData(),
            child: VendorSupportedBrandsScreen(initialBrandIds: initial),
          ),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => UserProfileCubit()..fetchCurrentUserProfile(),
            child: const UserProfileScreen(),
          ),
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
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
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => VendorRequestsCubit(),
            child: VendorIncomingRequestsScreen(
              initialHighlightSearchRequestId: highlightId,
            ),
          ),
        );

      case AppRoutes.createAd:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => CategoryCubit(),
            child: const CreateAdScreen(),
          ),
        );

      case AppRoutes.createAdPhotos:
        final formArgs = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
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
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
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
        return MaterialPageRoute(
          builder: (_) => OrdersScreen(
            orderId: orderId,
            orderTitle: orderTitle,
            createdAt: createdAt,
          ),
        );

      case AppRoutes.permissions:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => PermissionsCubit(),
            child: const PermissionsScreen(),
          ),
        );

      case AppRoutes.mySearchRequests:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
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
