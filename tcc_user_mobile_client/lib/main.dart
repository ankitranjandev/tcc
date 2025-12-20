import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'config/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/phone_number_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/kyc_verification_screen.dart';
import 'screens/auth/bank_details_screen.dart';
import 'screens/auth/kyc_status_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_otp_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/main_navigation.dart';
import 'screens/investments/investment_category_screen.dart';
import 'screens/investments/investment_product_detail_screen.dart';
import 'screens/investments/change_deposit_period_screen.dart';
import 'screens/investments/withdraw_investment_screen.dart';
import 'screens/investments/withdraw_agreement_screen.dart';
import 'screens/investments/withdraw_success_screen.dart';
import 'screens/portfolio/portfolio_investment_detail_screen.dart';
import 'screens/transactions/transaction_detail_screen.dart';
import 'screens/gift/send_gift_screen.dart';
import 'screens/agent/agent_search_screen.dart';
import 'models/investment_model.dart';
import 'models/transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip on web for now until firebase_options.dart is configured)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('✅ Firebase initialized', name: 'TCCApp');

      // Initialize Notification Service
      await NotificationService().initialize();
      developer.log('✅ Notification service initialized', name: 'TCCApp');
    } catch (e) {
      developer.log('❌ Error initializing Firebase/Notifications: $e', name: 'TCCApp');
    }

    // Initialize Stripe (not supported on web)
    try {
      Stripe.publishableKey = AppConstants.stripePublishableKey;
      Stripe.merchantIdentifier = 'merchant.com.tcc.app';
      Stripe.urlScheme = 'tccapp';
      await Stripe.instance.applySettings();
      developer.log('✅ Stripe initialized', name: 'TCCApp');
    } catch (e) {
      developer.log('❌ Error initializing Stripe: $e', name: 'TCCApp');
    }
  } else {
    developer.log('⚠️ Running on web - Firebase and Stripe initialization skipped', name: 'TCCApp');
  }

  runApp(const TCCApp());
}

class TCCApp extends StatefulWidget {
  const TCCApp({super.key});

  @override
  State<TCCApp> createState() => _TCCAppState();
}

