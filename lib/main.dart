import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'theme/main_theme.dart';

void main() {
  runApp(const LendingApp());
}

class LendingApp extends StatelessWidget {
  const LendingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lending App',
      debugShowCheckedModeBanner: false,
      theme: MainTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
