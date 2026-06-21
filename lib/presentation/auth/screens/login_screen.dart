import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/auth/google_sign_in_web.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/gradient_button.dart';

/// Quando `false`, a tela de login esconde o bloco "OU / Continuar com Google".
/// Coloque em `true` depois de configurar o Client ID em `web/index.html` e
/// a env `GOOGLE_CLIENT_ID` no auth-service.
const bool _showGoogleSignIn = false;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await context.read<AuthNotifier>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login com Google só disponível na versão web.'),
        ),
      );
      return;
    }
    setState(() => _googleLoading = true);
    try {
      final idToken = await fetchGoogleIdToken();
      if (!mounted) return;
      await context.read<AuthNotifier>().loginWithGoogleIdToken(idToken);
    } on GoogleSignInCancelled {
      // Usuário fechou o popup — silencioso
    } on GoogleSignInNotConfigured catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 40),
                    _LoginCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: _isLoading,
                      googleLoading: _googleLoading,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSubmit: _handleLogin,
                      onGoogleSignIn: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 24),
                    _CreateAccountFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTokens.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppTokens.onSurface.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'InteraEdu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTokens.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bem-vindo de volta.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Continue sua jornada de conhecimento e colaboração.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.googleLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onGoogleSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool googleLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: AppTokens.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── E-mail ─────────────────────────────────────────────────────
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _flatInputDecoration(
              context,
              label: 'E-mail Institucional',
              hint: 'nome@universidade.edu.br',
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Seus dados estão protegidos sob a LGPD.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppTokens.secondary,
                  ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Senha ──────────────────────────────────────────────────────
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            validator: (v) => v?.isEmpty == true ? 'Senha obrigatória' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _flatInputDecoration(
              context,
              label: 'Senha',
              suffix: IconButton(
                splashRadius: 20,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppTokens.onSurfaceVariant,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.forgotPassword),
                child: Text(
                  'Esqueci minha senha',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppTokens.primaryDim,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Entrar ─────────────────────────────────────────────────────
          GradientButton(
            height: 50,
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
          if (_showGoogleSignIn) ...[
            const SizedBox(height: 20),

            // ── Divider OU ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                      height: 1, color: AppTokens.surfaceContainerHigh),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTokens.outlineVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                      height: 1, color: AppTokens.surfaceContainerHigh),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Google ────────────────────────────────────────────────
            _GoogleButton(
              onPressed: googleLoading ? null : onGoogleSignIn,
              loading: googleLoading,
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _flatInputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: AppTokens.surfaceContainerLow,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTokens.onSurfaceVariant,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTokens.onSurfaceVariant,
      ),
      hintStyle: TextStyle(
        color: AppTokens.outlineVariant,
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: BorderSide(
          color: AppTokens.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(
          color: AppTokens.primaryContainer,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(color: AppTokens.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: const BorderSide(color: AppTokens.error, width: 2),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, this.loading = false});
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.surfaceContainerHigh,
          foregroundColor: AppTokens.onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const _GoogleGlyph(size: 16),
            const SizedBox(width: 12),
            Text(
              loading ? 'Conectando...' : 'Continuar com Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTokens.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final r = size.width / 2;
    final c = Offset(r, r);
    // Aproximação minimalista do glifo "G" do Google, tons de cinza
    // para se integrar à paleta neutra do design system Stitch.
    paint.color = const Color(0xFF5E5E67);
    canvas.drawCircle(c, r, paint);
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(r, r * 0.85, r, r * 0.35),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CreateAccountFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Não possui uma conta? ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.onSurfaceVariant,
                ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.register),
            child: Text(
              'Criar conta acadêmica',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
