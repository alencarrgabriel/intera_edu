import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../domain/repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  bool _hasFocus = false;
  final AuthRepository _authRepo = sl.authRepo;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (mounted) setState(() => _hasFocus = _emailFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await _authRepo.register(email);
      if (!mounted) return;
      context.go(AppRoutes.otp, extra: email);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      body: Stack(
        children: [
          // ── Editorial blur ornaments ─────────────────────────────────────
          const _BackgroundOrnaments(),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepProgress(current: 1, total: 5),
                        const SizedBox(height: 40),

                        Text(
                          'Bem-vindo ao InteraEdu.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Para começar, insira seu e-mail da universidade (.edu).',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppTokens.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 40),

                        // ── Email field ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'E-MAIL INSTITUCIONAL',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTokens.secondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _EmailField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hasFocus: _hasFocus,
                          onSubmit: _handleRegister,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 12,
                                color:
                                    AppTokens.secondary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Seus dados estão protegidos sob a LGPD.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontSize: 11,
                                        color: AppTokens.secondary
                                            .withValues(alpha: 0.7),
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Feature highlight ───────────────────────────
                        const _FeatureCard(),
                        const SizedBox(height: 32),

                        // ── Primary action ──────────────────────────────
                        GradientButton(
                          height: 56,
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Próximo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 32),

                        // ── Footer ──────────────────────────────────────
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Já possui uma conta? ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTokens.secondary),
                              ),
                              GestureDetector(
                                onTap: () => context.go(AppRoutes.login),
                                child: Text(
                                  'Fazer login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTokens.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationThickness: 2,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Passo $current de $total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTokens.secondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
        ),
        Row(
          children: List.generate(total, (i) {
            final active = i < current;
            return Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
              height: 6,
              width: 32,
              decoration: BoxDecoration(
                color: active
                    ? AppTokens.primary
                    : AppTokens.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.email,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmit(),
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: AppTokens.onSurface),
      decoration: InputDecoration(
        hintText: 'seuemail@faculdade.edu',
        filled: true,
        fillColor: AppTokens.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            Icons.school_outlined,
            color: hasFocus ? AppTokens.primary : AppTokens.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide(
            color: AppTokens.outlineVariant.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: const BorderSide(
            color: AppTokens.primaryDim,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: const BorderSide(color: AppTokens.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: const BorderSide(color: AppTokens.error, width: 2),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(
          color: AppTokens.outlineVariant.withValues(alpha: 0.10),
        ),
        boxShadow: AppTokens.ambientShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTokens.primaryContainer.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppTokens.primaryDim,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acesso Exclusivo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Conectamos apenas pesquisadores e estudantes verificados de instituições de ensino superior.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrnaments extends StatelessWidget {
  const _BackgroundOrnaments();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.primaryContainer.withValues(alpha: 0.30),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.secondaryContainer.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
