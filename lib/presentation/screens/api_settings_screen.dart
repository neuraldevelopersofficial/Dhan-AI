import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/ai_insights_service.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _openaiKeyController = TextEditingController();
  final _anthropicKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _groqKeyController = TextEditingController();
  final _customUrlController = TextEditingController();
  final _customKeyController = TextEditingController();

  ApiProvider _selectedProvider = ApiProvider.openai;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    _selectedProvider = await AiInsightsService.getSelectedProvider();

    _openaiKeyController.text =
        await AiInsightsService.getApiKey(ApiProvider.openai) ?? '';
    _anthropicKeyController.text =
        await AiInsightsService.getApiKey(ApiProvider.anthropic) ?? '';
    _geminiKeyController.text =
        await AiInsightsService.getApiKey(ApiProvider.gemini) ?? '';
    _groqKeyController.text =
        await AiInsightsService.getApiKey(ApiProvider.groq) ?? '';
    _customKeyController.text =
        await AiInsightsService.getApiKey(ApiProvider.custom) ?? '';
    _customUrlController.text = await AiInsightsService.getCustomApiUrl() ?? '';

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      // Save API keys
      if (_openaiKeyController.text.isNotEmpty) {
        await AiInsightsService.saveApiKey(
          ApiProvider.openai,
          _openaiKeyController.text.trim(),
        );
      }

      if (_anthropicKeyController.text.isNotEmpty) {
        await AiInsightsService.saveApiKey(
          ApiProvider.anthropic,
          _anthropicKeyController.text.trim(),
        );
      }

      if (_geminiKeyController.text.isNotEmpty) {
        await AiInsightsService.saveApiKey(
          ApiProvider.gemini,
          _geminiKeyController.text.trim(),
        );
      }

      if (_groqKeyController.text.isNotEmpty) {
        await AiInsightsService.saveApiKey(
          ApiProvider.groq,
          _groqKeyController.text.trim(),
        );
      }

      if (_customKeyController.text.isNotEmpty) {
        await AiInsightsService.saveApiKey(
          ApiProvider.custom,
          _customKeyController.text.trim(),
        );
      }

      if (_customUrlController.text.isNotEmpty) {
        await AiInsightsService.saveCustomApiUrl(
          _customUrlController.text.trim(),
        );
      }

      // Save selected provider
      await AiInsightsService.setSelectedProvider(_selectedProvider);

      // Verify the provider was saved correctly
      final savedProvider = await AiInsightsService.getSelectedProvider();
      print('Saved provider: ${savedProvider.name}');
      print('Selected provider: ${_selectedProvider.name}');

      // Verify API key for selected provider
      final savedKey = await AiInsightsService.getApiKey(_selectedProvider);
      if (savedKey == null || savedKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning: No API key saved for ${_getProviderName(_selectedProvider)}. '
                'Please enter an API key before using this provider.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings saved! Using ${_getProviderName(_selectedProvider)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _openaiKeyController.dispose();
    _anthropicKeyController.dispose();
    _geminiKeyController.dispose();
    _groqKeyController.dispose();
    _customUrlController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Provider Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select API Provider',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...ApiProvider.values.map(
                            (provider) => RadioListTile<ApiProvider>(
                              title: Text(_getProviderName(provider)),
                              subtitle: Text(_getProviderDescription(provider)),
                              value: provider,
                              groupValue: _selectedProvider,
                              onChanged: (value) {
                                setState(() {
                                  _selectedProvider = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // OpenAI Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OpenAI API Key',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _openaiKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'sk-...',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Get your API key from platform.openai.com',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Anthropic Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anthropic API Key',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _anthropicKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'sk-ant-...',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Get your API key from console.anthropic.com',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gemini Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Google Gemini API Key',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _geminiKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'AIzaSy...',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Get your API key from makersuite.google.com/app/apikey',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Groq Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Groq API Key',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _groqKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'gsk_...',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Get your API key from console.groq.com',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Custom API Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom API',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customUrlController,
                            decoration: const InputDecoration(
                              labelText: 'API URL',
                              hintText: 'https://api.example.com/insights',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customKeyController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'API Key',
                              hintText: 'Your API key',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
    );
  }

  String _getProviderName(ApiProvider provider) {
    switch (provider) {
      case ApiProvider.openai:
        return 'OpenAI (GPT-4)';
      case ApiProvider.anthropic:
        return 'Anthropic (Claude)';
      case ApiProvider.gemini:
        return 'Google Gemini';
      case ApiProvider.groq:
        return 'Groq (Llama)';
      case ApiProvider.custom:
        return 'Custom API';
    }
  }

  String _getProviderDescription(ApiProvider provider) {
    switch (provider) {
      case ApiProvider.openai:
        return 'Uses GPT-4o-mini for financial insights';
      case ApiProvider.anthropic:
        return 'Uses Claude 3 Haiku for financial insights';
      case ApiProvider.gemini:
        return 'Uses Gemini 1.5 Flash (fast & free tier available)';
      case ApiProvider.groq:
        return 'Uses Llama 3.1 70B (ultra-fast inference)';
      case ApiProvider.custom:
        return 'Use your own API endpoint';
    }
  }
}
