import 'package:flutter/material.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/stitch_skeleton.dart';

/// Placeholder shimmer para o cabeçalho da tela de perfil.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return StitchSkeleton(
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Header com gradiente placeholder ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            color: AppTokens.surfaceContainerLow,
            child: Column(
              children: [
                // Avatar
                const SkeletonBox(
                    height: 96, width: 96, shape: BoxShape.circle),
                const SizedBox(height: 14),
                // Nome
                const SkeletonBox(height: 18, width: 160),
                const SizedBox(height: 8),
                // Instituição
                const SkeletonBox(height: 13, width: 200),
                const SizedBox(height: 12),
                // Chip de privacidade
                Container(
                  width: 120,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Card de info acadêmica ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 13, width: 200),
                  SizedBox(height: 10),
                  SkeletonBox(height: 13, width: 140),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Seção Bio ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 60),
                SizedBox(height: 8),
                SkeletonBox(height: 13),
                SizedBox(height: 6),
                SkeletonBox(height: 13, width: 220),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
