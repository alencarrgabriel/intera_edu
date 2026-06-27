import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';

/// Tela de transição: recebe um @handle, resolve para user_id via API
/// e navega para a tela de perfil correspondente. Usada quando um link
/// `@usuario` é tocado em posts/comentários.
class HandleRedirectScreen extends StatefulWidget {
  final String handle;
  const HandleRedirectScreen({super.key, required this.handle});

  @override
  State<HandleRedirectScreen> createState() => _HandleRedirectScreenState();
}

class _HandleRedirectScreenState extends State<HandleRedirectScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    try {
      final user = await sl.profileRepo.getUserByHandle(widget.handle);
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.userProfile(user.id),
        extra: user.fullName,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Usuário @${widget.handle} não encontrado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTokens.background,
        title: Text('@${widget.handle}'),
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTokens.onSurfaceVariant),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
