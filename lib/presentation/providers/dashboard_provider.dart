import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/mock_api.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/nudge_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/services/sms_service.dart';
import '../../data/services/ai_copilot_service.dart';
import '../../data/services/database_service.dart';
import '../providers/user_profile_provider.dart';

// Transaction repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// SMS service provider
final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

// User provider
final userProvider = FutureProvider<User>((ref) async {
  return await MockApi.getUser('current_user');
});

// Dashboard data provider (now uses real transactions)
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final transactions = await repository.getDashboardTransactions();
  final stability = await repository.calculateStability();
  final forecast = await repository.calculateForecast();

  // Still get goals and other data from mock for now
  final mockData = await MockApi.getDashboard('current_user');

  return {
    'stability': stability,
    'forecast': forecast,
    'transactions': transactions,
    'goals': mockData['goals'] as List<Goal>,
  };
});

// Stability score provider (now calculated from real transactions)
final stabilityProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final stability = await repository.calculateStability();
  return stability['score'] as int;
});

// Forecast provider (now calculated from real transactions)
final forecastProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.calculateForecast();
});

// Transactions provider (now uses real SMS + manual transactions)
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getAllTransactions();
});

// Goals provider
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  return await MockApi.getGoals('current_user');
});

// Nudges provider - now uses AI to generate personalized nudges
final nudgesProvider = FutureProvider<List<Nudge>>((ref) async {
  try {
    // Get real transaction data
    final repository = ref.read(transactionRepositoryProvider);
    final transactions = await repository.getAllTransactions();
    final forecast = await repository.calculateForecast();
    final stability = await repository.calculateStability();

    // Get user profile
    final phone = ref.watch(currentUserPhoneProvider);
    final databaseService = DatabaseService();
    final userProfile = phone != null
        ? await databaseService.getUserByPhone(phone)
        : null;

    // Generate AI nudges
    final nudges = await AiCopilotService.generateNudges(
      transactions: transactions,
      forecast: forecast,
      stability: stability,
      userProfile: userProfile,
    );

    return nudges;
  } catch (e) {
    // Fallback to mock data if AI fails
    print('AI nudges failed, using mock data: $e');
    return await MockApi.getNudges('current_user');
  }
});
