import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseService.instance.initialize();
    debugPrint('Firebase initialized successfully');

    // Initialize Notification Service
    await NotificationService().initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase/Notifications: $e');
    // Continue running the app even if Firebase fails to initialize
    // This allows the app to work in development mode without Firebase
  }

  runApp(const TccAdminApp());
}

class TccAdminApp extends StatelessWidget {
  const TccAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final appRouter = AppRouter(authProvider);

          return MaterialApp.router(
            title: 'TCC Admin Panel',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
