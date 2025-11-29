import 'package:flutter/material.dart';

class Responsive {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  static bool isSmallScreen(BuildContext context) => screenWidth(context) < 360;
  static bool isMediumScreen(BuildContext context) => screenWidth(context) >= 360 && screenWidth(context) < 600;
  static bool isLargeScreen(BuildContext context) => screenWidth(context) >= 600;
  
  // Responsive padding
  static double horizontalPadding(BuildContext context) {
    if (isSmallScreen(context)) return 16;
    if (isMediumScreen(context)) return 20;
    return 24;
  }
  
  static double verticalPadding(BuildContext context) {
    if (isSmallScreen(context)) return 12;
    if (isMediumScreen(context)) return 16;
    return 20;
  }
  
  // Responsive font sizes
  static double fontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) return baseSize * 0.9;
    return baseSize;
  }
  
  // Responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    if (isSmallScreen(context)) return baseSpacing * 0.75;
    return baseSpacing;
  }
  
  // Responsive card padding
  static double cardPadding(BuildContext context) {
    if (isSmallScreen(context)) return 12;
    if (isMediumScreen(context)) return 16;
    return 20;
  }
  
  // Responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) return baseSize * 0.85;
    return baseSize;
  }
}

