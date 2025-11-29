import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum ApiProvider { openai, anthropic, gemini, groq, custom }

class AiInsightsService {
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _anthropicApiKeyKey = 'anthropic_api_key';
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _groqApiKeyKey = 'groq_api_key';
  static const String _customApiUrlKey = 'custom_api_url';
  static const String _customApiKeyKey = 'custom_api_key';
  static const String _selectedProviderKey = 'selected_api_provider';

  /// Quick setup with provided API keys (optional - for convenience)
  static Future<void> setupDefaultKeys({
    String? geminiKey1,
    String? geminiKey2,
    String? groqKey1,
    String? groqKey2,
  }) async {
    // Use first available key for each provider
    if (geminiKey1 != null && geminiKey1.isNotEmpty) {
      await saveApiKey(ApiProvider.gemini, geminiKey1);
    } else if (geminiKey2 != null && geminiKey2.isNotEmpty) {
      await saveApiKey(ApiProvider.gemini, geminiKey2);
    }

    if (groqKey1 != null && groqKey1.isNotEmpty) {
      await saveApiKey(ApiProvider.groq, groqKey1);
    } else if (groqKey2 != null && groqKey2.isNotEmpty) {
      await saveApiKey(ApiProvider.groq, groqKey2);
    }

    // Set Groq as default (fast and free tier)
    await setSelectedProvider(ApiProvider.groq);
  }

