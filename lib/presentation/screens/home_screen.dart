import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stability_score_card.dart';
import '../widgets/forecast_chart.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/scrolling_ai_message.dart';
import 'add_transaction_screen.dart';
import '../../data/services/sms_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasAutoRequested = false;

  @override
  void initState() {
    super.initState();
    // Auto-request permission after UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRequestPermission();
    });
  }

  Future<void> _autoRequestPermission() async {
    if (_hasAutoRequested) return;
    _hasAutoRequested = true;

    final smsService = ref.read(smsServiceProvider);
    final hasPermission = await smsService.hasPermission();

    if (!hasPermission && mounted) {
      // Auto-request permission
      final granted = await smsService.requestPermission();
      if (granted && mounted) {
        // Permission granted, automatically fetch SMS
        await _fetchSmsTransactions(context, ref, smsService);
      }
    } else if (hasPermission && mounted) {
      // Permission already granted, check if we have transactions
      final transactions = await ref.read(transactionsProvider.future);
      if (transactions.isEmpty) {
        // Auto-fetch if no transactions exist
        await _fetchSmsTransactions(context, ref, smsService);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final nudgesAsync = ref.watch(nudgesProvider);
    final smsService = ref.read(smsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Dhan-AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          // SMS fetch button (only show if permission is granted)
          FutureBuilder<bool>(
            future: smsService.hasPermission(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.sms),
                  tooltip: 'Fetch SMS Transactions',
                  onPressed: () =>
                      _fetchSmsTransactions(context, ref, smsService),
                );
              }
              // Don't show button if permission not granted (will auto-request)
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              context.push('/profile');
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dhan-AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your money co-pilot',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              title: 'Home',
              onTap: () => Navigator.pop(context),
              isSelected: true,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.recommend_outlined,
              selectedIcon: Icons.recommend,
              title: 'Nudges',
              onTap: () {
                Navigator.pop(context);
                context.push('/nudges');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.account_balance_outlined,
              selectedIcon: Icons.account_balance,
              title: 'Goals & Vaults',
              onTap: () {
                Navigator.pop(context);
                context.push('/vaults');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.trending_up_outlined,
              selectedIcon: Icons.trending_up,
              title: 'Investment Coach',
              onTap: () {
                Navigator.pop(context);
                context.push('/invest');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat,
              title: 'AI Copilot',
              onTap: () {
                Navigator.pop(context);
                context.push('/copilot');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.emoji_events_outlined,
              selectedIcon: Icons.emoji_events,
              title: 'Rewards',
              onTap: () {
                Navigator.pop(context);
                context.push('/rewards');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(goalsProvider);
          ref.invalidate(nudgesProvider);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = Responsive.isSmallScreen(context);
            final horizontalPadding = Responsive.horizontalPadding(context);
            
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: Responsive.verticalPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrolling AI Messages (like news ticker)
                  const ScrollingAiMessage(),
                  SizedBox(height: Responsive.spacing(context, 20)),
                  
                  // Stability Score Card and Forecast Chart - responsive layout
                  isSmallScreen
                      ? Column(
                          children: [
                            const StabilityScoreCard(),
                            SizedBox(height: Responsive.spacing(context, 12)),
                            const ForecastChart(),
                          ],
                        )
                      : Row(
                          children: [
                            const Expanded(child: StabilityScoreCard()),
                            SizedBox(width: Responsive.spacing(context, 12)),
                            const Expanded(child: ForecastChart()),
                          ],
                        ),
                  SizedBox(height: Responsive.spacing(context, 20)),

                  // Quick Actions
                  _buildQuickActions(context),
                  SizedBox(height: Responsive.spacing(context, 20)),

              // Active Nudges Carousel
              nudgesAsync.when(
                data: (nudges) {
                  if (nudges.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Active Nudges',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 18),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/nudges'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.spacing(context, 12),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.fontSize(context, 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, 12)),
                      SizedBox(
                        height: Responsive.isSmallScreen(context) ? 160 : 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: nudges.take(3).length,
                          itemBuilder: (context, index) {
                            final nudge = nudges[index];
                            return _buildNudgeCard(context, nudge);
                          },
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, 16)),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

                  // Goals Summary
                  goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Goals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/vaults'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...goals
                          .take(2)
                          .map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _buildGoalCard(context, goal),
                            ),
                          ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

                  // Recent Transactions
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, 12)),
                  transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fetch transactions from SMS or add manually',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _fetchSmsTransactions(
                                    context,
                                    ref,
                                    smsService,
                                  ),
                                  icon: const Icon(Icons.sms),
                                  label: const Text('Fetch from SMS'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showAddTransaction(context, 'income'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Manually'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                  }
                  return Container(
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
                      children: [
                        ...transactions.take(5).map((transaction) {
                          return TransactionListItem(transaction: transaction);
                        }).toList(),
                        if (transactions.length > 5)
                          ListTile(
                            title: const Text('View All Transactions'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              context.push('/transactions');
                            },
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Error loading transactions: $error'),
                  ),
                ),
                  ),
                  SizedBox(height: Responsive.spacing(context, 16)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isSmallScreen = Responsive.isSmallScreen(context);
    final cardPadding = Responsive.cardPadding(context);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _buildActionButton(
              context,
              icon: Icons.add_circle_outline,
              label: 'Income',
              color: AppColors.success,
              onTap: () => _showAddTransaction(context, 'income'),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            child: _buildActionButton(
              context,
              icon: Icons.remove_circle_outline,
              label: 'Expense',
              color: AppColors.danger,
              onTap: () => _showAddTransaction(context, 'expense'),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            child: _buildActionButton(
              context,
              icon: Icons.account_balance_outlined,
              label: 'Vault',
              color: AppColors.primary,
              onTap: () {
                // Navigate to vaults
              },
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            child: _buildActionButton(
              context,
              icon: Icons.chat_bubble_outline,
              label: 'AI',
              color: AppColors.warning,
              onTap: () {
                context.push('/copilot');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = Responsive.isSmallScreen(context);
    final iconSize = Responsive.iconSize(context, isSmallScreen ? 44 : 52);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, 8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: Responsive.iconSize(context, isSmallScreen ? 22 : 26),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, 6)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, isSmallScreen ? 10 : 12),
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNudgeCard(BuildContext context, nudge) {
    final riskColor = nudge.riskLevel == 'high'
        ? AppColors.danger
        : AppColors.primary;
    final isSmallScreen = Responsive.isSmallScreen(context);
    final cardWidth = Responsive.screenWidth(context) * (isSmallScreen ? 0.85 : 0.75);
    
    return Container(
      width: cardWidth.clamp(260.0, 320.0),
      margin: EdgeInsets.only(right: Responsive.spacing(context, 12)),
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
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 6)),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: Responsive.iconSize(context, 18),
                    color: riskColor,
                  ),
                ),
                SizedBox(width: Responsive.spacing(context, 10)),
                Expanded(
                  child: Text(
                    nudge.title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, 12)),
            Flexible(
              child: Text(
                nudge.reason,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: riskColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: goal.progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${goal.current.toStringAsFixed(0)} / ₹${goal.target.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(goal.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(initialType: type),
    );
  }

  Future<void> _fetchSmsTransactions(
    BuildContext context,
    WidgetRef ref,
    SmsService smsService,
  ) async {
    if (!await smsService.hasPermission()) {
      // Auto-request permission if not granted
      final granted = await smsService.requestPermission();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to fetch transactions.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Fetching SMS transactions...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }

    try {
      final newTransactions = await smsService.fetchSmsTransactions();

      // Wait a bit to ensure Hive has saved the data
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate providers to refresh UI
      ref.invalidate(transactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(stabilityProvider);
      ref.invalidate(forecastProvider);

      // Force a rebuild by waiting for providers to refresh
      await Future.delayed(const Duration(milliseconds: 300));

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newTransactions.isEmpty
                  ? 'No new transactions found in SMS. Make sure you have UPI/banking SMS in your inbox.'
                  : 'Found ${newTransactions.length} new transaction(s)!',
            ),
            backgroundColor: newTransactions.isEmpty
                ? Colors.orange
                : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching SMS: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
