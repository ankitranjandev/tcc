import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_helper.dart';

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
  bool _isLoading = false;
  bool _isAdminLogin = false;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      emailOrPhone: _emailOrPhoneController.text.trim(),
      password: _passwordController.text,
      isAdminLogin: _isAdminLogin,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Check if user needs to complete verification
      if (authProvider.isPendingVerification) {
        context.go('/verification-waiting');
      } else {
        context.go('/dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 40,
                        color: AppColors.primaryOrange,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Welcome Text
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _isAdminLogin
                          ? 'Sign in as Admin'
                          : 'Sign in to continue as TCC Agent',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Admin Login Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isAdminLogin
                            ? AppColors.primaryOrange.withValues(alpha: 0.1)
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAdminLogin
                              ? AppColors.primaryOrange
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAdminLogin ? Icons.admin_panel_settings : Icons.people,
                            color: _isAdminLogin
                                ? AppColors.primaryOrange
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Login as Admin',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: _isAdminLogin ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isAdminLogin,
                            onChanged: (value) {
                              setState(() => _isAdminLogin = value);
                            },
                            activeTrackColor: AppColors.primaryOrange.withValues(alpha: 0.5),
                            thumbColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primaryOrange;
                                }
                                return AppColors.gray400;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email/Phone Field
                    TextFormField(
                      controller: _emailOrPhoneController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _isAdminLogin ? 'Email' : 'Email or Mobile Number',
                        hintText: _isAdminLogin ? 'Enter your admin email' : 'Enter your email or mobile',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryOrange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or mobile number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryOrange),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.borderLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.borderLight)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Register Now',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Agent Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryOrange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This app is exclusively for verified TCC Agents',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
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
    );
  }
}
