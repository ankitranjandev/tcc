import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/kyc_verification_screen.dart';
import 'screens/auth/kyc_status_screen.dart';
import 'screens/auth/bank_details_screen.dart';
import 'screens/auth/verification_waiting_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/main_navigation.dart';
import 'screens/transactions/transaction_history_screen.dart';
import 'screens/transactions/add_money_screen.dart';
import 'screens/transactions/user_verification_screen.dart';
import 'screens/transactions/currency_counter_screen.dart';
import 'screens/transactions/transaction_confirmation_screen.dart';
import 'screens/transactions/transaction_success_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/wallet/credit_request_screen.dart';
import 'screens/orders/payment_orders_screen.dart';
import 'screens/commission/commission_dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  developer.log('🚀 [MAIN] App starting...', name: 'TCC.Main');
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('✅ [MAIN] Flutter binding initialized', name: 'TCC.Main');

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    developer.log('✅ [MAIN] Firebase initialized', name: 'TCC.Main');

    // Initialize Notification Service
    await NotificationService().initialize();
    developer.log('✅ [MAIN] Notification service initialized', name: 'TCC.Main');
  } catch (e) {
    developer.log('❌ [MAIN] Error initializing Firebase/Notifications: $e', name: 'TCC.Main');
  }

  runApp(const TCCAgentApp());
  developer.log('✅ [MAIN] App widget created', name: 'TCC.Main');
}

class TCCAgentApp extends StatelessWidget {
  const TCCAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('🏗️ [MAIN] Building TCCAgentApp widget', name: 'TCC.Main');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            developer.log('📦 [MAIN] Creating AuthProvider', name: 'TCC.Main');
            final provider = AuthProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            developer.log('📦 [MAIN] Creating ThemeProvider', name: 'TCC.Main');
            return ThemeProvider();
          },
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          developer.log(
            '🔄 [MAIN] Consumer rebuilding - isAuth: ${authProvider.isAuthenticated}, isPending: ${authProvider.isPendingVerification}',
            name: 'TCC.Main',
          );
          return MaterialApp.router(
            title: 'TCC Agent',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _buildRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    developer.log('🛣️ [ROUTER] Building router', name: 'TCC.Router');
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isPendingVerification = authProvider.isPendingVerification;
        final isKycApproved = authProvider.isKycApproved;
        final currentLocation = state.matchedLocation;
        final isOnAuthRoute = currentLocation.startsWith('/login') ||
            currentLocation.startsWith('/register') ||
            currentLocation.startsWith('/otp') ||
            currentLocation.startsWith('/kyc') ||
            currentLocation.startsWith('/bank-details') ||
            currentLocation.startsWith('/verification-waiting') ||
            currentLocation.startsWith('/forgot-password') ||
            currentLocation.startsWith('/splash');

        // Protected routes that require KYC approval
        final kycProtectedRoutes = [
          '/add-money',
          '/transaction-history',
          '/payment-orders',
          '/commission-dashboard',
          '/credit-request',
          '/user-verification',
          '/currency-counter',
          '/transaction-confirmation',
          '/transaction-success',
        ];

        final isOnKycProtectedRoute = kycProtectedRoutes.any(
          (route) => currentLocation.startsWith(route),
        );

        // Routes that are always accessible (even without KYC)
        final alwaysAccessibleRoutes = [
          '/dashboard',
          '/profile',
          '/settings',
          '/support',
          '/notifications',
          '/kyc-status',
        ];

        final isOnAlwaysAccessibleRoute = alwaysAccessibleRoutes.any(
          (route) => currentLocation.startsWith(route),
        );

        developer.log(
          '🔀 [ROUTER] Redirect check:\n'
          '  Current: $currentLocation\n'
          '  isAuthenticated: $isAuthenticated\n'
          '  isPendingVerification: $isPendingVerification\n'
          '  isKycApproved: $isKycApproved\n'
          '  isOnAuthRoute: $isOnAuthRoute\n'
          '  isOnKycProtectedRoute: $isOnKycProtectedRoute\n'
          '  Agent: ${authProvider.agent?.firstName ?? 'null'}',
          name: 'TCC.Router',
        );

        // If not authenticated and not on auth route, redirect to login
        if (!isAuthenticated && !isOnAuthRoute) {
          developer.log('➡️ [ROUTER] Redirecting to /login (not authenticated)', name: 'TCC.Router');
          return '/login';
        }

        // If authenticated but pending verification, redirect to waiting screen
        if (isAuthenticated && isPendingVerification && !currentLocation.startsWith('/verification-waiting')) {
          developer.log('➡️ [ROUTER] Redirecting to /verification-waiting (pending verification)', name: 'TCC.Router');
          return '/verification-waiting';
        }

        // If authenticated, not pending, but KYC not approved and trying to access protected route
        if (isAuthenticated && !isPendingVerification && !isKycApproved && isOnKycProtectedRoute) {
          developer.log('➡️ [ROUTER] Redirecting to /kyc-status (KYC not approved)', name: 'TCC.Router');
          return '/kyc-status';
        }

        // If authenticated, verified, and on auth route, redirect to dashboard
        if (isAuthenticated && !isPendingVerification && isOnAuthRoute && currentLocation != '/splash') {
          developer.log('➡️ [ROUTER] Redirecting to /dashboard (authenticated and verified)', name: 'TCC.Router');
          return '/dashboard';
        }

        developer.log('✅ [ROUTER] No redirect needed, staying at $currentLocation', name: 'TCC.Router');
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return OTPVerificationScreen(
              mobileNumber: extra?['mobile_number'] ?? '',
              isFromRegistration: extra?['is_from_registration'] ?? true,
            );
          },
        ),
        GoRoute(
          path: '/kyc-verification',
          builder: (context, state) => const KYCVerificationScreen(),
        ),
        GoRoute(
          path: '/kyc-status',
          builder: (context, state) => const KYCStatusScreen(),
        ),
        GoRoute(
          path: '/bank-details',
          builder: (context, state) => const BankDetailsScreen(),
        ),
        GoRoute(
          path: '/verification-waiting',
          builder: (context, state) => const VerificationWaitingScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ResetPasswordScreen(
              emailOrPhone: extra?['email_or_phone'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const MainNavigation(),
        ),
        // Transaction routes
        GoRoute(
          path: '/transaction-history',
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
        GoRoute(
          path: '/add-money',
          builder: (context, state) => const AddMoneyScreen(),
        ),
        GoRoute(
          path: '/user-verification',
          builder: (context, state) => const UserVerificationScreen(),
        ),
        GoRoute(
          path: '/currency-counter',
          builder: (context, state) => const CurrencyCounterScreen(),
        ),
        GoRoute(
          path: '/transaction-confirmation',
          builder: (context, state) => const TransactionConfirmationScreen(),
        ),
        GoRoute(
          path: '/transaction-success',
          builder: (context, state) => const TransactionSuccessScreen(),
        ),
        // Profile, settings, and support routes
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportScreen(),
        ),
        // Wallet, orders, and commission routes
        GoRoute(
          path: '/credit-request',
          builder: (context, state) => const CreditRequestScreen(),
        ),
        GoRoute(
          path: '/payment-orders',
          builder: (context, state) => const PaymentOrdersScreen(),
        ),
        GoRoute(
          path: '/commission-dashboard',
          builder: (context, state) => const CommissionDashboardScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }
}
