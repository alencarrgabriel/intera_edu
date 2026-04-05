import 'package:flutter/material.dart';

/// Avatar circular com inicial do nome como fallback.
/// Centraliza o padrão `CircleAvatar + initials` duplicado em múltiplas telas.
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

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      backgroundImage:
          (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(
              initial,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
