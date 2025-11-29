import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/main_navigation_screen.dart';
import '../../presentation/screens/nudges_screen.dart';
import '../../presentation/screens/transactions_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/signup_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/api_settings_screen.dart';
import '../../presentation/screens/copilot_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(path: '/nudges', builder: (context, state) => const NudgesScreen()),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
    // Placeholder routes for screens to be implemented
    GoRoute(
      path: '/vaults',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Goals & Vaults')),
        body: const Center(child: Text('Coming soon')),
      ),
    ),
    GoRoute(
      path: '/invest',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Investment Coach')),
        body: const Center(child: Text('Coming soon')),
      ),
    ),
    GoRoute(
      path: '/copilot',
      builder: (context, state) {
        return const CopilotScreen();
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Coming soon')),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/api-settings',
      builder: (context, state) => const ApiSettingsScreen(),
    ),
    GoRoute(
      path: '/rewards',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Rewards')),
        body: const Center(child: Text('Coming soon')),
      ),
    ),
  ],
);
