import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/constants.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/controllers/user_type_controller.dart';
import 'core/network/api_client.dart';
import 'core/navigation/root_navigator.dart';
import 'core/services/push_notification_service.dart'
    show firebaseMessagingBackgroundHandler, PushNotificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await UserTypeController().initialize();

  ApiClient().updateBaseUrl();

  await PushNotificationService.instance.initialize();

  runApp(
    BlocProvider(
      create: (_) => ThemeCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          locale: const Locale(AppConstants.defaultLanguage, 'EG'),
          supportedLocales: const [
            Locale(AppConstants.defaultLanguage, 'EG'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          builder: (context, child) {
            final placeholderBg = AppTheme.lightTheme.scaffoldBackgroundColor;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ??
                  ColoredBox(
                    color: placeholderBg,
                    child: const SizedBox.expand(),
                  ),
            );
          },

          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
