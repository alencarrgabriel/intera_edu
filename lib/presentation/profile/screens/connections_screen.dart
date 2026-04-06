import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/stitch_card.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/connection_model.dart';
import '../../../domain/repositories/connection_repository.dart';
import '../../shared/user_avatar.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  final ConnectionRepository _connRepo = sl.connRepo;
  late final TabController _tabController;

  List<Connection> _connected = [];
  List<Connection> _received = [];
  List<Connection> _sent = [];
  bool _loading = true;
  String? _error;

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
    setState(() { _loading = true; _error = null; });
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
    } catch (e) {
      setState(() => _error = e.toString());
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
    Connection conn, {
    List<Widget>? actions,
  }) {
    final user = conn.otherUser;
    final name = user?.fullName ?? 'Usuário';
    final course = user?.course;
    final institution = user?.institution?.name;

    return StitchCard(
      child: ListTile(
        leading: UserAvatar(name: name, imageUrl: user?.avatarUrl),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [course, institution].where((e) => e != null && e.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: user != null
            ? () => context.push(AppRoutes.userProfile(user.id), extra: name)
            : null,
        trailing: actions != null
            ? Row(mainAxisSize: MainAxisSize.min, children: actions)
            : null,
      ),
    );
  }

  Widget _buildEmptyState(String message) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.people_outline, size: 64, color: AppTokens.outline),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.onSurfaceVariant)),
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
                      color: AppTokens.error,
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
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
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTokens.error),
                    const SizedBox(height: 8),
                    const Text('Erro ao carregar conexões.'),
                    const SizedBox(height: 8),
                    FilledButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente')),
                  ]),
                )
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
                                onPressed: () => _remove(_connected[i].id),
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
                                    _updateRequest(_received[i].id, 'accept'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                tooltip: 'Rejeitar',
                                onPressed: () =>
                                    _updateRequest(_received[i].id, 'reject'),
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
                                    _remove(_sent[i].id),
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
