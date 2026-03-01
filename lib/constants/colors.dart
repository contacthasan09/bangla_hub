import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Bengali Flag Inspired)
  static const Color primaryGreen = Color(0xFF006A4E);
  static const Color primaryRed = Color(0xFFF42A41);
  
  // Secondary Colors
  static const Color secondaryGold = Color(0xFFFFD700);
  static const Color secondaryOrange = Color(0xFFFF6B35);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F8F8);
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color mediumGray = Color(0xFFBDBDBD);
  static const Color darkGray = Color(0xFF424242);
  static const Color black = Color(0xFF000000);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Accountants & Tax Preparers': Color(0xFF2196F3),
    'Legal Services': Color(0xFF9C27B0),
    'Healthcare Needs': Color(0xFF4CAF50),
    'Religious': Color(0xFFFF9800),
    'Restaurants & Grocery Stores': Color(0xFFF44336),
    'Real Estate Agents': Color(0xFF795548),
    'Plumbers, Electricians, Mechanics': Color(0xFF607D8B),
  };
}