import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../ui/theme/careflow_ui_theme.dart';

class CareFlowApp extends StatelessWidget {
  const CareFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareFlow',
      theme: CareFlowUITheme.light(),
      home: const LoginScreen(),
    );
  }
}
