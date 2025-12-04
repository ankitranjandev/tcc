import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Login Screen for Admin
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@tcc.sl');
  final _passwordController = TextEditingController(text: 'Admin@123');
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Call the login method which will handle mock/real API
    authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Title
                      Icon(
                        Icons.admin_panel_settings,
                        size: 64,
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(height: AppTheme.space24),
                      Text(
                        'TCC Admin',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        'Sign in to your admin account',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
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
                      const SizedBox(height: AppTheme.space16),

                      // Remember Me & Forgot Password
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to forgot password
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space32),

                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _handleLogin,
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          );
                        },
                      ),

                      // Error Message
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.errorMessage != null) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: AppTheme.space16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.space12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  border: Border.all(
                                    color: AppColors.error,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.space8),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Demo Credentials Info
                      const SizedBox(height: AppTheme.space32),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.space8),
                                Text(
                                  'Demo Credentials',
                                  style: TextStyle(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              'Email: admin@tcc.sl\nPassword: Admin@123',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
