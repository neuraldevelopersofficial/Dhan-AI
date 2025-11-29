import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_insights_service.dart';

/// Service for generating short motivational headlines from financial data
class AiHeadlinesService {
  /// Generate short motivational headlines (like news ticker)
  static Future<List<String>> generateHeadlines({
    required Map<String, dynamic> financialData,
    ApiProvider? provider,
  }) async {
    final selectedProvider = provider ?? await AiInsightsService.getSelectedProvider();
    final apiKey = await AiInsightsService.getApiKey(selectedProvider);

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API key not configured. Please configure it in Settings (⚙️).',
      );
    }

    try {
      switch (selectedProvider) {
        case ApiProvider.openai:
          return await _generateWithOpenAI(financialData, apiKey);
        case ApiProvider.anthropic:
          return await _generateWithAnthropic(financialData, apiKey);
        case ApiProvider.gemini:
          return await _generateWithGemini(financialData, apiKey);
        case ApiProvider.groq:
          return await _generateWithGroq(financialData, apiKey);
        case ApiProvider.custom:
          return await _generateWithCustomApi(financialData, apiKey);
      }
    } catch (e) {
      print('Error in ${selectedProvider.name} headlines API call: $e');
      rethrow;
    }
  }

  /// Build prompt specifically for short motivational headlines
  static String _buildHeadlinesPrompt(Map<String, dynamic> financialData) {
    final income = financialData['income'] as List;
    final expenses = financialData['expenses'] as List;
    final metadata = financialData['metadata'] as Map<String, dynamic>;
    
    final totalIncome = income.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] as num).toDouble()),
    );
    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] as num).toDouble()),
    );
    final netBalance = totalIncome - totalExpenses;
    
    final riskProfile = metadata['risk_profile'] as String? ?? 'unknown';
    
    // Calculate monthly trends
    final now = DateTime.now();
    final thisMonth = expenses.where((e) {
      final dateStr = e['date'] as String? ?? '';
      try {
        final date = DateTime.parse(dateStr);
        return date.year == now.year && date.month == now.month;
      } catch (e) {
        return false;
      }
    }).length;

    return '''
You are a friendly financial coach. Based on this financial data, generate 5-7 SHORT motivational headlines (like news ticker scrolls).
Each headline should be:
- Maximum 80 characters
- Motivational and encouraging (like "Keep going!", "Try saving ₹180 today")
- Actionable (like "You're short ₹600 for this month")
- Casual and conversational (like we're chatting)
- Specific with numbers when relevant

**Financial Summary:**
- Total Income: ₹${totalIncome.toStringAsFixed(2)}
- Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}
- Net Balance: ₹${netBalance.toStringAsFixed(2)}
- Risk Profile: $riskProfile
- Transactions this month: $thisMonth

Generate headlines that:
1. Motivate based on spending patterns
2. Give specific savings targets
3. Warn about budget shortfalls
4. Celebrate good habits
5. Suggest small daily actions

Return ONLY a JSON array of strings, like:
["Keep going! Your savings are on track", "Try saving ₹180 today", "You're short ₹600 for this month"]

Make them feel like friendly news headlines scrolling by.
''';
  }

  /// Generate headlines using OpenAI
  static Future<List<String>> _generateWithOpenAI(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildHeadlinesPrompt(financialData);

    final response = await http.post(
      Uri.parse(AiInsightsService.openaiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a friendly financial coach. Generate short, motivational headlines (max 80 chars each) as a JSON array of strings.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.8,
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return _parseHeadlinesResponse(content);
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  /// Generate headlines using Anthropic Claude
  static Future<List<String>> _generateWithAnthropic(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildHeadlinesPrompt(financialData);

    final response = await http.post(
      Uri.parse(AiInsightsService.anthropicUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 200,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'];
      return _parseHeadlinesResponse(content);
    } else {
      throw Exception('Anthropic API error: ${response.statusCode}');
    }
  }

  /// Generate headlines using Google Gemini
  static Future<List<String>> _generateWithGemini(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildHeadlinesPrompt(financialData);

    final url = Uri.parse(
      '${AiInsightsService.geminiBaseUrl}/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 200},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'];
      return _parseHeadlinesResponse(content);
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  /// Generate headlines using Groq
  static Future<List<String>> _generateWithGroq(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildHeadlinesPrompt(financialData);

    final response = await http.post(
      Uri.parse(AiInsightsService.groqUrl),
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
                'You are a friendly financial coach. Generate short, motivational headlines (max 80 chars each) as a JSON array of strings.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.8,
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return _parseHeadlinesResponse(content);
    } else {
      throw Exception('Groq API error: ${response.statusCode}');
    }
  }

  /// Generate headlines using custom API
  static Future<List<String>> _generateWithCustomApi(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final customUrl = await AiInsightsService.getCustomApiUrl();
    if (customUrl == null || customUrl.isEmpty) {
      throw Exception('Custom API URL not configured');
    }

    final response = await http.post(
      Uri.parse(customUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(financialData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['headlines'] is List) {
        return (data['headlines'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty && e.length <= 120)
            .toList();
      }
      return _parseHeadlinesResponse(response.body);
    } else {
      throw Exception('Custom API error: ${response.statusCode}');
    }
  }

  /// Parse headlines from AI response
  static List<String> _parseHeadlinesResponse(String content) {
    try {
      // Try to parse as JSON array directly
      final parsed = jsonDecode(content);
      if (parsed is List) {
        return parsed
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty && e.length <= 120)
            .toList();
      }
      
      // Try to find JSON array in the content
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
      if (jsonMatch != null) {
        final arrayStr = jsonMatch.group(0);
        final parsed = jsonDecode(arrayStr!);
        if (parsed is List) {
          return parsed
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty && e.length <= 120)
              .toList();
        }
      }
      
      // Fallback: extract quoted strings
      final quotedMatches = RegExp(r'"([^"]{1,120})"').allMatches(content);
      final headlines = quotedMatches.map((m) => m.group(1)!).toList();
      if (headlines.isNotEmpty) {
        return headlines;
      }
      
      // Last resort: split by newlines and take valid lines
      final lines = content
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.length <= 120 && !e.startsWith('```'))
          .take(7)
          .toList();
      return lines;
    } catch (e) {
      print('Error parsing headlines: $e');
      return [];
    }
  }
}
