import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/config/server_config.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Tela de configuração de servidor — aparece automaticamente na primeira
/// abertura (quando `ServerConfig.needsSetup`) e também é acessível pelo
/// drawer em "Servidor". Permite trocar de host sem reinstalar o APK.
class ServerSetupScreen extends StatefulWidget {
  /// `true` quando vem do primeiro boot (sem CTA pra voltar).
  final bool isInitialSetup;
  const ServerSetupScreen({super.key, this.isInitialSetup = false});

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  bool _tested = false;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = ServerConfig.instance.customHost;
    _ctrl.addListener(() => setState(() => _tested = false));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final value = _ctrl.text.trim();
    if (value.isEmpty) {
      AppSnackbar.warning(context, 'Digite o endereço primeiro.');
      return;
    }
    setState(() => _busy = true);
    final err = await ServerConfig.instance.testHost(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _tested = true;
      _testOk = err == null;
    });
    if (err == null) {
      AppSnackbar.success(context, 'Conexão OK!');
    } else {
      AppSnackbar.error(context, err);
    }
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    if (value.isEmpty) {
      AppSnackbar.warning(context, 'Digite o endereço primeiro.');
      return;
    }
    setState(() => _busy = true);
    await ServerConfig.instance.setHost(value);
    // Desconecta socket pra forçar reconexão no host novo
    if (mounted) {
      try {
        await context.read<AuthNotifier>().logout();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _busy = false);
    AppSnackbar.success(context, 'Servidor salvo. Faça login novamente.');
    if (widget.isInitialSetup) {
      context.go(AppRoutes.welcome);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: widget.isInitialSetup
          ? null
          : AppBar(
              backgroundColor: AppTokens.background,
              elevation: 0,
              title: const Text('Configurar servidor',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isInitialSetup) ...[
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.dns_outlined,
                      size: 36, color: AppTokens.onPrimaryContainer),
                ),
                const SizedBox(height: 24),
                Text(
                  'Conectar ao InteraEdu',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aponte o app pro servidor da sua instituição ou da rede de testes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTokens.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Endereço atual: ${ServerConfig.instance.customHost.isEmpty ? "padrão da build" : ServerConfig.instance.customHost}',
                  style: TextStyle(
                      color: AppTokens.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Endereço do servidor',
                  hintText: '192.168.1.9  ou  http://exemplo.edu.br',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  filled: true,
                  fillColor: AppTokens.surfaceContainerLowest,
                  suffixIcon: _tested
                      ? Icon(
                          _testOk
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: _testOk
                              ? const Color(0xFF16A34A)
                              : AppTokens.error,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Pode ser um IP da rede local (Wi-Fi) ou uma URL pública. '
                  'A porta padrão 3000 do gateway é adicionada automaticamente.',
                  style: TextStyle(
                    color: AppTokens.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _test,
                      icon: const Icon(Icons.wifi_protected_setup_rounded),
                      label: const Text('Testar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: const Text('Salvar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!widget.isInitialSetup &&
                  ServerConfig.instance.customHost.isNotEmpty)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          await ServerConfig.instance.clear();
                          if (!mounted) return;
                          AppSnackbar.info(
                              context, 'Servidor restaurado pro padrão.');
                          context.pop();
                        },
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Voltar ao padrão da build'),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'INTERAEDU · LGPD',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: AppTokens.outlineVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
