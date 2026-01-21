import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/controllers/user_type_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage and user type controller
  await UserTypeController().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: AppTheme.darkTheme,
      
      // Localization
      locale: const Locale(AppConstants.defaultLanguage, 'EG'),
      supportedLocales: const [
        Locale(AppConstants.defaultLanguage, 'EG'), // Arabic (Egypt)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // RTL Support
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      // Routing
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
