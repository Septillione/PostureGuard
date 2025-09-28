import 'package:flutter/material.dart';
import 'package:posture/app/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onPrimaryContainer: AppColors.backgroundProgressColor,

        onSecondaryContainer: AppColors.actionButtonColorActive,
        onSecondaryFixed: AppColors.actionButtonColorInactive,

        primaryFixed: AppColors.actionIconColorActive,
        onPrimaryFixed: AppColors.actionIconColorInactive
      ),
      scaffoldBackgroundColor: AppColors.backgroundColor,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.cardColor,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF1C1F22),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onPrimaryContainer: AppColors.backgroundProgressColorDark,
        
        onSecondaryContainer: AppColors.actionIconColorActive,
        onSecondaryFixed: AppColors.actionIconColorInactive,

        primaryFixed: AppColors.actionButtonColorActive,
        onPrimaryFixed: AppColors.actionButtonColorInactive,
      ),
      scaffoldBackgroundColor: const Color(0xFF111315),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF1C1F22),
      ),
    );
  }
}






