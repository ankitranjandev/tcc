import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/phone_number_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/kyc_verification_screen.dart';
import 'screens/auth/bank_details_screen.dart';
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    developer.log('🚀 TCCApp: Initializing app...', name: 'TCCApp');
    _authProvider = AuthProvider();
    _themeProvider = ThemeProvider();
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: _isInitialized
          ? Consumer2<AuthProvider, ThemeProvider>(
              builder: (context, auth, themeProvider, _) {
                final router = GoRouter(
                  initialLocation: auth.isAuthenticated ? '/dashboard' : '/login',
                  refreshListenable: auth,
                  redirect: (context, state) {
                    final isAuthenticated = auth.isAuthenticated;

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
                      return '/login';
                    }

                    // If authenticated and trying to access pre-auth routes (login/register), redirect to dashboard
                    // But allow onboarding routes even when authenticated
                    if (isAuthenticated && isPreAuthRoute) {
                      return '/dashboard';
                    }

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

                return MaterialApp.router(
                  title: 'TCC - The Community Coin',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  routerConfig: router,
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
