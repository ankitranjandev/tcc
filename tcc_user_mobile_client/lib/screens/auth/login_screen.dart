import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/responsive_builder.dart';
import '../../widgets/responsive_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    developer.log('🔐 LoginScreen: Login button pressed', name: 'LoginScreen');
    if (_formKey.currentState!.validate()) {
      developer.log('🔐 LoginScreen: Form validated, proceeding with login', name: 'LoginScreen');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      developer.log('🔐 LoginScreen: AuthProvider obtained, calling login()', name: 'LoginScreen');

      // Capture the current context's ScaffoldMessenger before async operation
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final success = await authProvider.login(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );

      developer.log('🔐 LoginScreen: Login result: $success', name: 'LoginScreen');
      developer.log('🔐 LoginScreen: mounted: $mounted', name: 'LoginScreen');

      if (success) {
        developer.log('🔐 LoginScreen: Login successful', name: 'LoginScreen');
        // Navigation will be handled by router redirect
      } else {
        // Show error even if widget is unmounted
        final errorMsg = authProvider.errorMessage ?? 'Invalid credentials. Please try again.';
        developer.log('🔐 LoginScreen: Login failed with error: $errorMsg', name: 'LoginScreen');
        developer.log('🔐 LoginScreen: Showing SnackBar with error message', name: 'LoginScreen');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: AppColors.white,
              onPressed: () {
                developer.log('🔐 LoginScreen: Dismiss button pressed', name: 'LoginScreen');
                authProvider.clearError();
              },
            ),
          ),
        );
        developer.log('🔐 LoginScreen: SnackBar displayed', name: 'LoginScreen');
      }
    } else {
      developer.log('🔐 LoginScreen: Form validation failed', name: 'LoginScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final isTabletOrDesktop = screenWidth > ResponsiveHelper.mobileBreakpoint;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: isTabletOrDesktop ? 500 : double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 5)),
                    ResponsiveText.headline(
                      'Welcome Back!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),
                    ResponsiveText.body(
                      'Sign in to continue',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 5)),
                TextFormField(
                  controller: _emailOrPhoneController,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Email or Phone Number',
                    hintText: 'Enter your email or phone number',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or phone number';
                    }
                    // Check if it's an email or phone number
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    final phoneRegex = RegExp(r'^\d{10,15}$');

                    if (!emailRegex.hasMatch(value) && !phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                      return 'Please enter a valid email or phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2)),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 1.5)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : ResponsiveText.body(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobileFactor: 3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/register');
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
    );
  }
}
