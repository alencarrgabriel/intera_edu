import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/connection_repository.dart';
import '../../messages/notifiers/messages_notifier.dart';
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
  bool _startingChat = false;

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

  Future<void> _openChat() async {
    if (_startingChat) return;
    setState(() => _startingChat = true);
    try {
      final chat = await context
          .read<MessagesNotifier>()
          .createDirectChat(widget.userId);
      if (!mounted) return;
      if (chat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível iniciar a conversa')));
        return;
      }
      context.push('/chat/${chat.id}', extra: {
        'name': _profile?.fullName ?? widget.initialName ?? 'Conversa',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      extendBodyBehindAppBar: true,
      appBar: AppTheme.glassAppBar(
        context: context,
        title: Text(
          widget.initialName ?? 'Perfil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: AppTokens.onSurface),
            onSelected: (v) async {
              if (v == 'block') {
                await sl.profileRepo.blockUser(widget.userId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário bloqueado.')),
                );
                if (mounted) Navigator.of(context).maybePop();
              } else if (v == 'report') {
                try {
                  await sl.apiClient.post('/reports', body: {
                    'target_type': 'user',
                    'target_id': widget.userId,
                    'reason': 'abuse',
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Denúncia enviada para revisão.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'block',
                child: Row(children: [
                  Icon(Icons.block, size: 18),
                  SizedBox(width: 8),
                  Text('Bloquear usuário'),
                ]),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(children: [
                  Icon(Icons.flag_outlined,
                      size: 18, color: AppTokens.error),
                  SizedBox(width: 8),
                  Text('Denunciar',
                      style: TextStyle(color: AppTokens.error)),
                ]),
              ),
            ],
          ),
        ],
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
                      padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              4,
                          16,
                          24),
                      children: [
                        // ── Header ──────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTokens.primaryContainer.withValues(alpha: 0.5),
                                AppTokens.background,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(children: [
                              UserAvatar(
                                name: _profile!.fullName,
                                imageUrl: _profile!.avatarUrl,
                                radius: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profile!.fullName,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _profile!.institution.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTokens.primary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botões de ação (Conectar + Mensagem)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_connectionStatus == 'none')
                              FilledButton.icon(
                                onPressed: _connecting ? null : _connect,
                                icon: _connecting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
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
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _startingChat ? null : _openChat,
                              icon: _startingChat
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.chat_bubble_outline),
                              label: const Text('Mensagem'),
                            ),
                          ],
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
                                          backgroundColor: AppTokens.primaryContainer,
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
