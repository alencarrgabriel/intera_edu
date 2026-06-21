import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_endpoints.dart';

/// RF-30, RF-31, RF-32 — Tela de Configurações com ações LGPD.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;
  bool _deleting = false;
  bool _revoking = false;

  Future<void> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: confirmColor ?? AppTokens.primary),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }

  /// RF-30 — Solicita exportação e baixa o JSON no browser.
  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final res = await sl.apiClient.get(ApiEndpoints.myDataExport);
      final encoder = const JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(res);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pacote LGPD pronto'),
          content: SizedBox(
            width: 480,
            height: 360,
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: pretty));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copiado.')),
                );
              },
              child: const Text('Copiar'),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// RF-31 — Exclui conta.
  Future<void> _deleteAccount() async {
    setState(() => _deleting = true);
    try {
      await sl.apiClient.delete(ApiEndpoints.myProfile);
      if (!mounted) return;
      await context.read<AuthNotifier>().logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta marcada para exclusão.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  /// RF-32 — Revoga consentimento (e excluir conta em seguida).
  Future<void> _revokeConsent() async {
    setState(() => _revoking = true);
    try {
      final userId = context.read<AuthNotifier>().userId;
      await sl.apiClient.post('/auth/revoke-consent', body: {'user_id': userId});
      await sl.apiClient.delete(ApiEndpoints.myProfile);
      if (!mounted) return;
      await context.read<AuthNotifier>().logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppTokens.background,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('CONTA',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.onSurfaceVariant,
                )),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sair'),
            onTap: () async {
              await context.read<AuthNotifier>().logout();
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('PRIVACIDADE (LGPD)',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.onSurfaceVariant,
                )),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Exportar meus dados'),
            subtitle: const Text(
                'Gera um pacote JSON com perfil, posts, comentários e mensagens (RF-30).'),
            trailing: _exporting
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right_rounded),
            onTap: _exporting ? null : _exportData,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.cancel_outlined,
                color: AppTokens.error),
            title: const Text('Revogar consentimento',
                style: TextStyle(color: AppTokens.error)),
            subtitle: const Text(
                'Cancela o aceite dos termos e dispara exclusão da conta (RF-32).'),
            trailing: _revoking
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _revoking
                ? null
                : () => _confirm(
                      title: 'Revogar consentimento',
                      message:
                          'Isso retira seu consentimento aos termos. Sua conta será excluída e os dados anonimizados em até 30 dias. Tem certeza?',
                      confirmLabel: 'Revogar',
                      confirmColor: AppTokens.error,
                      onConfirm: _revokeConsent,
                    ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppTokens.error),
            title: const Text('Excluir minha conta',
                style: TextStyle(color: AppTokens.error)),
            subtitle: const Text(
                'Solicita exclusão; anonimização em até 30 dias (RF-31).'),
            trailing: _deleting
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _deleting
                ? null
                : () => _confirm(
                      title: 'Excluir conta',
                      message:
                          'Sua conta será marcada para exclusão. Em 30 dias os dados pessoais serão anonimizados. Continuar?',
                      confirmLabel: 'Excluir',
                      confirmColor: AppTokens.error,
                      onConfirm: _deleteAccount,
                    ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
