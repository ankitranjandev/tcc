import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        context.go('/dashboard');
      } else if (mounted) {
        final errorMsg = authProvider.errorMessage ?? 'Invalid credentials. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: AppColors.white,
              onPressed: () {
                authProvider.clearError();
              },
            ),
          ),
        );
      }
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
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
