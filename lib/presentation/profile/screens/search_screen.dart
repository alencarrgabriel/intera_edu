import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/search_result_model.dart';
import '../../../domain/entities/user.dart' show Skill;
import '../../../domain/repositories/connection_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/profile_notifier.dart';

/// Tela "Explorar" no padrão Stitch:
/// top bar, busca pill, filtros visuais e seção "Pessoas sugeridas para você"
/// com cards mostrando habilidades em comum.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProfileRepository _profileRepo = sl.profileRepo;
  final ConnectionRepository _connRepo = sl.connRepo;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<SearchResult> _results = [];
  String _query = '';
  final Set<String> _requesting = {};
  final Set<String> _requested = {};

  // Filtros ativos.
  _FilterOption? _skillFilter;
  _FilterOption? _institutionFilter;
  String? _courseFilter; // valor digitado

  // Cache para os bottom sheets de filtro.
  List<Skill>? _skillsCache;

  @override
  void initState() {
    super.initState();
    // Carrega sugestões iniciais a partir de uma query "broad".
    WidgetsBinding.instance.addPostFrameCallback((_) => _search(' '));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() => _query = query);
    final q = query.trim();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(q.isEmpty ? ' ' : q);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final myId = context.read<ProfileNotifier>().profile?.id;
    try {
      final result = await _profileRepo.searchUsers(
        query,
        skillId: _skillFilter?.id,
        institutionId: _institutionFilter?.id,
        course: _courseFilter,
      );
      if (!mounted) return;
      setState(() => _results = myId == null
          ? result.data
          : result.data.where((r) => r.id != myId).toList());
    } catch (e) {
      setState(() {
        _results = [];
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Filtros ────────────────────────────────────────────────────────────

  Future<void> _openSkillFilter() async {
    _skillsCache ??= await _profileRepo.getSkills();
    if (!mounted) return;
    final picked = await showModalBottomSheet<_FilterOption?>(
      context: context,
      backgroundColor: AppTokens.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (ctx) => _FilterSheet(
        title: 'Filtrar por habilidade',
        items: _skillsCache!
            .map((s) => _FilterOption(s.id, s.name))
            .toList(),
        selected: _skillFilter?.id,
      ),
    );
    if (!mounted) return;
    setState(() => _skillFilter = picked);
    _search(_query.trim().isEmpty ? ' ' : _query);
  }

  Future<void> _openInstitutionFilter() async {
    final picked = await showModalBottomSheet<_FilterOption?>(
      context: context,
      backgroundColor: AppTokens.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (ctx) => _FilterSheet(
        title: 'Filtrar por instituição',
        items: const [
          _FilterOption('f2f1bd56-0bdd-406f-acc3-d0d7c21a027a', 'UFMG'),
          _FilterOption('79e44efb-e085-4967-b858-89154ce949aa', 'USP'),
        ],
        selected: _institutionFilter?.id,
      ),
    );
    if (!mounted) return;
    setState(() => _institutionFilter = picked);
    _search(_query.trim().isEmpty ? ' ' : _query);
  }

  Future<void> _openCourseFilter() async {
    final controller =
        TextEditingController(text: _courseFilter ?? '');
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar por curso',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ex.: Ciência da Computação',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                        ctx,
                        controller.text.trim().isEmpty
                            ? null
                            : controller.text.trim()),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _courseFilter = picked);
    _search(_query.trim().isEmpty ? ' ' : _query);
  }

  Future<void> _connect(String userId) async {
    if (_requesting.contains(userId)) return;
    setState(() => _requesting.add(userId));
    try {
      await _connRepo.sendRequest(userId);
      setState(() {
        _requested.add(userId);
        _requesting.remove(userId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada')),
      );
    } catch (e) {
      setState(() => _requesting.remove(userId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ProfileNotifier>().profile;
    final mySkillIds = me?.skills.map((s) => s.id).toSet() ?? {};

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: _StitchTopBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _search(_query.trim().isEmpty ? ' ' : _query),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              // ── Search input ───────────────────────────────────────────
              _SearchInput(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 14),

              // ── Filtros (funcionais) ───────────────────────────────────
              _FilterChips(
                skillLabel: _skillFilter?.label,
                institutionLabel: _institutionFilter?.label,
                courseLabel: _courseFilter,
                onSkill: _openSkillFilter,
                onInstitution: _openInstitutionFilter,
                onCourse: _openCourseFilter,
                onClearSkill: () {
                  setState(() => _skillFilter = null);
                  _search(_query.trim().isEmpty ? ' ' : _query);
                },
                onClearInstitution: () {
                  setState(() => _institutionFilter = null);
                  _search(_query.trim().isEmpty ? ' ' : _query);
                },
                onClearCourse: () {
                  setState(() => _courseFilter = null);
                  _search(_query.trim().isEmpty ? ' ' : _query);
                },
              ),
              const SizedBox(height: 24),

              // ── Header sugeridas ───────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _query.trim().isEmpty
                          ? 'Pessoas sugeridas\npara você'
                          : 'Resultados para "$_query"',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.1,
                          ),
                    ),
                  ),
                  if (_query.trim().isEmpty)
                    Text(
                      'BASEADO EM\nSUAS SKILLS',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppTokens.primary,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Conteúdo ───────────────────────────────────────────────
              if (_loading && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorBox(
                  message: _error!,
                  onRetry: () =>
                      _search(_query.trim().isEmpty ? ' ' : _query),
                )
              else if (_results.isEmpty)
                _EmptyBox(query: _query)
              else
                ..._results.map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SuggestionCard(
                        result: u,
                        mySkillIds: mySkillIds,
                        requested: _requested.contains(u.id),
                        requesting: _requesting.contains(u.id),
                        onConnect: () => _connect(u.id),
                        onTap: () => context.push(
                          AppRoutes.userProfile(u.id),
                          extra: u.fullName,
                        ),
                      ),
                    )),

              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 12, color: AppTokens.outlineVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Seus dados estão protegidos sob a LGPD.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        ),
      ],
    );
  }
}

