import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/connection_model.dart';
import '../../../domain/repositories/connection_repository.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/messages_notifier.dart';
import '../../../core/widgets/app_snackbar.dart';

/// RF-24 — Criação de grupo de estudos com nome + seleção de membros
/// a partir das conexões aceitas. Backend valida limite de 50 membros.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ConnectionRepository _connRepo = sl.connRepo;
  final _nameCtrl = TextEditingController();
  bool _loadingConns = true;
  bool _creating = false;
  String? _error;
  List<Connection> _connections = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadingConns = true;
      _error = null;
    });
    try {
      _connections = await _connRepo.listConnections(status: 'accepted');
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingConns = false);
    }
  }

  Future<void> _create() async {
    if (_creating) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome ao grupo.')),
      );
      return;
    }
    if (_selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos 2 conexões.')),
      );
      return;
    }
    setState(() => _creating = true);
    final messages = context.read<MessagesNotifier>();
    try {
      final chat = await sl.messagingRepo.createGroupChat(
        name: name,
        memberIds: _selected.toList(),
      );
      await messages.load();
      if (!mounted) return;
      context.pop();
      context.push('/chat/${chat.id}', extra: {'name': name, 'chatId': chat.id});
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        title: const Text('Novo grupo'),
        backgroundColor: AppTokens.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Criar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do grupo',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Selecionar membros',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    Text('${_selected.length} selecionado(s)',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppTokens.primary)),
                ],
              ),
            ),
            Expanded(
              child: _loadingConns
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _connections.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Você ainda não tem conexões aceitas.\nConecte-se com colegas para criar grupos.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _connections.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (_, i) {
                                final c = _connections[i];
                                final u = c.otherUser;
                                if (u == null) return const SizedBox.shrink();
                                final selected = _selected.contains(u.id);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (_) => setState(() {
                                    if (selected) {
                                      _selected.remove(u.id);
                                    } else {
                                      _selected.add(u.id);
                                    }
                                  }),
                                  secondary: UserAvatar(
                                      name: u.fullName,
                                      imageUrl: u.avatarUrl),
                                  title: Text(u.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    [u.course, u.institution?.name]
                                        .where((e) =>
                                            e != null && e.isNotEmpty)
                                        .join(' · '),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
