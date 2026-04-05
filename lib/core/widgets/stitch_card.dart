import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

/// Card Stitch: sem elevation Material, usa ambient shadow e corner radius lg.
class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppTokens.surfaceContainerLowest,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: AppTokens.ambientShadow,
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}
