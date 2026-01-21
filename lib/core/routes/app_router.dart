import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../../features/auth/presentation/views/splash_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/home/presentation/views/home_screen.dart';
import '../../features/home/presentation/views/search_results_screen.dart';
import '../../features/vendor/presentation/views/vendor_profile_screen.dart';
import '../../features/vendor/presentation/views/vendor_dashboard_screen.dart';
import '../../features/chat/presentation/views/chat_list_screen.dart';
import '../../features/chat/presentation/views/chat_room_screen.dart';
import '../../features/subscription/presentation/views/subscription_plans_screen.dart';
import '../../features/profile/presentation/views/user_profile_screen.dart';

/// Application Router
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case AppRoutes.searchResults:
        return MaterialPageRoute(
          builder: (_) => const SearchResultsScreen(),
        );

      case AppRoutes.vendorProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => VendorProfileScreen(
            vendorId: args?['vendorId'] ?? '',
            vendorName: args?['vendorName'] ?? 'المهندس لقطع الغيار',
          ),
        );

      case AppRoutes.chatList:
        return MaterialPageRoute(
          builder: (_) => const ChatListScreen(),
        );

      case AppRoutes.chatRoom:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatId: args?['chatId'] ?? '',
            vendorName: args?['vendorName'] ?? 'مركز النصر لقطع الغيار',
          ),
        );

      case AppRoutes.subscriptionPlans:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionPlansScreen(),
        );

      case AppRoutes.vendorDashboard:
        return MaterialPageRoute(
          builder: (_) => const VendorDashboardScreen(),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const UserProfileScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

