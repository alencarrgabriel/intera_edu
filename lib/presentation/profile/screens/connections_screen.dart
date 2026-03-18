import 'package:flutter/material.dart';
import '../../../data/repositories/connection_repository_impl.dart';
import '../../../domain/repositories/connection_repository.dart';
import 'user_profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  final ConnectionRepository _connRepo = ConnectionRepositoryImpl();
  late final TabController _tabController;

  List<Map<String, dynamic>> _connected = [];
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _connRepo.listConnections(status: 'accepted'),
        _connRepo.listConnections(status: 'pending', direction: 'received'),
        _connRepo.listConnections(status: 'pending', direction: 'sent'),
      ]);
      setState(() {
        _connected = results[0];
        _received = results[1];
        _sent = results[2];
      });
    } catch (_) {
      // Silent fail — exibe listas vazias
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateRequest(String id, String action) async {
    try {
      await _connRepo.updateRequest(id, action);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _remove(String id) async {
    try {
      await _connRepo.removeConnection(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildUserTile(
    Map<String, dynamic> conn, {
    List<Widget>? actions,
  }) {
    final user = conn['other_user'] as Map<String, dynamic>?;
    final name = (user?['full_name'] ?? 'Usuário').toString();
    final course = user?['course']?.toString();
    final institution = (user?['institution']?['name'])?.toString();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [course, institution].where((e) => e != null && e.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: user != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userId: user['id'].toString(),
                      initialName: name,
                    ),
                  ),
                )
            : null,
        trailing: actions != null ? Row(mainAxisSize: MainAxisSize.min, children: actions) : null,
      ),
    );
  }

  Widget _buildEmptyState(String message) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conexões'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Conectados (${_connected.length})'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Recebidas'),
                if (_received.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_received.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ]),
            ),
            Tab(text: 'Enviadas (${_sent.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Aba: Conectados
                  _connected.isEmpty
                      ? _buildEmptyState('Você ainda não tem conexões.\nBusque usuários para se conectar!')
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _connected.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildUserTile(
                            _connected[i],
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                                tooltip: 'Remover conexão',
                                onPressed: () => _remove(_connected[i]['id'].toString()),
                              ),
                            ],
                          ),
                        ),

                  // Aba: Solicitações recebidas
                  _received.isEmpty
                      ? _buildEmptyState('Nenhuma solicitação recebida.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _received.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildUserTile(
                            _received[i],
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                tooltip: 'Aceitar',
                                onPressed: () =>
                                    _updateRequest(_received[i]['id'].toString(), 'accept'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                tooltip: 'Rejeitar',
                                onPressed: () =>
                                    _updateRequest(_received[i]['id'].toString(), 'reject'),
                              ),
                            ],
                          ),
                        ),

                  // Aba: Solicitações enviadas
                  _sent.isEmpty
                      ? _buildEmptyState('Nenhuma solicitação enviada.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _sent.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildUserTile(
                            _sent[i],
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined),
                                tooltip: 'Cancelar solicitação',
                                onPressed: () =>
                                    _remove(_sent[i]['id'].toString()),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
