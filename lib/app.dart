import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_notifier.dart';
import 'core/theme/app_theme.dart';
import 'presentation/onboarding/screens/welcome_screen.dart';
import 'presentation/main_screen.dart';

class InteraEduApp extends StatelessWidget {
  const InteraEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthNotifier()..checkSession(),
      child: MaterialApp(
        title: 'InteraEdu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const _AuthWrapper(),
      ),
    );
  }
}

/// Widget que observa o AuthNotifier e redireciona para a tela correta.
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthNotifier>().status;

    return switch (authStatus) {
      AuthStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.authenticated => const MainScreen(),
      AuthStatus.unauthenticated => const WelcomeScreen(),
    };
  }
}
