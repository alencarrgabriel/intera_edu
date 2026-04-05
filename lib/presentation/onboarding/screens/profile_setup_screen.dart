import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/utils/validators.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/auth_repository.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String temporaryToken;
  final String email;

  const ProfileSetupScreen({
    super.key,
    required this.temporaryToken,
    required this.email,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _selectedPeriod;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  final AuthRepository _authRepo = sl.authRepo;

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar os Termos e a Política de Privacidade')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepo.completeRegistration(
        temporaryToken: widget.temporaryToken,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        course: _courseController.text.trim().isEmpty ? null : _courseController.text.trim(),
        period: _selectedPeriod,
        skillIds: null,
      );
      if (!mounted) return;
      // Notifica o AuthNotifier — o AuthWrapper redireciona automaticamente para o Feed
      context.read<AuthNotifier>().forceLogout(); // reset
      await context.read<AuthNotifier>().checkSession();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Configure seu perfil acadêmico',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Essas informações ajudam outras pessoas a te encontrar e colaborar com você.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Nome completo
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => Validators.required(v, 'Nome'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Curso
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Curso',
                    hintText: 'ex.: Ciência da Computação',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Período/Semestre
                DropdownButtonFormField<int>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Período',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((p) => DropdownMenuItem(value: p, child: Text('${p}º período')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPeriod = v),
                ),
                const SizedBox(height: 16),

                // Senha
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Criar Senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Checkbox de termos
                CheckboxListTile(
                  title: const Text(
                    'Aceito os Termos de Uso e a Política de Privacidade',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Botão de concluir
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleComplete,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Concluir Cadastro', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
