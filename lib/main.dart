import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/sms_service.dart';
import 'presentation/providers/user_profile_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SMS service
  await SmsService().initialize();

  // Load current user phone if exists
  final phone = await getCurrentUserPhone();

  runApp(
    ProviderScope(
      overrides: phone != null
          ? [currentUserPhoneProvider.overrideWith((ref) => phone)]
          : [],
      child: const DhanAIApp(),
    ),
  );
}

class DhanAIApp extends StatelessWidget {
  const DhanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dhan-AI',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
