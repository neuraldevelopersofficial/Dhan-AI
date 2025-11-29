import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../repositories/transaction_repository.dart';
import 'database_service.dart';
import 'ai_insights_service.dart';

class WebhookService {
  // Note: Webhook URL removed - now using direct API integration only
  // If you need webhook support in the future, you can add it back

  /// Send all available data and get AI insights
  /// Uses AI service directly (Groq, Gemini, OpenAI, Anthropic, or Custom API)
  static Future<Map<String, dynamic>?> sendDataToWebhook({
    String? userId,
  }) async {
    try {
      // Get user profile
      final databaseService = DatabaseService();
      String? phoneNumber = userId;

      // If no userId provided, try to get current user from SharedPreferences
      if (phoneNumber == null) {
        final prefs = await SharedPreferences.getInstance();
        phoneNumber = prefs.getString('current_user_phone');
      }

      // Get transactions
      final transactionRepository = TransactionRepository();
      final transactions = await transactionRepository.getAllTransactions();

      // Get forecast
      final forecast = await transactionRepository.calculateForecast();

      // Get stability
      final stability = await transactionRepository.calculateStability();

      // Get goals (from mock for now, but can be extended)
      // For now, we'll create empty goals structure

      // Format income transactions
      final incomeTransactions = transactions
          .where((t) => t.type == 'income')
          .map(
            (t) => {
              'amount': t.amount,
              'source': t.category,
              'date': _formatDate(t.date),
              'type': _getPaymentType(t.note ?? ''),
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
              'payment_method': _getPaymentType(t.note ?? ''),
              'description': t.note ?? '',
            },
          )
          .toList();

      // Get user profile if available
      UserProfile? userProfile;
      if (phoneNumber != null) {
        userProfile = await databaseService.getUserByPhone(phoneNumber);
      }

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

      // Add goals if available (for now empty, can be extended)
      metadata['monthly_goal'] = {'emergency_fund': 0, 'savings': 0};

      // Build payload
      final payload = {
        'user_id': userProfile?.phoneNumber ?? userId ?? 'unknown',
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

      // Use AI insights service directly (no webhook fallback)
      try {
        // Generate AI insights using configured API provider
        final insights = await AiInsightsService.generateInsights(
          financialData: payload,
        );
        return insights;
      } catch (e) {
        // Provide helpful error message
        print('AI insights failed: $e');
        throw Exception(
          'Failed to generate AI insights: $e\n\n'
          'Please check:\n'
          '1. API key is correctly entered in Settings (⚙️)\n'
          '2. Selected provider matches the API key\n'
          '3. You have internet connectivity\n'
          '4. API key is valid and has not expired',
        );
      }
    } catch (e) {
      // Re-throw the error as-is (it already has a good message from AI service)
      rethrow;
    }
  }

  /// Format date to YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Determine payment type from transaction note
  static String _getPaymentType(String note) {
    final lower = note.toLowerCase();
    if (lower.contains('upi') ||
        lower.contains('paytm') ||
        lower.contains('phonepe') ||
        lower.contains('gpay')) {
      return 'UPI';
    } else if (lower.contains('cash')) {
      return 'Cash';
    } else if (lower.contains('card') ||
        lower.contains('debit') ||
        lower.contains('credit')) {
      return 'Card';
    } else if (lower.contains('bank') ||
        lower.contains('transfer') ||
        lower.contains('neft') ||
        lower.contains('imps')) {
      return 'Bank Transfer';
    }
    return 'UPI'; // Default
  }

  /// Determine risk profile from stability score
  static String _getRiskProfile(int score) {
    if (score >= 70) return 'low';
    if (score >= 50) return 'moderate';
    return 'high';
  }
}
