import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'screens/simple_auth_screen.dart';
import 'theme/main_theme.dart';

void main() {
  runApp(const LendingApp());
}

class LendingApp extends StatefulWidget {
  const LendingApp({super.key});

  @override
  State<LendingApp> createState() => _LendingAppState();
}

class _LendingAppState extends State<LendingApp> {
  bool _isAuthenticated = false;

  void _onAuthenticated() {
    setState(() => _isAuthenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lending App',
      debugShowCheckedModeBanner: false,
      theme: MainTheme.lightTheme,
      home: _isAuthenticated
          ? const MainLayout()
          : SimpleAuthScreen(onAuthenticated: _onAuthenticated),
    );
  }
}
