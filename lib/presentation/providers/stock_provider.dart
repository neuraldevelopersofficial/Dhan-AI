import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/stock_market_service.dart';
import '../../data/services/ai_copilot_service.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/database_service.dart';
import '../providers/user_profile_provider.dart';
import '../providers/dashboard_provider.dart';

/// Provider for top gainers from Indian stock market
final topGainersProvider = FutureProvider<List<Stock>>((ref) async {
  return await StockMarketService.getTopGainers(limit: 20);
});

/// Provider to refresh top gainers (clears cache and refetches)
final refreshTopGainersProvider = FutureProvider<List<Stock>>((ref) async {
  // Clear cache to force fresh fetch
  StockMarketService.clearCache();
  // Invalidate the provider to trigger refetch
  ref.invalidate(topGainersProvider);
  return await StockMarketService.getTopGainers(limit: 20);
});

/// Provider for AI-powered stock recommendations
final stockRecommendationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    // Get top gainers
    final topGainers = await ref.read(topGainersProvider.future);
    
    // Convert stocks to JSON format for AI
    final gainersJson = topGainers.map((stock) => stock.toJson()).toList();
    
    // Get user's financial summary
    final repository = ref.read(transactionRepositoryProvider);
    final transactions = await repository.getAllTransactions();
    final stability = await repository.calculateStability();
    
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final financialSummary = {
      'monthlyIncome': totalIncome,
      'monthlyExpenses': totalExpenses,
      'balance': totalIncome - totalExpenses,
      'stabilityScore': stability['score'] as int,
      'riskProfile': stability['riskProfile'] as String? ?? 'moderate',
    };
    
    // Get user profile
    final phone = ref.watch(currentUserPhoneProvider);
    final databaseService = DatabaseService();
    final userProfile = phone != null
        ? await databaseService.getUserByPhone(phone)
        : null;
    
    // Get AI recommendations
    final recommendations = await AiCopilotService.getStockRecommendations(
      topGainers: gainersJson,
      financialSummary: financialSummary,
      userProfile: userProfile,
    );
    
    // Ensure we return exactly 5 recommendations
    final limitedRecommendations = recommendations.take(5).toList();
    
    // If we have less than 5, pad with top gainers
    if (limitedRecommendations.length < 5) {
      final usedSymbols = limitedRecommendations
          .map((r) => r['symbol'] as String?)
          .where((s) => s != null)
          .toSet();
      
      final additionalStocks = topGainers
          .where((stock) => !usedSymbols.contains(stock.symbol))
          .take(5 - limitedRecommendations.length)
          .map((stock) => {
                'symbol': stock.symbol,
                'name': stock.name,
                'currentPrice': stock.currentPrice,
                'changePercent': stock.changePercent,
                'sector': stock.sector,
                'reason': 'Strong performance today. Consider for diversified portfolio based on top gainer status.',
                'riskLevel': 'medium',
                'investmentAmount': '₹${(stock.currentPrice * 10).toStringAsFixed(0)}',
                'timeframe': 'Medium-term',
                'potentialReturn': '${(stock.changePercent * 0.5).toStringAsFixed(1)}% annually',
              })
          .toList();
      
      limitedRecommendations.addAll(additionalStocks);
    }
    
    return limitedRecommendations.take(5).toList();
  } catch (e) {
    print('Error getting stock recommendations: $e');
    // Return empty list on error
    return [];
  }
});
