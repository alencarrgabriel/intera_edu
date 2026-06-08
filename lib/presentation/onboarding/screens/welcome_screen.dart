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
      body: Stack(
        children: [
          const _BackgroundOrnaments(),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo ──────────────────────────────────────────────
                  const _LogoBadge(),
                  const SizedBox(height: 40),

                  // ── Brand ─────────────────────────────────────────────
                  Text(
                    'InteraEdu',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTokens.primaryDim,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CURADORIA DIGITAL',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTokens.onSurfaceVariant,
                          letterSpacing: 3.5,
                          fontWeight: FontWeight.w500,
                        ),
                  ),

                  const Spacer(flex: 3),

                  // ── CTAs ──────────────────────────────────────────────
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

                  // ── LGPD ──────────────────────────────────────────────
                  Text(
                    'Seus dados estão protegidos sob a LGPD.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppTokens.outlineVariant,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTokens.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTokens.radiusXl + 4),
              border: Border.all(
                color: AppTokens.outlineVariant.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTokens.onSurface.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 44,
              color: AppTokens.primary,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTokens.primary,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.primary.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.hub,
                color: AppTokens.onPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrnaments extends StatelessWidget {
  const _BackgroundOrnaments();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.primaryContainer.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            right: -180,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.secondaryContainer.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
