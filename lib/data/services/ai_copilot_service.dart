import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../models/nudge_model.dart';
import '../models/goal_model.dart';
import '../models/user_profile_model.dart';
import 'ai_insights_service.dart';

/// Comprehensive AI service for all AI-powered features using Groq
class AiCopilotService {
  /// Categorize a transaction using AI
  static Future<String> categorizeTransaction({
    required String description,
    required double amount,
    required String type, // 'income' or 'expense'
    UserProfile? userProfile,
  }) async {
    final prompt = '''
Categorize this transaction:

Description: $description
Amount: ₹$amount
Type: $type
${userProfile != null ? 'User Occupation: ${userProfile.occupationCategory}' : ''}

Return ONLY the category name (e.g., "Food", "Transport", "Salary", "Delivery", "Rent", "Fuel", "Entertainment", "Healthcare", "Shopping", "Bills", "Other").
Do not include any explanation, just the category name.
''';

    final response = await _callGroq(prompt, maxTokens: 50);
    return response.trim();
  }

  /// Generate smart nudges based on user's financial data
  static Future<List<Nudge>> generateNudges({
    required List<Transaction> transactions,
    required Map<String, dynamic> forecast,
    required Map<String, dynamic> stability,
    UserProfile? userProfile,
  }) async {
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpenses;
    final stabilityScore = stability['score'] as int;

    final prompt = '''
Analyze this user's financial situation and generate 3-5 actionable nudges (recommendations):

**Financial Summary:**
- Total Income: ₹${totalIncome.toStringAsFixed(2)}
- Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}
- Net Balance: ₹${netBalance.toStringAsFixed(2)}
- Stability Score: $stabilityScore/100
- Risk Profile: ${stability['riskProfile'] ?? 'moderate'}

**User Profile:**
${userProfile != null ? '- Occupation: ${userProfile.occupationCategory}\n- Income Range: ${userProfile.incomeRange}\n- Monthly Obligations: ${userProfile.monthlyObligations}' : 'Not available'}

**Recent Transactions (last 10):**
${transactions.take(10).map((t) => '${t.type}: ₹${t.amount} - ${t.category}').join('\n')}

Generate nudges in JSON format:
{
  "nudges": [
    {
      "title": "Short actionable title",
      "reason": "Why this nudge is relevant",
      "impact": "Expected impact (e.g., 'Save ₹500/month')",
      "riskLevel": "low|medium|high",
      "type": "savings|spending|investment|goal"
    }
  ]
}

Return ONLY valid JSON, no other text.
''';

    final response = await _callGroq(prompt, maxTokens: 800);
    
    try {
      final data = jsonDecode(response);
      final nudgesJson = data['nudges'] as List;
      return nudgesJson.asMap().entries.map((entry) {
        final nudge = entry.value as Map<String, dynamic>;
        return Nudge(
          id: 'nudge_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          title: nudge['title'] as String,
          reason: nudge['reason'] as String,
          impact: nudge['impact'] as String,
          riskLevel: nudge['riskLevel'] as String,
          type: nudge['type'] as String,
        );
      }).toList();
    } catch (e) {
      // Fallback to default nudges if AI fails
      return _getDefaultNudges(stabilityScore, netBalance);
    }
  }

  /// AI Copilot Chat - conversational financial advice
  static Future<String> chat({
    required String userMessage,
    required List<Transaction> recentTransactions,
    required Map<String, dynamic> financialSummary,
    UserProfile? userProfile,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final history = conversationHistory ?? [];
    final historyText = history.isEmpty
        ? ''
        : history
            .map((msg) => '${msg['role']}: ${msg['content']}')
            .join('\n');

    final prompt = '''
You are a friendly financial advisor AI assistant helping users with irregular incomes manage their money.

**User's Financial Summary:**
- Current Balance: ₹${financialSummary['balance'] ?? 0}
- Monthly Income: ₹${financialSummary['monthlyIncome'] ?? 0}
- Monthly Expenses: ₹${financialSummary['monthlyExpenses'] ?? 0}
- Stability Score: ${financialSummary['stabilityScore'] ?? 0}/100

**User Profile:**
${userProfile != null ? '- Name: ${userProfile.name}\n- Occupation: ${userProfile.occupationCategory}\n- Income Range: ${userProfile.incomeRange}' : 'Not available'}

**Recent Transactions:**
${recentTransactions.take(5).map((t) => '${t.type}: ₹${t.amount} - ${t.category}').join('\n')}

**Conversation History:**
$historyText

**User's Question:**
$userMessage

Provide a helpful, concise, and actionable response. Be friendly and empathetic. Keep it under 200 words.
''';

    return await _callGroq(prompt, maxTokens: 300);
  }

  /// What-if simulation - predict financial outcomes
  static Future<Map<String, dynamic>> whatIfSimulation({
    required String scenario, // e.g., "What if I save ₹2000 more per month?"
    required List<Transaction> currentTransactions,
    required Map<String, dynamic> currentForecast,
    UserProfile? userProfile,
  }) async {
    final prompt = '''
Simulate this financial scenario:

**Current Situation:**
- Monthly Income: ₹${currentForecast['monthlyIncome'] ?? 0}
- Monthly Expenses: ₹${currentForecast['monthlyExpenses'] ?? 0}
- Current Balance: ₹${currentForecast['currentBalance'] ?? 0}

**Scenario to Simulate:**
$scenario

**Recent Transactions:**
${currentTransactions.take(10).map((t) => '${t.type}: ₹${t.amount} - ${t.category}').join('\n')}

Return analysis in JSON format:
{
  "projectedBalance": 0,
  "monthlyChange": 0,
  "impact": "Description of impact",
  "recommendation": "Actionable recommendation",
  "timeline": "When effects will be visible"
}

Return ONLY valid JSON, no other text.
''';

    final response = await _callGroq(prompt, maxTokens: 400);
    
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return {
        'projectedBalance': 0,
        'monthlyChange': 0,
        'impact': 'Unable to simulate scenario. Please try again.',
        'recommendation': 'Check your inputs and try again.',
        'timeline': 'N/A',
      };
    }
  }

