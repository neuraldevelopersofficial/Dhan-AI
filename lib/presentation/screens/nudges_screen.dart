import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/models/nudge_model.dart';
import '../providers/dashboard_provider.dart';

class NudgesScreen extends ConsumerWidget {
  const NudgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nudgesAsync = ref.watch(nudgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nudges & Recommendations'),
      ),
      body: nudgesAsync.when(
        data: (nudges) {
          if (nudges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 64,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No nudges available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Check back later for recommendations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nudgesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: nudges.length,
              itemBuilder: (context, index) {
                final nudge = nudges[index];
                return _NudgeCard(
                  nudge: nudge,
                  onApply: () => _handleApplyNudge(context, ref, nudge),
                  onSuggestAlternative: () => _handleSuggestAlternative(context, nudge),
                  onDismiss: () => _handleDismiss(context, ref, nudge),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading nudges: $error'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(nudgesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleApplyNudge(BuildContext context, WidgetRef ref, Nudge nudge) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Nudge?'),
        content: Text('Do you want to apply: ${nudge.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulate applying the nudge
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${nudge.title} applied successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Refresh nudges
              ref.invalidate(nudgesProvider);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _handleSuggestAlternative(BuildContext context, Nudge nudge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggest Alternative'),
        content: Text(
          'We will analyze alternatives for: ${nudge.title}\n\n'
          'This feature will be available in a future update.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleDismiss(BuildContext context, WidgetRef ref, Nudge nudge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Nudge?'),
        content: Text('This nudge will be removed: ${nudge.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nudge dismissed')),
              );
              // In real app, would call API to dismiss
              // For now, just refresh to simulate removal
              ref.invalidate(nudgesProvider);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final Nudge nudge;
  final VoidCallback onApply;
  final VoidCallback onSuggestAlternative;
  final VoidCallback onDismiss;

  const _NudgeCard({
    required this.nudge,
    required this.onApply,
    required this.onSuggestAlternative,
    required this.onDismiss,
  });

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(nudge.riskLevel);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getRiskIcon(nudge.riskLevel),
                    color: riskColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    nudge.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              nudge.reason,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    nudge.impact,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSuggestAlternative,
                    child: const Text('Suggest Alternative'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: riskColor,
                    ),
                    child: const Text('Apply Plan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