class _TCCAppState extends State<TCCApp> {
  late final AuthProvider _authProvider;
  late final ThemeProvider _themeProvider;
  late final GoRouter _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    developer.log('🚀 TCCApp: Initializing app...', name: 'TCCApp');
    _authProvider = AuthProvider();
    _themeProvider = ThemeProvider();
    _router = _createRouter();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    developer.log('🚀 TCCApp: Starting app initialization', name: 'TCCApp');
    await _authProvider.initialize();
    developer.log('🚀 TCCApp: AuthProvider initialized. isAuthenticated: ${_authProvider.isAuthenticated}', name: 'TCCApp');
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      developer.log('🚀 TCCApp: App initialization complete', name: 'TCCApp');
    }
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/login', // Will be redirected based on auth state
      refreshListenable: _authProvider,
      observers: [NavigationLogger()],
      redirect: (context, state) {
        final isAuthenticated = _authProvider.isAuthenticated;

        developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Router');
        developer.log('🔀 ROUTE REDIRECT', name: 'Router');
        developer.log('From: ${state.matchedLocation}', name: 'Router');
        developer.log('Authenticated: $isAuthenticated', name: 'Router');
        developer.log('Initialized: $_isInitialized', name: 'Router');
        developer.log('User: ${_authProvider.user?.email ?? 'null'}', name: 'Router');

        // Don't redirect until initialization is complete
        if (!_isInitialized) {
          developer.log('🔀 Router: Not initialized yet, staying on current route', name: 'Router');
          return null;
        }

        // Auth routes that require being NOT authenticated
        final isPreAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register') ||
            state.matchedLocation.startsWith('/forgot-password');

        // Onboarding routes that are part of registration flow (user is authenticated but needs to complete setup)
        final isOnboardingRoute = state.matchedLocation.startsWith('/phone-number') ||
            state.matchedLocation.startsWith('/otp') ||
            state.matchedLocation.startsWith('/kyc-verification') ||
            state.matchedLocation.startsWith('/bank-details');

        // If not authenticated and trying to access protected routes, redirect to login
        if (!isAuthenticated && !isPreAuthRoute && !isOnboardingRoute) {
          developer.log('🔀 Not authenticated, redirecting to /login', name: 'Router');
          developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Router');
          return '/login';
        }

        // If authenticated and trying to access pre-auth routes (login/register), redirect to dashboard
        // But allow onboarding routes even when authenticated
        if (isAuthenticated && isPreAuthRoute) {
          developer.log('🔀 Authenticated, redirecting to /dashboard', name: 'Router');
          developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Router');
          return '/dashboard';
        }

        developer.log('🔀 No redirect needed', name: 'Router');
        developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Router');
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/forgot-password/verify-otp',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ResetPasswordOtpScreen(
              email: extra?['email'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/forgot-password/reset',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ResetPasswordScreen(
              email: extra?['email'] ?? '',
              phone: extra?['phone'] ?? '',
              countryCode: extra?['countryCode'] ?? '+232',
              otp: extra?['otp'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(),
        ),
        GoRoute(
          path: '/phone-number',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PhoneNumberScreen(registrationData: extra);
          },
        ),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return OTPVerificationScreen(extraData: extra);
          },
        ),
        GoRoute(
          path: '/kyc-verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return KYCVerificationScreen(extraData: extra);
          },
        ),
        GoRoute(
          path: '/bank-details',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return BankDetailsScreen(extraData: extra);
          },
        ),
        GoRoute(
          path: '/kyc-status',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return KYCStatusScreen(extraData: extra);
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => MainNavigation(),
        ),
        GoRoute(
          path: '/investments/:category',
          builder: (context, state) {
            final category = state.pathParameters['category']!;
            return InvestmentCategoryScreen(category: category);
          },
        ),
        GoRoute(
          path: '/investments/:category/:productId',
          builder: (context, state) {
            final product = state.extra as InvestmentProduct;
            return InvestmentProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: '/portfolio/:investmentId',
          builder: (context, state) {
            final investment = state.extra as InvestmentModel;
            return PortfolioInvestmentDetailScreen(investment: investment);
          },
        ),
        GoRoute(
          path: '/transactions/:transactionId',
          builder: (context, state) {
            final transaction = state.extra as TransactionModel;
            return TransactionDetailScreen(transaction: transaction);
          },
        ),
        GoRoute(
          path: '/send-gift',
          builder: (context, state) => SendGiftScreen(),
        ),
        GoRoute(
          path: '/change-deposit-period',
          builder: (context, state) => ChangeDepositPeriodScreen(),
        ),
        GoRoute(
          path: '/withdraw-investment',
          builder: (context, state) => WithdrawInvestmentScreen(),
        ),
        GoRoute(
          path: '/withdraw-agreement',
          builder: (context, state) => WithdrawAgreementScreen(),
        ),
        GoRoute(
          path: '/withdraw-success',
          builder: (context, state) => WithdrawSuccessScreen(),
        ),
        GoRoute(
          path: '/agent-search',
          builder: (context, state) => AgentSearchScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: _isInitialized
          ? Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return MaterialApp.router(
                  title: 'TCC - The Community Coin',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  routerConfig: _router,
                  debugShowCheckedModeBanner: false,
                );
              },
            )
          : MaterialApp(
              title: 'TCC - The Community Coin',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
    );
  }
}

// Navigation observer for logging route changes
class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
    developer.log('➡️ PUSH', name: 'Navigation');
    developer.log('To: ${route.settings.name}', name: 'Navigation');
    developer.log('From: ${previousRoute?.settings.name ?? 'null'}', name: 'Navigation');
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
    developer.log('⬅️ POP', name: 'Navigation');
    developer.log('From: ${route.settings.name}', name: 'Navigation');
    developer.log('To: ${previousRoute?.settings.name ?? 'null'}', name: 'Navigation');
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
    developer.log('🔄 REPLACE', name: 'Navigation');
    developer.log('New: ${newRoute?.settings.name}', name: 'Navigation');
    developer.log('Old: ${oldRoute?.settings.name}', name: 'Navigation');
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
    developer.log('🗑️ REMOVE', name: 'Navigation');
    developer.log('Route: ${route.settings.name}', name: 'Navigation');
    developer.log('Previous: ${previousRoute?.settings.name ?? 'null'}', name: 'Navigation');
    developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'Navigation');
  }
}
