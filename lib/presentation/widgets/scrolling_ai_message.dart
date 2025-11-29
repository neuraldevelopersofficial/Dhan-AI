import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/ai_message_provider.dart';

/// A scrolling text widget that displays AI-generated motivational messages
/// Similar to news ticker, scrolling from right to left
class ScrollingAiMessage extends ConsumerStatefulWidget {
  const ScrollingAiMessage({super.key});

  @override
  ConsumerState<ScrollingAiMessage> createState() => _ScrollingAiMessageState();
}

class _ScrollingAiMessageState extends ConsumerState<ScrollingAiMessage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (_isScrolling) return;
    _isScrolling = true;

    // Auto-scroll messages from right to left continuously
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_scrollController.hasClients) {
        _isScrolling = false;
        return;
      }

      _scrollOnce();
    });
  }

  void _scrollOnce() {
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 25),
      curve: Curves.linear,
    ).then((_) {
      // When scroll completes, reset to start for seamless loop
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
        // Continue scrolling after a brief pause
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _scrollOnce();
        });
      } else {
        _isScrolling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(aiMessagesProvider);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Getting your financial insights...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            );
          }

          // Start scrolling after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startScrolling();
          });

          return Row(
            children: [
              // AI Icon
              Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              // Scrolling messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: messages.length * 2, // Duplicate for seamless loop
                  itemBuilder: (context, index) {
                    final message = messages[index % messages.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          // Separator
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Analyzing your transactions...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'AI insights unavailable. Check API settings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
