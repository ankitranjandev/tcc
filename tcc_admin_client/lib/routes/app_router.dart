import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/users/users_screen.dart';
import '../screens/agents/agents_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/investments/investments_screen.dart';
import '../screens/bill_payments/bill_payments_screen.dart';
import '../screens/voting/voting_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/layout/main_layout.dart';
import '../services/navigation_service.dart';

/// App Router Configuration
class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    navigatorKey: NavigationService().navigatorKey,
    refreshListenable: authProvider,
    debugLogDiagnostics: true,
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      // If not authenticated and trying to access protected routes, redirect to login
      if (!isAuthenticated && !isGoingToLogin) {
        return '/login';
      }

      // If authenticated and trying to access login, redirect to dashboard
      if (isAuthenticated && isGoingToLogin) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Login Route (No Layout)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboard Route (With Layout)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const DashboardScreen(),
        ),
      ),

      // Users Route (With Layout)
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const UsersScreen(),
        ),
      ),

      // Agents Route (With Layout)
      GoRoute(
        path: '/agents',
        name: 'agents',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const AgentsScreen(),
        ),
      ),

      // Transactions Route (With Layout)
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const TransactionsScreen(),
        ),
      ),

      // Investments Route
      GoRoute(
        path: '/investments',
        name: 'investments',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const InvestmentsScreen(),
        ),
      ),

      // Bill Payments Route
      GoRoute(
        path: '/bill-payments',
        name: 'bill-payments',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const BillPaymentsScreen(),
        ),
      ),

      // E-Voting Route
      GoRoute(
        path: '/e-voting',
        name: 'e-voting',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const VotingScreen(),
        ),
      ),

      // Reports Route
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const ReportsScreen(),
        ),
      ),

      // Settings Route
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => MainLayout(
          currentRoute: state.matchedLocation,
          child: const SettingsScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => MainLayout(
      currentRoute: state.matchedLocation,
      child: _ErrorScreen(error: state.error.toString()),
    ),
  );
}

/// Error Screen
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.home),
            label: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }
}
