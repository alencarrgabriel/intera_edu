import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_notifier.dart';
import '../design/app_tokens.dart';
import '../router/app_router.dart';
import '../../presentation/profile/notifiers/profile_notifier.dart';
import '../../presentation/shared/user_avatar.dart';

/// Drawer principal aberto pelo ícone de menu (3 barras) nas top bars.
/// Atalhos: Perfil, Notificações, Configurações, Administração (oculto se
/// não-admin), Sair.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final auth = context.watch<AuthNotifier>();

    return Drawer(
      backgroundColor: AppTokens.surfaceContainerLowest,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header com avatar/nome ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  UserAvatar(
                    name: profile?.fullName,
                    imageUrl: profile?.avatarUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile?.fullName ?? 'Carregando…',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profile?.institution.name ?? '',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppTokens.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Itens ─────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Item(
                    icon: Icons.person_outline,
                    label: 'Meu perfil',
                    onTap: () {
                      Navigator.pop(context);
                      // O perfil está no IndexedStack; quem trata a tab é o MainScreen.
                    },
                  ),
                  _Item(
                    icon: Icons.notifications_outlined,
                    label: 'Notificações',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.notifications);
                    },
                  ),
                  _Item(
                    icon: Icons.group_outlined,
                    label: 'Grupos por disciplina',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.groups);
                    },
                  ),
                  _Item(
                    icon: Icons.bookmark_outline,
                    label: 'Salvos',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.bookmarks);
                    },
                  ),
                  _Item(
                    icon: Icons.person_add_alt_outlined,
                    label: 'Pessoas pra conhecer',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.suggestions);
                    },
                  ),
                  _Item(
                    icon: Icons.dns_outlined,
                    label: 'Servidor',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.serverSetup);
                    },
                  ),
                  _Item(
                    icon: Icons.settings_outlined,
                    label: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.settings);
                    },
                  ),
                  if (auth.isAdmin) ...[
                    const Divider(),
                    _Item(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Administração',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.admin);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            _Item(
              icon: Icons.logout_rounded,
              label: 'Sair',
              destructive: true,
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthNotifier>().logout();
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'InteraEdu · LGPD compliant',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: AppTokens.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTokens.error : AppTokens.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
