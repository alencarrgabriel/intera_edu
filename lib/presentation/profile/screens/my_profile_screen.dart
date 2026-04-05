import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/stitch_card.dart';
import '../../../domain/entities/user.dart';
import '../../shared/error_retry_widget.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/profile_notifier.dart';
import '../widgets/profile_header_skeleton.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    final notifier = context.read<ProfileNotifier>();
    if (notifier.profile == null && !notifier.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.load());
    }
  }

  Future<void> _goToEdit(User profile) async {
    await context.push(AppRoutes.editProfile, extra: profile);
    // ProfileNotifier.update() já atualizou o cache — sem reload manual.
  }

  String _privacyLabel(String? level) => switch (level) {
    'public' => '🌎 Público',
    'local_only' => '🏫 Somente minha instituição',
    'private' => '🔒 Privado (apenas conexões)',
    _ => 'Desconhecido',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (_, notifier, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Meu Perfil'),
            actions: [
              if (notifier.profile != null)
                IconButton(
                  onPressed: () => _goToEdit(notifier.profile!),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar perfil',
                ),
            ],
          ),
          body: (notifier.loading || notifier.profile == null)
              ? const ProfileHeaderSkeleton()
              : notifier.error != null
                  ? ErrorRetryWidget(
                      message: notifier.error!,
                      onRetry: () => notifier.load(force: true))
                  : _buildProfile(context, notifier.profile!),
        );
      },
    );
  }

  Widget _buildProfile(BuildContext context, User profile) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProfileNotifier>().load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // ── Header com gradiente ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
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
            child: Column(
              children: [
                // Avatar com ícone de câmera (affordance "em breve")
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Upload de foto em breve 📸')),
                  ),
                  child: Stack(
                    children: [
                      UserAvatar(
                        name: profile.fullName,
                        imageUrl: profile.avatarUrl,
                        radius: 48,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTokens.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTokens.background, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: AppTokens.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  profile.institution.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    _privacyLabel(profile.privacyLevel),
                    style: const TextStyle(fontSize: 12),
                  ),
                  side: BorderSide.none,
                  backgroundColor: AppTokens.surfaceContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Informações acadêmicas ───────────────────────────────────────
          if (profile.course != null || profile.period != null)
            _InfoCard(children: [
              if (profile.course != null)
                _InfoRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Curso',
                    value: profile.course!),
              if (profile.period != null)
                _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Período',
                    value: '${profile.period}º período'),
            ]),

          // ── Bio ──────────────────────────────────────────────────────────
          if (profile.bio != null && profile.bio!.isNotEmpty)
            _Section(
              title: 'Sobre',
              child: Text(profile.bio!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6)),
            ),

          // ── Habilidades ──────────────────────────────────────────────────
          if (profile.skills.isNotEmpty)
            _Section(
              title: 'Habilidades',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: profile.skills
                    .map((s) => Chip(
                          label: Text(s.name),
                          side: BorderSide.none,
                          backgroundColor: AppTokens.primaryContainer,
                          labelStyle: const TextStyle(
                              color: AppTokens.onPrimaryContainer,
                              fontWeight: FontWeight.w500),
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.connections),
            icon: const Icon(Icons.people_outline),
            label: const Text('Minhas Conexões'),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: StitchCard(
        padding: const EdgeInsets.all(14),
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
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTokens.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
