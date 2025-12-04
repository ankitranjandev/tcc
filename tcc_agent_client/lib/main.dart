import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/kyc_verification_screen.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TCCAgentApp());
}

class TCCAgentApp extends StatelessWidget {
  const TCCAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
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
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isPendingVerification = authProvider.isPendingVerification;
        final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register') ||
            state.matchedLocation.startsWith('/otp') ||
            state.matchedLocation.startsWith('/kyc') ||
            state.matchedLocation.startsWith('/bank-details') ||
            state.matchedLocation.startsWith('/verification-waiting') ||
            state.matchedLocation.startsWith('/forgot-password') ||
            state.matchedLocation.startsWith('/splash');

        // If not authenticated and not on auth route, redirect to login
        if (!isAuthenticated && !isOnAuthRoute) {
          return '/login';
        }

        // If authenticated but pending verification, redirect to waiting screen
        if (isAuthenticated && isPendingVerification && !state.matchedLocation.startsWith('/verification-waiting')) {
          return '/verification-waiting';
        }

        // If authenticated, verified, and on auth route, redirect to dashboard
        if (isAuthenticated && !isPendingVerification && isOnAuthRoute && state.matchedLocation != '/splash') {
          return '/dashboard';
        }

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
