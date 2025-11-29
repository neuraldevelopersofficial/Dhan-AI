import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'home_screen.dart';
import 'advanced_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [const HomeScreen(), const AdvancedScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = Responsive.isSmallScreen(context);
              final horizontalPadding = Responsive.horizontalPadding(context);
              
              return Container(
                constraints: BoxConstraints(
                  minHeight: isSmallScreen ? 60 : 65,
                  maxHeight: isSmallScreen ? 70 : 75,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      context: context,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Basic',
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.insights_outlined,
                      selectedIcon: Icons.insights,
                      label: 'Advanced',
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = Responsive.isSmallScreen(context);
    final screenWidth = Responsive.screenWidth(context);
    final iconSize = Responsive.iconSize(context, isSmallScreen ? 20 : 24);
    final fontSize = Responsive.fontSize(context, isSmallScreen ? 10 : 12);
    
    // Use shorter labels on very small screens
    String displayLabel = label;
    if (screenWidth < 340) {
      if (label == 'Advanced') {
        displayLabel = 'Adv';
      } else if (label == 'Basic') {
        displayLabel = 'Basic';
      }
    }
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(context, 4),
            vertical: Responsive.spacing(context, 6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: iconSize,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
              SizedBox(height: Responsive.spacing(context, 2)),
              Flexible(
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
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
