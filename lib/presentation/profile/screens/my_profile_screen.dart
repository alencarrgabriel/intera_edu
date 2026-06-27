import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user.dart';
import '../../feed/notifiers/feed_notifier.dart';
import '../../shared/error_retry_widget.dart';
import '../../shared/relative_time_text.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/profile_notifier.dart';
import '../widgets/profile_header_skeleton.dart';

/// Tela "Perfil" inspirada no protótipo Stitch:
/// avatar central, identidade, badge de conexões, blocos "Minhas Habilidades"
/// e "Minhas Publicações", CTA "Editar dados do perfil" e nota LGPD.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _uploadingAvatar = false;

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
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja encerrar sua sessão?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTokens.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthNotifier>().logout();
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;
    final notifier = context.read<ProfileNotifier>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) AppSnackbar.error(context, 'Não foi possível ler o arquivo.');
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) AppSnackbar.warning(context, 'Imagem maior que 5 MB. Escolha outra.');
        return;
      }
      final ext = (file.extension ?? '').toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      if (mounted) setState(() => _uploadingAvatar = true);
      await notifier.uploadAvatar(
        bytes: bytes,
        filename: file.name,
        mimeType: mime,
      );
      if (mounted) AppSnackbar.success(context, 'Avatar atualizado!');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: _ProfileTopBar(onSettings: () => context.push(AppRoutes.settings)),
      drawer: const AppDrawer(),
      body: Consumer<ProfileNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading && notifier.profile == null) {
            return const ProfileHeaderSkeleton();
          }
          if (notifier.error != null) {
            return ErrorRetryWidget(
              message: notifier.error!,
              onRetry: () => notifier.load(force: true),
            );
          }
          if (notifier.profile == null) {
            return const ProfileHeaderSkeleton();
          }
          return _buildBody(context, notifier.profile!);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, User profile) {
    final feed = context.watch<FeedNotifier>();
    final userId = context.read<AuthNotifier>().userId;
    final myPosts =
        feed.posts.where((p) => p.authorId == userId).toList(growable: false);

    return RefreshIndicator(
      onRefresh: () => context.read<ProfileNotifier>().load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Avatar + identidade ────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: _AvatarWithBadge(
                profile: profile,
                uploading: _uploadingAvatar,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile.fullName.isNotEmpty
                  ? profile.fullName
                  : '(sem nome)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
          ),
          if (profile.course != null && profile.course!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile.course!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.onSurfaceVariant,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 2),
          Center(
            child: Text(
              profile.institution.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Badge de conexões ──────────────────────────────────────────
          Center(child: _ConnectionsPill(userId: profile.id)),

          const SizedBox(height: 32),

          // ── Habilidades ─────────────────────────────────────────────────
          _SectionHeader(
            title: 'Minhas Habilidades',
            action: 'Editar',
            onAction: () => _goToEdit(profile),
          ),
          const SizedBox(height: 12),
          _SkillsWrap(
            skills: profile.skills,
            onAdd: () => _goToEdit(profile),
          ),

          const SizedBox(height: 32),

          // ── Publicações ─────────────────────────────────────────────────
          _SectionHeader(
            title: 'Minhas Publicações',
            actionIcon: Icons.add_rounded,
            onAction: () => context.push(AppRoutes.createPost),
          ),
          const SizedBox(height: 12),
          if (myPosts.isEmpty)
            _EmptyPostsCard(
              onCreate: () => context.push(AppRoutes.createPost),
            )
          else
            ...myPosts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PublicationCard(post: p),
                )),

          const SizedBox(height: 32),

          // ── CTA editar ──────────────────────────────────────────────────
          _EditProfileButton(onTap: () => _goToEdit(profile)),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Seus dados estão protegidos sob a LGPD.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: AppTokens.outlineVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _ProfileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileTopBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          icon: const Icon(Icons.menu_rounded, color: AppTokens.onSurface),
        ),
      ),
      title: Center(
        child: Text(
          'InteraEdu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTokens.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined,
              color: AppTokens.onSurfaceVariant),
          tooltip: 'Configurações / Sair',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined,
              color: AppTokens.onSurfaceVariant),
          tooltip: 'Notificações',
        ),
      ],
    );
  }
}

// ── Avatar + badge ─────────────────────────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({required this.profile, required this.uploading});
  final User profile;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppTokens.ambientShadow,
            ),
            child: ClipOval(
              child: UserAvatar(
                name: profile.fullName,
                imageUrl: profile.avatarUrl,
                radius: 58,
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: uploading ? AppTokens.surfaceContainerHigh : AppTokens.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.background, width: 3),
                boxShadow: uploading ? null : AppTokens.primaryShadow,
              ),
              child: uploading
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTokens.primary,
                      ),
                    )
                  : const Icon(
                      Icons.verified_rounded,
                      color: AppTokens.onPrimary,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Connections pill ───────────────────────────────────────────────────────────

class _ConnectionsPill extends StatelessWidget {
  const _ConnectionsPill({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    // Conta as conexões a partir de uma rota cached do ConnectionsScreen;
    // se ainda não carregadas, fica '—'. O número é só visual — clicar leva
    // pra aba Conexões pra detalhe.
    return GestureDetector(
      onTap: () => context.push(AppRoutes.connections),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTokens.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: AppTokens.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_rounded,
                size: 14, color: AppTokens.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Minhas Conexões',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTokens.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.action,
    this.actionIcon,
    required this.onAction,
  });

  final String title;
  final String? action;
  final IconData? actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (actionIcon != null)
          IconButton(
            onPressed: onAction,
            icon: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTokens.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(actionIcon, size: 16, color: AppTokens.primary),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        else if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTokens.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
      ],
    );
  }
}

// ── Skills ─────────────────────────────────────────────────────────────────────

class _SkillsWrap extends StatelessWidget {
  const _SkillsWrap({required this.skills, required this.onAdd});
  final List<Skill> skills;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...skills.map((s) => _SkillChip(label: s.name)),
        _AddSkillChip(onTap: onAdd),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTokens.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AddSkillChip extends StatelessWidget {
  const _AddSkillChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: AppTokens.outlineVariant.withValues(alpha: 0.40),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: AppTokens.primary),
            const SizedBox(width: 4),
            Text(
              'Adicionar',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Publication card ──────────────────────────────────────────────────────────

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final tag = post.scope == 'global'
        ? 'PUBLICAÇÃO GLOBAL'
        : 'PUBLICAÇÃO LOCAL';
    final firstLine = post.content.trim().split('\n').first;
    final excerpt = post.content.length > 160
        ? '${post.content.substring(0, 160)}…'
        : post.content;
    final preview = excerpt == firstLine ? null : excerpt;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
            children: [
              Expanded(
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTokens.primary,
                  ),
                ),
              ),
              Icon(Icons.more_vert,
                  size: 18, color: AppTokens.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            firstLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 6),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppTokens.onSurfaceVariant),
              const SizedBox(width: 4),
              RelativeTimeText(date: post.createdAt, compact: true),
              const SizedBox(width: 12),
              const Icon(Icons.thumb_up_outlined,
                  size: 12, color: AppTokens.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${post.reactionCount} reações',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTokens.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPostsCard extends StatelessWidget {
  const _EmptyPostsCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: AppTokens.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.article_outlined,
              size: 36, color: AppTokens.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Você ainda não publicou nada',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compartilhe um projeto ou ideia com a rede.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Criar publicação'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTokens.outlineVariant.withValues(alpha: 0.30),
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTokens.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppTokens.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Editar dados do perfil',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTokens.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
