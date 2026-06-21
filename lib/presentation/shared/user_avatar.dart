import 'package:flutter/material.dart';

/// Avatar circular com inicial do nome como fallback.
/// Se a [imageUrl] falha em carregar, automaticamente mostra a inicial.
class UserAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = (name != null && name!.isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : '?';

    final initialsChild = Text(
      initial,
      style: TextStyle(
        color: colors.onPrimaryContainer,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
      ),
    );

    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      // `foregroundImage` permite ter o initials como fallback automático
      // quando o NetworkImage falha em carregar (vs `backgroundImage` que
      // deixa o círculo vazio em caso de erro).
      foregroundImage: hasUrl ? NetworkImage(imageUrl!) : null,
      child: initialsChild,
    );
  }
}
