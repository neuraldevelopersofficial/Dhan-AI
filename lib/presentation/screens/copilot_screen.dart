import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/services/ai_copilot_service.dart';
import '../../data/services/database_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/user_profile_provider.dart';

class CopilotScreen extends ConsumerStatefulWidget {
  const CopilotScreen({super.key});

  @override
  ConsumerState<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends ConsumerState<CopilotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'assistant',
      'content':
          'Hi! I\'m your AI financial copilot. I can help you with:\n\n'
          '• Understanding your spending patterns\n'
          '• Saving money tips\n'
          '• Investment recommendations\n'
          '• Financial goal planning\n'
          '• What-if scenarios\n\n'
          'What would you like to know?',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Get financial data
      final repository = ref.read(transactionRepositoryProvider);
      final transactions = await repository.getAllTransactions();
      final forecast = await repository.calculateForecast();
      final stability = await repository.calculateStability();

      // Get user profile
      final phone = ref.read(currentUserPhoneProvider);
      final databaseService = DatabaseService();
      final userProfile = phone != null
          ? await databaseService.getUserByPhone(phone)
          : null;

      // Calculate financial summary
      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      final totalExpenses = transactions
          .where((t) => t.type == 'expense')
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      final financialSummary = {
        'balance': totalIncome - totalExpenses,
        'monthlyIncome': forecast['monthlyIncome'] ?? totalIncome,
        'monthlyExpenses': forecast['monthlyExpenses'] ?? totalExpenses,
        'stabilityScore': stability['score'] ?? 0,
      };

      // Get AI response
      final response = await AiCopilotService.chat(
        userMessage: message,
        recentTransactions: transactions.take(10).toList(),
        financialSummary: financialSummary,
        userProfile: userProfile,
        conversationHistory: _messages,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                'Sorry, I encountered an error. Please make sure your Groq API key is configured in Settings (⚙️).\n\nError: $e',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickQuestions() {
    final questions = [
      'How can I save more money?',
      'What are my spending patterns?',
      'Should I invest my savings?',
      'How much should I keep as emergency fund?',
      'What-if I save ₹2000 more per month?',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Questions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ...questions.map((question) => ListTile(
                  title: Text(question),
                  leading: const Icon(Icons.chat_bubble_outline),
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = question;
                    _sendMessage();
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Copilot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showQuickQuestions,
            tooltip: 'Quick Questions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: AppSpacing.md),
                        Text('AI is thinking...'),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything about your finances...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

