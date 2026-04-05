import 'package:flutter/material.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/stitch_card.dart';
import '../../../core/widgets/stitch_skeleton.dart';

/// Placeholder shimmer que replica visualmente a estrutura de um [PostCard].
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return StitchSkeleton(
      child: StitchCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  const SkeletonBox(
                      height: 40, width: 40, shape: BoxShape.circle),
                  const SizedBox(width: 10),
                  // Nome + curso
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(height: 13, width: 140),
                        SizedBox(height: 5),
                        SkeletonBox(height: 11, width: 100),
                      ],
                    ),
                  ),
                  // Badge de tempo
                  const SkeletonBox(height: 11, width: 40),
                ],
              ),
            ),

            // ── Conteúdo (3 linhas) ─────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(height: 13, width: 180),
                  SizedBox(height: 14),
                ],
              ),
            ),

            // ── Separador ───────────────────────────────────────────────
            Container(height: 1, color: AppTokens.surfaceContainerLow),

            // ── Barra de ações ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
                  SkeletonBox(height: 12, width: 60),
                  SizedBox(width: 24),
                  SkeletonBox(height: 12, width: 72),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
