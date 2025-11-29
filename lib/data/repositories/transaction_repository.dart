import '../models/transaction_model.dart';
import '../services/sms_service.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final SmsService _smsService = SmsService();
  final Uuid _uuid = const Uuid();
  
  // In-memory storage for manually added transactions
  static final List<Transaction> _manualTransactions = [];

  /// Get all transactions (SMS + manual)
  Future<List<Transaction>> getAllTransactions() async {
    final List<Transaction> allTransactions = [];

    // Get SMS transactions
    try {
      final smsTransactions = await _smsService.getStoredTransactions();
      allTransactions.addAll(smsTransactions);
    } catch (e) {
      // If SMS service fails, continue with manual transactions
    }

    // Add manual transactions
    allTransactions.addAll(_manualTransactions);

    // Sort by date (newest first)
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    return allTransactions;
  }

  /// Add a manual transaction
  Future<Transaction> addTransaction(Transaction transaction) async {
    // If transaction doesn't have an ID, generate one
    final transactionWithId = transaction.id.isEmpty
        ? Transaction(
            id: _uuid.v4(),
            type: transaction.type,
            amount: transaction.amount,
            category: transaction.category,
            date: transaction.date,
            note: transaction.note,
          )
        : transaction;

    _manualTransactions.add(transactionWithId);
    return transactionWithId;
  }

  /// Get transactions for dashboard (combines SMS + manual only, no mock data)
  Future<List<Transaction>> getDashboardTransactions() async {
    final List<Transaction> allTransactions = [];

    // Get SMS transactions
    try {
      final smsTransactions = await _smsService.getStoredTransactions();
      allTransactions.addAll(smsTransactions);
    } catch (e) {
      // Continue if SMS fails
    }

    // Add manual transactions
    allTransactions.addAll(_manualTransactions);

    // Sort by date (newest first)
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    return allTransactions;
  }

  /// Calculate forecast data from transactions
  Future<Map<String, dynamic>> calculateForecast({
    int days = 7,
  }) async {
    final transactions = await getAllTransactions();
    
    // Filter transactions from last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    // Calculate average daily balance change
    double totalIncome = 0;
    double totalExpense = 0;
    int incomeDays = 0;
    int expenseDays = 0;

    final Map<int, double> dailyBalance = {};
    
    for (final txn in recentTransactions) {
      final dayKey = txn.date.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
      dailyBalance[dayKey] = (dailyBalance[dayKey] ?? 0.0) + 
          (txn.type == 'income' ? txn.amount : -txn.amount);
      
      if (txn.type == 'income') {
        totalIncome += txn.amount;
        incomeDays++;
      } else {
        totalExpense += txn.amount;
        expenseDays++;
      }
    }

    // Calculate current balance (rough estimate)
    double currentBalance = 0;
    for (final txn in transactions.take(50)) {
      currentBalance += txn.type == 'income' ? txn.amount : -txn.amount;
    }

    // Predict next 7 days
    final avgDailyIncome = incomeDays > 0 ? totalIncome / incomeDays : 0;
    final avgDailyExpense = expenseDays > 0 ? totalExpense / expenseDays : 0;
    final avgDailyChange = avgDailyIncome - avgDailyExpense;

    final List<double> next7Days = [];
    double runningBalance = currentBalance;
    
    for (int i = 0; i < days; i++) {
      runningBalance += avgDailyChange;
      next7Days.add(runningBalance);
    }

    return {
      'next7Days': next7Days,
      'predictedEndBalance': next7Days.isNotEmpty ? next7Days.last : currentBalance,
      'currentBalance': currentBalance,
      'avgDailyIncome': avgDailyIncome,
      'avgDailyExpense': avgDailyExpense,
    };
  }

  /// Calculate stability score
  Future<Map<String, dynamic>> calculateStability() async {
    final transactions = await getAllTransactions();
    
    // Filter transactions from last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    if (recentTransactions.isEmpty) {
      return {
        'score': 50,
        'safeDays': 0,
        'trend': 'unknown',
      };
    }

    // Calculate income consistency
    final incomeTransactions = recentTransactions
        .where((t) => t.type == 'income')
        .toList();
    
    final expenseTransactions = recentTransactions
        .where((t) => t.type == 'expense')
        .toList();

    double totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    double totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    // Calculate days until balance runs out
    final dailyAvgExpense = expenseTransactions.isNotEmpty
        ? totalExpense / 30
        : 0.0;
    
    final currentBalance = totalIncome - totalExpense;
    final safeDays = dailyAvgExpense > 0 
        ? (currentBalance / dailyAvgExpense).floor()
        : 999;

    // Calculate stability score (0-100)
    // Based on: income consistency, expense predictability, balance safety
    int score = 50; // Base score
    
    if (incomeTransactions.length >= 10) score += 20; // Regular income
    if (currentBalance > 0) score += 20; // Positive balance
    if (safeDays >= 7) score += 10; // Safe for a week
    
    score = score.clamp(0, 100);

    String trend = 'stable';
    if (score < 40) trend = 'declining';
    else if (score > 70) trend = 'improving';

    return {
      'score': score,
      'safeDays': safeDays.clamp(0, 999),
      'trend': trend,
    };
  }
}