// ── Search input ──────────────────────────────────────────────────────────────

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppTokens.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Buscar por pessoas, habilidades ou curso',
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded,
                  color: AppTokens.onSurfaceVariant, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.skillLabel,
    required this.institutionLabel,
    required this.courseLabel,
    required this.onSkill,
    required this.onInstitution,
    required this.onCourse,
    required this.onClearSkill,
    required this.onClearInstitution,
    required this.onClearCourse,
  });

  final String? skillLabel;
  final String? institutionLabel;
  final String? courseLabel;
  final VoidCallback onSkill;
  final VoidCallback onInstitution;
  final VoidCallback onCourse;
  final VoidCallback onClearSkill;
  final VoidCallback onClearInstitution;
  final VoidCallback onClearCourse;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: skillLabel ?? 'Habilidades',
            icon: Icons.bookmark_outline,
            selected: skillLabel != null,
            onTap: onSkill,
            onClear: skillLabel != null ? onClearSkill : null,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: institutionLabel ?? 'Instituição',
            icon: Icons.school_outlined,
            selected: institutionLabel != null,
            onTap: onInstitution,
            onClear: institutionLabel != null ? onClearInstitution : null,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: courseLabel ?? 'Curso',
            icon: Icons.menu_book_outlined,
            selected: courseLabel != null,
            onTap: onCourse,
            onClear: courseLabel != null ? onClearCourse : null,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.primaryContainer.withValues(alpha: 0.6)
              : AppTokens.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: selected
                ? AppTokens.primary.withValues(alpha: 0.30)
                : AppTokens.outlineVariant.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? AppTokens.primary
                    : AppTokens.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppTokens.primary
                    : AppTokens.onSurfaceVariant,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppTokens.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String id;
  final String label;
  const _FilterOption(this.id, this.label);
}

/// Bottom sheet genérico para escolha de filtro com lista de opções.
/// Retorna o item selecionado via Navigator.pop, ou null se cancelado.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.items,
    this.selected,
  });

  final String title;
  final List<_FilterOption> items;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                final isSel = it.id == selected;
                return ListTile(
                  onTap: () => Navigator.pop(context, it),
                  title: Text(it.label),
                  trailing: isSel
                      ? const Icon(Icons.check_rounded,
                          color: AppTokens.primary)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Limpar filtro'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestion card ───────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.result,
    required this.mySkillIds,
    required this.requested,
    required this.requesting,
    required this.onConnect,
    required this.onTap,
  });

  final SearchResult result;
  final Set<String> mySkillIds;
  final bool requested;
  final bool requesting;
  final VoidCallback onConnect;
  final VoidCallback onTap;

  String get _contextLine {
    final shared = result.skills
        .where((s) => mySkillIds.contains(s.id))
        .map((s) => s.name)
        .toList();
    if (shared.isNotEmpty) {
      return 'Interesses em comum: ${shared.join(', ')}';
    }
    if (result.skills.isNotEmpty) {
      return 'Conectado via ${result.skills.first.name}';
    }
    return 'Sugerido pela rede';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTokens.outlineVariant.withValues(alpha: 0.20),
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            boxShadow: AppTokens.ambientShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: result.fullName,
                    imageUrl: result.avatarUrl,
                    radius: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [result.institution?.name, result.course]
                              .where((e) => e != null && e.isNotEmpty)
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppTokens.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _ConnectIcon(
                    requested: requested,
                    requesting: requesting,
                    onTap: onConnect,
                  ),
                ],
              ),
              if (result.skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.skills
                      .take(3)
                      .map((s) => _SkillPill(label: s.name.toUpperCase()))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 12, color: AppTokens.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _contextLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTokens.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectIcon extends StatelessWidget {
  const _ConnectIcon({
    required this.requested,
    required this.requesting,
    required this.onTap,
  });

  final bool requested;
  final bool requesting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: requested || requesting ? null : onTap,
      icon: requesting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              requested
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_rounded,
              color: requested
                  ? AppTokens.primary
                  : AppTokens.onSurfaceVariant,
            ),
      tooltip: requested ? 'Solicitação enviada' : 'Solicitar conexão',
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppTokens.onPrimaryContainer,
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppTokens.error),
          const SizedBox(height: 8),
          const Text('Erro ao buscar.'),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.person_search_outlined,
              size: 56, color: AppTokens.outlineVariant),
          const SizedBox(height: 12),
          Text(
            query.trim().isEmpty
                ? 'Sem sugestões no momento'
                : 'Nenhum resultado para "$query"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
