import 'package:flutter/material.dart';

class MainColors {
  static const MaterialColor primarySwatch = Colors.blueGrey;
  static const Color background = Color(0xFFF4F6F8);
  static const Color textPrimary = Colors.black87;
  
  static const Color bottomNavSelected = Color(0xFF263238); // Colors.blueGrey[900]
  static const Color bottomNavUnselected = Color(0xFF546E7A); // Colors.blueGrey[600]
}

class MainTextStyles {
  // General text styles for main layout if needed in future
}

class MainTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: MainColors.primarySwatch,
      scaffoldBackgroundColor: MainColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: MainColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}
