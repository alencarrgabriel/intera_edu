import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

/// Botão CTA Stitch com gradiente primary→primary-dim.
///
/// Internamente usa [FilledButton] para que `find.byType(FilledButton)` nos
/// testes continue funcionando.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52.0,
    this.width = double.infinity,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppTokens.primaryGradient : null,
          color: enabled
              ? null
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          boxShadow: enabled ? AppTokens.primaryShadow : null,
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppTokens.onPrimary,
            disabledForegroundColor:
                AppTokens.onSurface.withValues(alpha: 0.38),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
