import 'package:flutter/material.dart';

/// Formata uma data em tempo relativo ("há 5 min", "há 2 h", "12/03/2026").
/// Consolida a lógica duplicada em post_card.dart e comments_sheet.dart.
class RelativeTimeText extends StatelessWidget {
  final DateTime? date;
  final TextStyle? style;
  final bool compact;

  const RelativeTimeText({
    super.key,
    required this.date,
    this.style,
    this.compact = false,
  });

  static String format(DateTime? date, {bool compact = false}) {
    if (date == null) return '';
    try {
      final dt = date.toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return compact ? 'agora' : 'agora mesmo';
      if (diff.inMinutes < 60) {
        return compact ? '${diff.inMinutes} min' : 'há ${diff.inMinutes} min';
      }
      if (diff.inHours < 24) {
        return compact ? '${diff.inHours} h' : 'há ${diff.inHours} h';
      }
      if (diff.inDays < 7) {
        return compact ? '${diff.inDays} d' : 'há ${diff.inDays} d';
      }
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      format(date, compact: compact),
      style: style ?? Theme.of(context).textTheme.labelSmall,
    );
  }
}
