import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../feed/screens/feed_screen.dart';

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
  final AuthRepository _authRepo = AuthRepositoryImpl();

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
        const SnackBar(content: Text('You must accept the Terms and Privacy Policy')),
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FeedScreen()),
        (route) => false,
      );
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
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set up your academic profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This information helps others find and collaborate with you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Full name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => Validators.required(v, 'Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Course
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    hintText: 'e.g., Computer Science',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Period/Semester
                DropdownButtonFormField<int>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((p) => DropdownMenuItem(value: p, child: Text('$pº semester')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPeriod = v),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Create Password',
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

                // Terms checkbox
                CheckboxListTile(
                  title: const Text(
                    'I accept the Terms of Service and Privacy Policy',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Complete button
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
                        : const Text('Complete Registration', style: TextStyle(fontSize: 16)),
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
