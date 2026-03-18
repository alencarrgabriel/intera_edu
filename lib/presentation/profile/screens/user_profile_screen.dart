import 'package:flutter/material.dart';
import '../../../data/repositories/profile_repository_impl.dart';
import '../../../data/repositories/connection_repository_impl.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/connection_repository.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  final ConnectionRepository _connRepo = ConnectionRepositoryImpl();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _isPrivate = false;
  String _connectionStatus = 'none'; // none | pending | accepted
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _profileRepo.getUserProfile(widget.userId);
      setState(() {
        _profile = p;
        _connectionStatus = p['connection_status']?.toString() ?? 'none';
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404') || msg.contains('PROFILE_PRIVATE')) {
        setState(() => _isPrivate = true);
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      await _connRepo.sendRequest(widget.userId);
      setState(() => _connectionStatus = 'pending');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  String _privacyLabel(String? level) => switch (level) {
    'public' => '🌎 Público',
    'local_only' => '🏫 Somente minha instituição',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialName ?? 'Perfil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isPrivate
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_outline, size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text('Perfil privado',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Este perfil está visível apenas para conexões ou\nusuários da mesma instituição.',
                        textAlign: TextAlign.center),
                  ]),
                )
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(_error!),
                      ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
                    ]))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Avatar e nome
                        Center(
                          child: Column(children: [
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
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // Botão Conectar
                        if (_connectionStatus == 'none')
                          FilledButton.icon(
                            onPressed: _connecting ? null : _connect,
                            icon: _connecting
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.person_add_outlined),
                            label: const Text('Conectar'),
                          )
                        else if (_connectionStatus == 'pending')
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.hourglass_empty),
                            label: const Text('Solicitação enviada'),
                          )
                        else if (_connectionStatus == 'accepted')
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Conectado'),
                          ),

                        const SizedBox(height: 16),

                        // Info acadêmica
                        if (_profile!['course'] != null || _profile!['period'] != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (_profile!['course'] != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(children: [
                                      const Icon(Icons.menu_book_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Curso: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Expanded(child: Text(_profile!['course'].toString())),
                                    ]),
                                  ),
                                if (_profile!['period'] != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(children: [
                                      const Icon(Icons.calendar_today_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text('${_profile!["period"]}º período'),
                                    ]),
                                  ),
                              ]),
                            ),
                          ),

                        // Bio
                        if (_profile!['bio'] != null && (_profile!['bio'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Sobre', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_profile!['bio'].toString(), style: const TextStyle(height: 1.5)),
                            ]),
                          ),

                        // Habilidades
                        if (_profile!['skills'] != null &&
                            (_profile!['skills'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Habilidades', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: (_profile!['skills'] as List)
                                    .map((s) => Chip(
                                          label: Text(s['name'].toString()),
                                          side: BorderSide.none,
                                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                        ))
                                    .toList(),
                              ),
                            ]),
                          ),
                      ],
                    ),
    );
  }
}
