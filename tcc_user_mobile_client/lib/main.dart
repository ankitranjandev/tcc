import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

void main() {
  runApp(const TCCApp());
}

class TCCApp extends StatelessWidget {
  const TCCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProvider, _) {
          final router = GoRouter(
            initialLocation: auth.isAuthenticated ? '/dashboard' : '/login',
            redirect: (context, state) {
              final isAuthenticated = auth.isAuthenticated;
              final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                  state.matchedLocation.startsWith('/register') ||
                  state.matchedLocation.startsWith('/otp') ||
                  state.matchedLocation.startsWith('/forgot-password');

              if (!isAuthenticated && !isAuthRoute) {
                return '/login';
              }

              if (isAuthenticated && isAuthRoute) {
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
      ),
    );
  }
}
