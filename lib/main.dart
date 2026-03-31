import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'screens/simple_auth_screen.dart';
import 'theme/main_theme.dart';

/// Entry point of the Lending App
/// Manages authentication state and routes to appropriate screens
void main() {
  runApp(const LendingApp());
}

/// Root widget of the application
/// Handles authentication state management and theme configuration
class LendingApp extends StatefulWidget {
  const LendingApp({super.key});

  @override
  State<LendingApp> createState() => _LendingAppState();
}

/// State management for LendingApp
class _LendingAppState extends State<LendingApp> {
  bool _isAuthenticated = false;

  // === AUTHENTICATION HANDLING ===

  /// Updates authentication state and triggers UI rebuild
  void _onAuthenticated() {
    setState(() => _isAuthenticated = true);
  }

  // === UI BUILDING ===

  /// Builds the app widget based on authentication state
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lending App',
      debugShowCheckedModeBanner: false, // Clean production build
      theme: MainTheme.lightTheme,
      home: _isAuthenticated
          ? const MainLayout() // Authenticated users see main app
          : SimpleAuthScreen(
              onAuthenticated: _onAuthenticated), // Unauthenticated see login
    );
  }

  // === END OF UI BUILDING ===
}
