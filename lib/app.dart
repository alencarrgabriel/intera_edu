import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/login_screen.dart';

class InteraEduApp extends StatelessWidget {
  const InteraEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteraEdu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}
