import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/gradient_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),

              // ── Ícone com gradiente ──────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                  boxShadow: AppTokens.primaryShadow,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 52,
                  color: AppTokens.onPrimary,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Bem-vindo ao\nInteraEdu',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTokens.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quebre as barreiras institucionais.\nColabore entre universidades.\nCresça junto.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTokens.onSurfaceVariant,
                      height: 1.6,
                    ),
              ),

              const Spacer(),

              // ── CTAs ─────────────────────────────────────────────────────
              GradientButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text('Começar'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Já tenho uma conta'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
