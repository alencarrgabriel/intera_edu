import 'package:flutter/material.dart';
import '../../../data/repositories/profile_repository_impl.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'edit_profile_screen.dart';
import 'connections_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _profileRepo.getMyProfile();
      setState(() => _profile = p);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile!)),
    );
    if (updated == true) _load();
  }

  String _privacyLabel(String? level) => switch (level) {
    'public' => '🌎 Público',
    'local_only' => '🏫 Somente minha instituição',
    'private' => '🔒 Privado (apenas conexões)',
    _ => 'Desconhecido',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          if (_profile != null)
            IconButton(
              onPressed: _goToEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Avatar e nome
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                (_profile!['full_name'] ?? '?').toString().isNotEmpty
                                    ? (_profile!['full_name'] as String)[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (_profile!['full_name'] ?? 'Sem nome').toString(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (_profile!['institution'] != null)
                              Text(
                                (_profile!['institution']?['name'] ?? '').toString(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            const SizedBox(height: 8),
                            // Badge de privacidade
                            Chip(
                              label: Text(
                                _privacyLabel(_profile!['privacy_level']?.toString()),
                                style: const TextStyle(fontSize: 12),
                              ),
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Informações acadêmicas
                      if (_profile!['course'] != null || _profile!['period'] != null)
                        _InfoCard(children: [
                          if (_profile!['course'] != null)
                            _InfoRow(icon: Icons.menu_book_outlined, label: 'Curso',
                                value: _profile!['course'].toString()),
                          if (_profile!['period'] != null)
                            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Período',
                                value: '${_profile!['period']}º período'),
                        ]),

                      // Bio
                      if (_profile!['bio'] != null && (_profile!['bio'] as String).isNotEmpty)
                        _Section(
                          title: 'Sobre',
                          child: Text(_profile!['bio'].toString(),
                              style: const TextStyle(height: 1.5)),
                        ),

                      // Habilidades
                      if (_profile!['skills'] != null &&
                          (_profile!['skills'] as List).isNotEmpty)
                        _Section(
                          title: 'Habilidades',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: (_profile!['skills'] as List)
                                .map((s) => Chip(
                                      label: Text(s['name'].toString()),
                                      side: BorderSide.none,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                    ))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Botão de conexões
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConnectionsScreen()),
                        ),
                        icon: const Icon(Icons.people_outline),
                        label: const Text('Minhas Conexões'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
