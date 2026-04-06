import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design/app_tokens.dart';

/// Wrapper de shimmer com as cores do Stitch.
///
/// Use [StitchSkeleton] para envolver qualquer widget "placeholder" que
/// represente a estrutura da UI durante o carregamento.
///
/// ```dart
/// StitchSkeleton(
///   child: Container(
///     height: 16,
///     width: double.infinity,
///     decoration: BoxDecoration(
///       color: AppTokens.surfaceContainerLow,
///       borderRadius: BorderRadius.circular(AppTokens.radiusSm),
///     ),
///   ),
/// )
/// ```
class StitchSkeleton extends StatelessWidget {
  const StitchSkeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTokens.surfaceContainerLow,
      highlightColor: AppTokens.surfaceContainerHigh,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Bloco de skeleton genérico (linha, retângulo, círculo).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double? borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLow,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius ?? AppTokens.radiusSm),
      ),
    );
  }
}
