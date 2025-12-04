import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      if (authProvider.isPendingVerification) {
        context.go('/verification-waiting');
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryOrange,
              AppColors.primaryOrangeDark,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 48,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TCC',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'TCC Agent',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Money Transfer Partner',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Version Info
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
