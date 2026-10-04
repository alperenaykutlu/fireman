import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppConstants.bgDark,
      cardColor: AppConstants.bgCard,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.fireOrange,
        secondary: AppConstants.waterBlue,
        surface: AppConstants.bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.bgCard,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppConstants.bgCard,
        selectedItemColor: AppConstants.fireOrange,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
