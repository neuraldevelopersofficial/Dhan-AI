import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/ai_copilot_service.dart';
import '../../data/services/database_service.dart';
import '../providers/webhook_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/stock_recommendations_widget.dart';

class AdvancedScreen extends ConsumerStatefulWidget {
  const AdvancedScreen({super.key});

  @override
  ConsumerState<AdvancedScreen> createState() => _AdvancedScreenState();
}

class _AdvancedScreenState extends ConsumerState<AdvancedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Advanced',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API Settings',
            onPressed: () => context.push('/api-settings'),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Get AI Insights',
            onPressed: () => _sendToWebhook(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: Responsive.verticalPadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advanced Analytics Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Advanced Analytics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detailed insights and analytics coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Investment Insights - Stock Recommendations
            const StockRecommendationsWidget(),
            const SizedBox(height: AppSpacing.md),

            // Budget Planning
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Budget Planning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create and manage budgets for different categories',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showWhatIfSimulation(context),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('What-If Simulation'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export & Reports
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.file_download_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Export & Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Export your transaction data and generate detailed reports',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToWebhook(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ref.read(sendCurrentUserDataProvider.future);
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null
                  ? 'Data sent successfully! Insights: ${result['insights'] ?? 'No insights'}'
                  : 'Data sent successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        // Extract error message
        String errorMessage = e.toString();

        // Check for specific error types
        if (errorMessage.contains('No user logged in')) {
          errorMessage = 'Please login first before sending data.';
        } else if (errorMessage.contains('API key not configured') ||
            errorMessage.contains('configure API keys') ||
            errorMessage.contains('configure it in Settings')) {
          errorMessage =
              'API key not configured. Please go to Settings (⚙️) to add your API key.';
        } else if (errorMessage.contains('Failed to generate AI insights')) {
          // This is an AI service error - clean it up for better readability
          errorMessage = errorMessage.replaceAll('Exception: ', '');
          errorMessage = errorMessage.replaceAll(
            'Failed to send data to webhook: ',
            '',
          );
          errorMessage = errorMessage.replaceAll(
            'Error sending data to webhook: ',
            '',
          );
          errorMessage = errorMessage.replaceAll(
            'Failed to generate AI insights: ',
            '',
          );

          // Extract the actual API error if it's nested
          if (errorMessage.contains('Groq API error') ||
              errorMessage.contains('Gemini API error') ||
              errorMessage.contains('OpenAI API error') ||
              errorMessage.contains('Anthropic API error')) {
            // Find the actual API error message
            final apiErrorMatch = RegExp(
              r'(Groq|Gemini|OpenAI|Anthropic) API error: \d+\s*(.*?)(?:\n\n|$)',
            ).firstMatch(errorMessage);
            if (apiErrorMatch != null) {
              errorMessage =
                  '${apiErrorMatch.group(1)} API Error: ${apiErrorMatch.group(2)?.trim() ?? ''}';
            }
          }
        } else if (errorMessage.contains('Groq API error') ||
            errorMessage.contains('Gemini API error') ||
            errorMessage.contains('OpenAI API error') ||
            errorMessage.contains('Anthropic API error')) {
          // AI API specific errors - show them directly
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(child: Text(e.toString())),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showWhatIfSimulation(BuildContext context) async {
    final scenarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What-If Simulation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a scenario to simulate:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: scenarioController,
              decoration: const InputDecoration(
                hintText: 'e.g., What if I save ₹2000 more per month?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (scenarioController.text.isEmpty) return;

              Navigator.pop(context);
              await _runSimulation(context, scenarioController.text);
            },
            child: const Text('Simulate'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSimulation(BuildContext context, String scenario) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get financial data
      final repository = ref.read(transactionRepositoryProvider);
      final transactions = await repository.getAllTransactions();
      final forecast = await repository.calculateForecast();

      // Get user profile
      final phone = ref.read(currentUserPhoneProvider);
      final databaseService = DatabaseService();
      final userProfile = phone != null
          ? await databaseService.getUserByPhone(phone)
          : null;

      final simulation = await AiCopilotService.whatIfSimulation(
        scenario: scenario,
        currentTransactions: transactions,
        currentForecast: forecast,
        userProfile: userProfile,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Simulation Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scenario: $scenario',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (simulation['projectedBalance'] != null)
                    Text(
                      'Projected Balance: ₹${(simulation['projectedBalance'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (simulation['monthlyChange'] != null)
                    Text(
                      'Monthly Change: ₹${(simulation['monthlyChange'] as num).toStringAsFixed(2)}',
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (simulation['impact'] != null)
                    Text('Impact: ${simulation['impact']}'),
                  const SizedBox(height: AppSpacing.sm),
                  if (simulation['recommendation'] != null)
                    Text('Recommendation: ${simulation['recommendation']}'),
                  const SizedBox(height: AppSpacing.sm),
                  if (simulation['timeline'] != null)
                    Text('Timeline: ${simulation['timeline']}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
