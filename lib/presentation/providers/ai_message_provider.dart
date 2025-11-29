import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_headlines_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/services/database_service.dart';
import '../providers/user_profile_provider.dart';

/// Provider that automatically fetches transaction data and generates
/// AI motivational messages when app opens
final aiMessagesProvider = FutureProvider<List<String>>((ref) async {
  try {
    // Get all transactions
    final repository = TransactionRepository();
    final transactions = await repository.getAllTransactions();
    
    // Only proceed if we have transactions
    if (transactions.isEmpty) {
      return [
        'Add your first transaction to get personalized insights!',
        'Start tracking your expenses to see financial tips here.',
      ];
    }

    // Get user profile for context
    final phone = ref.watch(currentUserPhoneProvider);
    final databaseService = DatabaseService();
    
    // Prepare financial data similar to webhook service
    final forecast = await repository.calculateForecast();
    final stability = await repository.calculateStability();
    
    // Format income transactions
    final incomeTransactions = transactions
        .where((t) => t.type == 'income')
        .map(
          (t) => {
            'amount': t.amount,
            'source': t.category,
            'date': _formatDate(t.date),
            'type': 'UPI',
          },
        )
        .toList();

    // Format expense transactions
    final expenseTransactions = transactions
        .where((t) => t.type == 'expense')
        .map(
          (t) => {
            'amount': t.amount,
            'category': t.category,
            'date': _formatDate(t.date),
            'payment_method': 'UPI',
            'description': t.note ?? '',
          },
        )
        .toList();

    // Get user profile if available
    final userProfile = phone != null
        ? await databaseService.getUserByPhone(phone)
        : null;

    // Build metadata
    final metadata = <String, dynamic>{
      'previous_forecast': {
        'week': {
          'predicted_expenses': forecast['avgDailyExpense'] as double? ?? 0.0,
          'actual_expenses': expenseTransactions.fold<double>(
            0.0,
            (sum, e) => sum + (e['amount'] as num).toDouble(),
          ),
        },
      },
      'risk_profile': _getRiskProfile(stability['score'] as int),
    };

    // Build payload
    final payload = {
      'user_id': userProfile?.phoneNumber ?? phone ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
      'income': incomeTransactions,
      'expenses': expenseTransactions,
      'metadata': metadata,
      'user_profile': userProfile != null
          ? {
              'name': userProfile.name,
              'phone_number': userProfile.phoneNumber,
              'occupation_category': userProfile.occupationCategory,
              'income_range': userProfile.incomeRange,
              'monthly_obligations': userProfile.monthlyObligations,
            }
          : null,
    };
    
    // Generate headlines using the headlines service
    final headlines = await AiHeadlinesService.generateHeadlines(
      financialData: payload,
    );

    if (headlines.isEmpty) {
      return _getDefaultMessages();
    }

    return headlines;
  } catch (e) {
    print('Error generating AI messages: $e');
    // Return default messages on error
    return _getDefaultMessages();
  }
});

/// Format date to YYYY-MM-DD
String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Determine risk profile from stability score
String _getRiskProfile(int score) {
  if (score >= 70) return 'low';
  if (score >= 50) return 'moderate';
  return 'high';
}


/// Get default motivational messages when AI is unavailable
List<String> _getDefaultMessages() {
  return [
    'Keep tracking your expenses to build better financial habits! 💰',
    'Every small saving adds up to big goals! 🎯',
    'Stay consistent with your budget tracking! 📊',
    'Review your transactions regularly to optimize spending! 💡',
    'You\'re making progress with every transaction logged! ✨',
  ];
}
