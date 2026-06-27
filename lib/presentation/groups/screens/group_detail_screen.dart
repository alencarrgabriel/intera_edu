import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/entities/material.dart';
import '../notifiers/group_detail_notifier.dart';
import '../../feed/widgets/post_card.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupDetailNotifier>().load(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _toggleJoin() async {
    final n = context.read<GroupDetailNotifier>();
    final g = n.group;
    if (g == null) return;
    setState(() => _joining = true);
    try {
      if (g.isMember) {
        await sl.groupsRepo.leaveGroup(g.id);
      } else {
        await sl.groupsRepo.joinGroup(g.id);
      }
      await n.load(g.id);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _uploadMaterial() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    final title = file.name;
    final mime = _guessMime(file.extension);
    try {
      await sl.materialsRepo.upload(
        groupId: widget.groupId,
        title: title,
        fileBytes: bytes,
        filename: file.name,
        mimeType: mime,
      );
      if (!mounted) return;
      await context.read<GroupDetailNotifier>().reloadMaterials();
      if (mounted) AppSnackbar.success(context, 'Material enviado!');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    }
  }

  String _guessMime(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.background,
        elevation: 0,
        title: Consumer<GroupDetailNotifier>(
          builder: (_, n, __) => Text(
            n.group?.name ?? 'Grupo',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTokens.primary,
          unselectedLabelColor: AppTokens.onSurfaceVariant,
          indicatorColor: AppTokens.primary,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Materiais'),
            Tab(text: 'Membros'),
          ],
        ),
      ),
      body: Consumer<GroupDetailNotifier>(
        builder: (_, n, __) {
          if (n.loadingFeed && n.group == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final g = n.group;
          return Column(
            children: [
              if (g != null)
                _Header(
                    description: g.description,
                    members: g.memberCount,
                    isMember: g.isMember,
                    onToggle: _toggleJoin,
                    busy: _joining),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _feedTab(n),
                    _materialsTab(n),
                    _membersTab(n),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (_, __) {
          if (_tab.index == 1) {
            return FloatingActionButton.extended(
              backgroundColor: AppTokens.primary,
              icon: const Icon(Icons.upload_file_outlined,
                  color: Colors.white),
              label: const Text('Material',
                  style: TextStyle(color: Colors.white)),
              onPressed: _uploadMaterial,
            );
          }
          if (_tab.index == 0) {
            return FloatingActionButton.extended(
              backgroundColor: AppTokens.primary,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Postar',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => context.push(
                AppRoutes.createPost,
                extra: {'group_id': widget.groupId},
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _feedTab(GroupDetailNotifier n) {
    if (n.feed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sem posts ainda. Seja o primeiro a publicar!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTokens.onSurfaceVariant),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: n.reloadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: n.feed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => PostCard(
          post: n.feed[i],
          onReact: (_) {},
          onComment: () {},
          onDelete: () {},
          onReport: () {},
        ),
      ),
    );
  }

  Widget _membersTab(GroupDetailNotifier n) {
    if (n.loadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.members.isEmpty) {
      return Center(
        child: Text('Sem membros ainda.',
            style: TextStyle(color: AppTokens.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: n.members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = n.members[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTokens.primaryContainer,
            backgroundImage:
                m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
            child: m.avatarUrl == null
                ? Text(
                    (m.fullName ?? '?').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: AppTokens.onPrimaryContainer,
                        fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          title: Text(m.fullName ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            [if (m.course != null) m.course!, if (m.role == 'admin') 'Admin']
                .join(' · '),
            style: TextStyle(color: AppTokens.onSurfaceVariant, fontSize: 12.5),
          ),
          onTap: () => context.push(AppRoutes.userProfile(m.userId),
              extra: m.fullName),
        );
      },
    );
  }

  Widget _materialsTab(GroupDetailNotifier n) {
    if (n.loadingMaterials) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.materials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sem materiais ainda. Use o botão acima pra adicionar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTokens.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: n.materials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _MaterialTile(material: n.materials[i]),
    );
  }
}

class _Header extends StatelessWidget {
  final String? description;
  final int members;
  final bool isMember;
  final VoidCallback onToggle;
  final bool busy;
  const _Header({
    this.description,
    required this.members,
    required this.isMember,
    required this.onToggle,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: AppTokens.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null && description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(description!,
                  style: TextStyle(
                      color: AppTokens.onSurfaceVariant, fontSize: 13)),
            ),
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: AppTokens.onSurfaceVariant, size: 16),
              const SizedBox(width: 4),
              Text('$members membros',
                  style: TextStyle(
                      color: AppTokens.onSurfaceVariant, fontSize: 13)),
              const Spacer(),
              FilledButton(
                onPressed: busy ? null : onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isMember ? AppTokens.surfaceContainerLowest : AppTokens.primary,
                  foregroundColor: isMember ? AppTokens.onSurface : Colors.white,
                  visualDensity: VisualDensity.compact,
                  side: isMember
                      ? BorderSide(color: AppTokens.outlineVariant)
                      : BorderSide.none,
                ),
                child: Text(isMember ? 'Sair' : 'Entrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final GroupMaterial material;
  const _MaterialTile({required this.material});

  IconData get _icon {
    switch (material.kind) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.movie_outlined;
      case 'doc':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _open(BuildContext context) async {
    try {
      final url = await sl.materialsRepo.getDownloadUrl(material.id);
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      AppSnackbar.info(context, 'Link copiado pra área de transferência.');
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTokens.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: AppTokens.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTokens.primaryContainer,
          child: Icon(_icon, color: AppTokens.onPrimaryContainer),
        ),
        title: Text(material.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${material.downloadCount} downloads · ★ ${material.ratingAvg}',
          style: TextStyle(color: AppTokens.onSurfaceVariant, fontSize: 12.5),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () => _open(context),
        ),
        onTap: () => _open(context),
      ),
    );
  }
}