  // API Endpoints
  static const String openaiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String anthropicUrl = 'https://api.anthropic.com/v1/messages';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Save API key for a provider
  static Future<void> saveApiKey(ApiProvider provider, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case ApiProvider.openai:
        await prefs.setString(_openaiApiKeyKey, apiKey);
        break;
      case ApiProvider.anthropic:
        await prefs.setString(_anthropicApiKeyKey, apiKey);
        break;
      case ApiProvider.gemini:
        await prefs.setString(_geminiApiKeyKey, apiKey);
        break;
      case ApiProvider.groq:
        await prefs.setString(_groqApiKeyKey, apiKey);
        break;
      case ApiProvider.custom:
        await prefs.setString(_customApiKeyKey, apiKey);
        break;
    }
  }

  /// Get API key for a provider
  static Future<String?> getApiKey(ApiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case ApiProvider.openai:
        return prefs.getString(_openaiApiKeyKey);
      case ApiProvider.anthropic:
        return prefs.getString(_anthropicApiKeyKey);
      case ApiProvider.gemini:
        return prefs.getString(_geminiApiKeyKey);
      case ApiProvider.groq:
        return prefs.getString(_groqApiKeyKey);
      case ApiProvider.custom:
        return prefs.getString(_customApiKeyKey);
    }
  }

  /// Save custom API URL
  static Future<void> saveCustomApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customApiUrlKey, url);
  }

  /// Get custom API URL
  static Future<String?> getCustomApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customApiUrlKey);
  }

  /// Set selected provider
  static Future<void> setSelectedProvider(ApiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProviderKey, provider.name);
  }

  /// Get selected provider
  static Future<ApiProvider> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString(_selectedProviderKey);
    if (providerName == null) return ApiProvider.openai; // Default

    return ApiProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => ApiProvider.openai,
    );
  }

  /// Generate insights from financial data
  static Future<Map<String, dynamic>> generateInsights({
    required Map<String, dynamic> financialData,
    ApiProvider? provider,
  }) async {
    final selectedProvider = provider ?? await getSelectedProvider();
    final apiKey = await getApiKey(selectedProvider);

    print('Selected provider: ${selectedProvider.name}');
    print('API key present: ${apiKey != null && apiKey.isNotEmpty}');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API key not configured for ${selectedProvider.name}. Please configure it in Settings (⚙️).',
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
      print('Error in ${selectedProvider.name} API call: $e');
      rethrow;
    }
  }

  /// Generate insights using OpenAI
  static Future<Map<String, dynamic>> _generateWithOpenAI(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildPrompt(financialData);

    final response = await http.post(
      Uri.parse(openaiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // Using cheaper model, can change to gpt-4
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a financial advisor helping users with irregular incomes manage their money. Provide concise, actionable insights in JSON format.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Try to parse as JSON, fallback to text
      try {
        final insights = jsonDecode(content);
        return {'insights': insights};
      } catch (e) {
        return {'insights': content};
      }
    } else {
      throw Exception(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Generate insights using Anthropic Claude
  static Future<Map<String, dynamic>> _generateWithAnthropic(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildPrompt(financialData);

    final response = await http.post(
      Uri.parse(anthropicUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307', // Using cheaper model
        'max_tokens': 500,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'];

      // Try to parse as JSON, fallback to text
      try {
        final insights = jsonDecode(content);
        return {'insights': insights};
      } catch (e) {
        return {'insights': content};
      }
    } else {
      throw Exception(
        'Anthropic API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Generate insights using Google Gemini
  static Future<Map<String, dynamic>> _generateWithGemini(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildPrompt(financialData);

    // Use Gemini 1.5 Flash (fast and cost-effective)
    final url = Uri.parse(
      '$geminiBaseUrl/models/gemini-1.5-flash:generateContent?key=$apiKey',
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
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'];

      // Try to parse as JSON, fallback to text
      try {
        final insights = jsonDecode(content);
        return {'insights': insights};
      } catch (e) {
        return {'insights': content};
      }
    } else {
      throw Exception(
        'Gemini API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Generate insights using Groq
  static Future<Map<String, dynamic>> _generateWithGroq(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final prompt = _buildPrompt(financialData);

    print('Calling Groq API...');
    print('API Key length: ${apiKey.length}');
    print(
      'API Key starts with: ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...',
    );

    final response = await http.post(
      Uri.parse(groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile', // Updated to current model
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a financial advisor helping users with irregular incomes manage their money. Provide concise, actionable insights in JSON format.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    print('Groq response status: ${response.statusCode}');
    print('Groq response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Try to parse as JSON, fallback to text
      try {
        final insights = jsonDecode(content);
        return {'insights': insights};
      } catch (e) {
        return {'insights': content};
      }
    } else {
      final errorBody = response.body;
      String errorMessage = 'Groq API error: ${response.statusCode}';

      try {
        final errorData = jsonDecode(errorBody);
        if (errorData['error'] != null) {
          errorMessage += '\n${errorData['error']['message'] ?? errorBody}';
        } else {
          errorMessage += '\n$errorBody';
        }
      } catch (e) {
        errorMessage += '\n$errorBody';
      }

      throw Exception(errorMessage);
    }
  }

  /// Generate insights using custom API
  static Future<Map<String, dynamic>> _generateWithCustomApi(
    Map<String, dynamic> financialData,
    String apiKey,
  ) async {
    final customUrl = await getCustomApiUrl();
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
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Custom API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Build prompt for AI
  static String _buildPrompt(Map<String, dynamic> financialData) {
    final income = financialData['income'] as List;
    final expenses = financialData['expenses'] as List;
    final metadata = financialData['metadata'] as Map<String, dynamic>;
    final riskProfile = metadata['risk_profile'] as String? ?? 'unknown';

    final totalIncome = income.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] as num).toDouble()),
    );
    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] as num).toDouble()),
    );

    return '''
Analyze this financial data and provide actionable insights:

**Income Summary:**
- Total Income: ₹${totalIncome.toStringAsFixed(2)}
- Number of income transactions: ${income.length}
- Income sources: ${income.map((e) => e['source']).join(', ')}

**Expense Summary:**
- Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}
- Number of expense transactions: ${expenses.length}
- Expense categories: ${expenses.map((e) => e['category']).join(', ')}

**Financial Health:**
- Risk Profile: $riskProfile
- Net Balance: ₹${(totalIncome - totalExpenses).toStringAsFixed(2)}
- Forecast: ${metadata['previous_forecast']?['week']?['predicted_expenses'] ?? 'N/A'}

**User Profile:**
- Income Range: ${financialData['user_profile']?['income_range'] ?? 'Not specified'}
- Occupation: ${financialData['user_profile']?['occupation_category'] ?? 'Not specified'}

Provide:
1. Key insights about spending patterns
2. Recommendations for better financial management
3. Warnings if any (overspending, low balance, etc.)
4. Actionable next steps

Format your response as JSON with keys: "insights", "recommendations", "warnings", "next_steps"
''';
  }
}
