import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/connection_repository.dart';
import '../../shared/error_retry_widget.dart';
import '../../shared/profile_info_card.dart';
import '../../shared/user_avatar.dart';

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
  final ProfileRepository _profileRepo = sl.profileRepo;
  final ConnectionRepository _connRepo = sl.connRepo;
  User? _profile;
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
        // connection_status may come from the API as an extra field
        // For now we keep 'none' as default
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
                  ? ErrorRetryWidget(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Avatar e nome
                        Center(
                          child: Column(children: [
                            UserAvatar(
                              name: _profile!.fullName,
                              imageUrl: _profile!.avatarUrl,
                              radius: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _profile!.fullName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _profile!.institution.name,
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
                        ProfileInfoCard(
                          course: _profile!.course,
                          period: _profile!.period,
                        ),

                        // Bio
                        if (_profile!.bio != null && _profile!.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Sobre', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_profile!.bio!, style: const TextStyle(height: 1.5)),
                            ]),
                          ),

                        // Habilidades
                        if (_profile!.skills.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Habilidades', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _profile!.skills
                                    .map((s) => Chip(
                                          label: Text(s.name),
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
