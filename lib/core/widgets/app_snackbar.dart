import 'package:flutter/material.dart';
import '../design/app_tokens.dart';
import '../network/api_client.dart';

/// SnackBars padronizadas com identidade visual do app.
/// Use em vez de `ScaffoldMessenger.of(context).showSnackBar(...)` direto —
/// garante cores, ícones, formato e duração consistentes.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    required _Kind kind,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(kind.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _humanize(message),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: kind.background,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        duration: duration,
        elevation: 6,
      ),
    );
  }

  /// Erro: vermelho, ícone de alerta.
  static void error(BuildContext context, Object error,
      {Duration duration = const Duration(seconds: 5)}) {
    show(context,
        message: _messageFrom(error), kind: _Kind.error, duration: duration);
  }

  /// Sucesso: verde, check.
  static void success(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(context,
        message: message, kind: _Kind.success, duration: duration);
  }

  /// Info neutro: azul (cor primária).
  static void info(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(context, message: message, kind: _Kind.info, duration: duration);
  }

  /// Aviso: amarelo, exclamação.
  static void warning(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4)}) {
    show(context, message: message, kind: _Kind.warning, duration: duration);
  }

  /// Converte qualquer `Object` em mensagem amigável.
  /// Trata `ApiException`, mantém strings simples, e oculta detalhes técnicos.
  static String _messageFrom(Object error) {
    if (error is ApiException) return error.message;
    if (error is String) return _humanize(error);
    final raw = error.toString();
    return _humanize(raw);
  }

  /// Limpa prefixos técnicos comuns ("Exception: ", "ClientException: ", etc.)
  /// e troca jargões em inglês por mensagens em português.
  static String _humanize(String raw) {
    var msg = raw.trim();
    const prefixes = [
      'Exception:',
      'ClientException:',
      'SocketException:',
      'HttpException:',
      'FormatException:',
      'TimeoutException:',
      'HandshakeException:',
    ];
    for (final p in prefixes) {
      if (msg.startsWith(p)) msg = msg.substring(p.length).trim();
    }
    // Padrões frequentes em inglês
    final lower = msg.toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('failed to fetch') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('no address associated with hostname')) {
      return 'Sem conexão com o servidor. Verifique sua rede.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'O servidor demorou demais para responder. Tente novamente.';
    }
    if (lower.contains('certificate') || lower.contains('handshake')) {
      return 'Falha de segurança na conexão.';
    }
    if (lower.contains('413') || lower.contains('payload too large')) {
      return 'Arquivo muito grande.';
    }
    if (lower.contains('429') || lower.contains('too many requests')) {
      return 'Muitas tentativas. Aguarde um instante.';
    }
    if (lower.contains('500') || lower.contains('internal server')) {
      return 'Erro no servidor. Tente novamente em alguns minutos.';
    }
    return msg;
  }
}

enum _Kind { error, success, info, warning }

extension on _Kind {
  IconData get icon => switch (this) {
        _Kind.error => Icons.error_outline_rounded,
        _Kind.success => Icons.check_circle_outline_rounded,
        _Kind.info => Icons.info_outline_rounded,
        _Kind.warning => Icons.warning_amber_rounded,
      };

  Color get background => switch (this) {
        _Kind.error => AppTokens.error,
        _Kind.success => const Color(0xFF16A34A),
        _Kind.info => AppTokens.primary,
        _Kind.warning => const Color(0xFFD97706),
      };
}
