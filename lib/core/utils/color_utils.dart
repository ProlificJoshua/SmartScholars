import 'package:flutter/material.dart';

/// Utility class for color operations
class ColorUtils {
  /// Creates a color with the specified opacity
  /// This is a replacement for the deprecated withOpacity method
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Common opacity values
  static const double veryLight = 0.1;
  static const double light = 0.2;
  static const double medium = 0.3;
  static const double dark = 0.5;
  static const double veryDark = 0.8;
  
  /// Common colors used in the app
  static const Color gold = Color(0xFFFFD700);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);
}