  /// Generate personalized investment recommendations
  static Future<Map<String, dynamic>> getInvestmentRecommendations({
    required List<Transaction> transactions,
    required Map<String, dynamic> financialSummary,
    UserProfile? userProfile,
  }) async {
    final monthlySavings = (financialSummary['monthlyIncome'] ?? 0.0) -
        (financialSummary['monthlyExpenses'] ?? 0.0);
    final riskProfile = financialSummary['riskProfile'] ?? 'moderate';

    final prompt = '''
Provide investment recommendations for this user:

**Financial Situation:**
- Monthly Income: ₹${financialSummary['monthlyIncome'] ?? 0}
- Monthly Expenses: ₹${financialSummary['monthlyExpenses'] ?? 0}
- Monthly Savings: ₹$monthlySavings
- Risk Profile: $riskProfile
- Stability Score: ${financialSummary['stabilityScore'] ?? 0}/100

**User Profile:**
${userProfile != null ? '- Occupation: ${userProfile.occupationCategory}\n- Income Range: ${userProfile.incomeRange}' : 'Not available'}

Return recommendations in JSON format:
{
  "recommendations": [
    {
      "instrument": "FD|Mutual Fund|Stocks|PPF|Gold",
      "amount": 0,
      "reason": "Why this is suitable",
      "riskLevel": "low|medium|high",
      "expectedReturn": "X% annually"
    }
  ],
  "totalRecommended": 0,
  "strategy": "Overall investment strategy"
}

Return ONLY valid JSON, no other text.
''';

    final response = await _callGroq(prompt, maxTokens: 600);
    
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return {
        'recommendations': [],
        'totalRecommended': 0,
        'strategy': 'Unable to generate recommendations. Please try again.',
      };
    }
  }

  /// Suggest goals based on user's financial situation
  static Future<List<Goal>> suggestGoals({
    required List<Transaction> transactions,
    required Map<String, dynamic> financialSummary,
    UserProfile? userProfile,
  }) async {
    final monthlySavings = (financialSummary['monthlyIncome'] ?? 0.0) -
        (financialSummary['monthlyExpenses'] ?? 0.0);

    final prompt = '''
Suggest 3-4 financial goals for this user:

**Financial Situation:**
- Monthly Income: ₹${financialSummary['monthlyIncome'] ?? 0}
- Monthly Expenses: ₹${financialSummary['monthlyExpenses'] ?? 0}
- Monthly Savings: ₹$monthlySavings
- Stability Score: ${financialSummary['stabilityScore'] ?? 0}/100

**User Profile:**
${userProfile != null ? '- Occupation: ${userProfile.occupationCategory}\n- Income Range: ${userProfile.incomeRange}\n- Monthly Obligations: ${userProfile.monthlyObligations}' : 'Not available'}

Return goals in JSON format:
{
  "goals": [
    {
      "title": "Goal name",
      "targetAmount": 0,
      "currentAmount": 0,
      "deadline": "YYYY-MM-DD",
      "type": "emergency_fund|purchase|vacation|debt_payoff",
      "description": "Why this goal is important"
    }
  ]
}

Return ONLY valid JSON, no other text.
''';

    final response = await _callGroq(prompt, maxTokens: 600);
    
    try {
      final data = jsonDecode(response);
      final goalsJson = data['goals'] as List;
      return goalsJson.asMap().entries.map((entry) {
        final goal = entry.value as Map<String, dynamic>;
        return Goal(
          id: 'goal_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          title: goal['title'] as String,
          target: (goal['targetAmount'] as num).toDouble(),
          current: (goal['currentAmount'] as num).toDouble(),
          type: goal['type'] as String,
        );
      }).toList();
    } catch (e) {
      return _getDefaultGoals(monthlySavings);
    }
  }

  /// Call Groq API with a prompt
  static Future<String> _callGroq(String prompt, {int maxTokens = 500}) async {
    final apiKey = await AiInsightsService.getApiKey(ApiProvider.groq);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key not configured. Please add it in Settings.');
    }

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful financial advisor AI. Provide concise, actionable responses. Always return data in the requested format (JSON when requested).',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
        'Groq API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Default nudges if AI fails
  static List<Nudge> _getDefaultNudges(int stabilityScore, double netBalance) {
    final nudges = <Nudge>[];
    
    if (netBalance < 0) {
      nudges.add(Nudge(
        id: 'nudge_1',
        title: 'Reduce Non-Essential Spending',
        reason: 'Your expenses exceed income this month',
        impact: 'Save ₹${(-netBalance).toStringAsFixed(0)}/month',
        riskLevel: 'high',
        type: 'spending',
      ));
    }
    
    if (stabilityScore < 50) {
      nudges.add(Nudge(
        id: 'nudge_2',
        title: 'Build Emergency Fund',
        reason: 'Low financial stability score',
        impact: 'Aim for ₹5000 emergency fund',
        riskLevel: 'medium',
        type: 'savings',
      ));
    }
    
    return nudges;
  }

  /// Default goals if AI fails
  static List<Goal> _getDefaultGoals(double monthlySavings) {
    return [
      Goal(
        id: 'goal_1',
        title: 'Emergency Fund',
        target: 10000,
        current: 0,
        type: 'emergency_fund',
      ),
    ];
  }

  /// Generate stock investment recommendations based on top gainers and user profile
  static Future<List<Map<String, dynamic>>> getStockRecommendations({
    required List<Map<String, dynamic>> topGainers, // List of stock data
    required Map<String, dynamic> financialSummary,
    UserProfile? userProfile,
  }) async {
    final monthlySavings = (financialSummary['monthlyIncome'] ?? 0.0) -
        (financialSummary['monthlyExpenses'] ?? 0.0);
    final riskProfile = financialSummary['riskProfile'] ?? 'moderate';

    // Format top gainers for prompt
    final gainersText = topGainers.take(10).map((stock) {
      return '${stock['name']} (${stock['symbol']}): ₹${stock['currentPrice']} (+${stock['changePercent']}%) - ${stock['sector']}';
    }).join('\n');

    final prompt = '''
You are a financial advisor specializing in the Indian stock market. Based on today's top gainers and the user's financial profile, recommend 5 stocks for investment.

**Today's Top Gainers:**
$gainersText

**User's Financial Situation:**
- Monthly Income: ₹${financialSummary['monthlyIncome'] ?? 0}
- Monthly Expenses: ₹${financialSummary['monthlyExpenses'] ?? 0}
- Monthly Savings: ₹$monthlySavings
- Risk Profile: $riskProfile
- Stability Score: ${financialSummary['stabilityScore'] ?? 0}/100

**User Profile:**
${userProfile != null ? '- Occupation: ${userProfile.occupationCategory}\n- Income Range: ${userProfile.incomeRange}' : 'Not available'}

Analyze the top gainers and recommend EXACTLY 5 stocks from the list above that are suitable for this user. Consider:
1. Risk profile alignment
2. Affordability based on savings
3. Sector diversification
4. Growth potential
5. Stability and fundamentals

Return recommendations in JSON format:
{
  "recommendations": [
    {
      "symbol": "STOCK_SYMBOL",
      "name": "Company Name",
      "currentPrice": 0,
      "changePercent": 0,
      "sector": "Sector Name",
      "reason": "Why this stock is recommended for this user (2-3 sentences)",
      "riskLevel": "low|medium|high",
      "investmentAmount": "Suggested investment amount in ₹",
      "timeframe": "Short-term|Medium-term|Long-term",
      "potentialReturn": "Expected return estimate"
    }
  ]
}

IMPORTANT: Only recommend stocks from the provided top gainers list. Return EXACTLY 5 recommendations. Return ONLY valid JSON, no other text.
''';

    final response = await _callGroq(prompt, maxTokens: 1000);
    
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        final data = jsonDecode(jsonStr!);
        final recommendations = data['recommendations'] as List;
        
        return recommendations.cast<Map<String, dynamic>>();
      }
      
      // Try parsing the whole response
      final data = jsonDecode(response);
      final recommendations = data['recommendations'] as List;
      return recommendations.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing stock recommendations: $e');
      // Return default recommendations based on top gainers
      return _getDefaultStockRecommendations(topGainers.take(5).toList());
    }
  }

  /// Default stock recommendations if AI fails
  static List<Map<String, dynamic>> _getDefaultStockRecommendations(
    List<Map<String, dynamic>> topGainers,
  ) {
    return topGainers.map((stock) {
      return {
        'symbol': stock['symbol'],
        'name': stock['name'],
        'currentPrice': stock['currentPrice'],
        'changePercent': stock['changePercent'],
        'sector': stock['sector'],
        'reason': 'Strong performance today. Consider for diversified portfolio.',
        'riskLevel': 'medium',
        'investmentAmount': '₹${(stock['currentPrice'] * 10).toStringAsFixed(0)}',
        'timeframe': 'Medium-term',
        'potentialReturn': '${(stock['changePercent'] * 0.5).toStringAsFixed(1)}% annually',
      };
    }).toList();
  }
}

