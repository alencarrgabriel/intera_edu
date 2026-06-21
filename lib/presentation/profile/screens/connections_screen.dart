import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/connection_model.dart';
import '../../../domain/repositories/connection_repository.dart';
import '../../shared/user_avatar.dart';

/// Tela "Suas Conexões" inspirada no protótipo Stitch:
/// top bar centralizado, título grande + subtítulo, segmented control
/// (Pendentes / Conectados) e cards de solicitação com CTA Recusar / Aceitar.
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final ConnectionRepository _connRepo = sl.connRepo;

  List<Connection> _connected = [];
  List<Connection> _received = [];
  bool _loading = true;
  String? _error;
  int _tabIndex = 0; // 0 = Pendentes, 1 = Conectados

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _connRepo.listConnections(status: 'pending', direction: 'received'),
        _connRepo.listConnections(status: 'accepted'),
      ]);
      setState(() {
        _received = results[0];
        _connected = results[1];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String id, String action) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: _StitchTopBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ── Título + subtítulo ─────────────────────────────────────
              Text(
                'Suas Conexões',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie suas colaborações acadêmicas e expanda sua rede de conhecimento.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),

              // ── Segmented control ──────────────────────────────────────
              _SegmentedTabs(
                index: _tabIndex,
                pendingCount: _received.length,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: 20),

              // ── Conteúdo da aba ─────────────────────────────────────────
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorBox(message: _error!, onRetry: _load)
              else
                ..._buildTabContent(),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'SEUS DADOS ESTÃO PROTEGIDOS SOB A LGPD.',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    if (_tabIndex == 0) {
      if (_received.isEmpty) {
        return [
          _EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Sem solicitações pendentes',
            subtitle:
                'Quando alguém solicitar conexão, aparecerá aqui.',
          ),
        ];
      }
      return _received
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PendingCard(
                  connection: c,
                  onAccept: () => _respond(c.id, 'accept'),
                  onReject: () => _respond(c.id, 'reject'),
                ),
              ))
          .toList();
    } else {
      if (_connected.isEmpty) {
        return [
          _EmptyState(
            icon: Icons.people_outline,
            title: 'Você ainda não tem conexões',
            subtitle:
                'Use a aba Explorar pra buscar e conectar com outros estudantes.',
          ),
        ];
      }
      return _connected
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ConnectedCard(
                  connection: c,
                  onRemove: () => _remove(c.id),
                ),
              ))
          .toList();
    }
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _StitchTopBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu_rounded, color: AppTokens.onSurface),
      ),
      title: Text(
        'InteraEdu',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTokens.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined,
              color: AppTokens.primary),
          tooltip: 'Notificações',
        ),
      ],
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.index,
    required this.pendingCount,
    required this.onChanged,
  });

  final int index;
  final int pendingCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Pendentes',
              badge: pendingCount,
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Conectados',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTokens.onSurface.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppTokens.onSurface
                    : AppTokens.onSurfaceVariant,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.primary,
                  borderRadius:
                      BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: AppTokens.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.connection,
    required this.onAccept,
    required this.onReject,
  });

  final Connection connection;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final user = connection.otherUser;
    final name = user?.fullName ?? 'Usuário';
    final course = user?.course;
    final institution = user?.institution?.name;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: AppTokens.outlineVariant.withValues(alpha: 0.20),
        ),
        boxShadow: AppTokens.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarWithBadge(name: name, imageUrl: user?.avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: user != null
                      ? () => context.push(AppRoutes.userProfile(user.id),
                          extra: name)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [course, institution]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTokens.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.handshake_outlined,
                              size: 12, color: AppTokens.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Solicitou colaboração',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTokens.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RejectButton(onPressed: onReject),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AcceptButton(onPressed: onAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.connection, required this.onRemove});
  final Connection connection;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final user = connection.otherUser;
    final name = user?.fullName ?? 'Usuário';
    final course = user?.course;
    final institution = user?.institution?.name;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: AppTokens.outlineVariant.withValues(alpha: 0.20),
        ),
        boxShadow: AppTokens.ambientShadow,
      ),
      child: Row(
        children: [
          _AvatarWithBadge(name: name, imageUrl: user?.avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: user != null
                  ? () => context.push(AppRoutes.userProfile(user.id),
                      extra: name)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [course, institution]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' · '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTokens.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.person_remove_outlined),
            color: AppTokens.onSurfaceVariant,
            tooltip: 'Remover conexão',
          ),
        ],
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({required this.name, this.imageUrl});
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(name: name, imageUrl: imageUrl, radius: 26),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppTokens.primary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTokens.surfaceContainerLowest, width: 2),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppTokens.onPrimary, size: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTokens.primaryGradient,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          boxShadow: AppTokens.primaryShadow,
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppTokens.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
          ),
          child: const Text(
            'Aceitar',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _RejectButton extends StatelessWidget {
  const _RejectButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.surfaceContainerHigh,
          foregroundColor: AppTokens.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        child: const Text(
          'Recusar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppTokens.outlineVariant),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppTokens.error),
          const SizedBox(height: 8),
          const Text('Erro ao carregar conexões.'),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
