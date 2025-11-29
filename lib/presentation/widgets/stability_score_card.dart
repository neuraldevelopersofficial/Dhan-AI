import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../providers/dashboard_provider.dart';

class StabilityScoreCard extends ConsumerWidget {
  const StabilityScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stabilityAsync = ref.watch(stabilityProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

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
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 8)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shield,
                    size: Responsive.iconSize(context, 18),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: Responsive.spacing(context, 10)),
                Flexible(
                  child: Text(
                    'Stability',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, 16)),
            stabilityAsync.when(
              data: (score) {
                final stabilityData =
                    dashboardAsync.value?['stability'] as Map<String, dynamic>?;
                final safeDays = stabilityData?['safeDays'] as int? ?? 0;
                final isSmallScreen = Responsive.isSmallScreen(context);
                final size = Responsive.isSmallScreen(context) ? 90.0 : 110.0;
                
                return Column(
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: size,
                            height: size,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: isSmallScreen ? 6 : 8,
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getScoreColor(score),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, isSmallScreen ? 26 : 32),
                                  fontWeight: FontWeight.w700,
                                  color: _getScoreColor(score),
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                '$safeDays days safe',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 10),
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => SizedBox(
                width: Responsive.isSmallScreen(context) ? 90 : 100,
                height: Responsive.isSmallScreen(context) ? 90 : 100,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) =>
                  Text('Error: $error', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }
}
