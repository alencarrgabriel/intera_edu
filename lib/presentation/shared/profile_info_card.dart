import 'package:flutter/material.dart';

/// Card com informações acadêmicas (curso e período) do perfil.
/// Extraído para evitar duplicação entre my_profile_screen e user_profile_screen.
class ProfileInfoCard extends StatelessWidget {
  final String? course;
  final int? period;

  const ProfileInfoCard({
    super.key,
    required this.course,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (course == null && period == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.menu_book_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Curso: ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Expanded(child: Text(course!)),
                ]),
              ),
            if (period != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('$period\u00ba período'),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
