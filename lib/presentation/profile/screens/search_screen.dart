import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/stitch_card.dart';
import '../../../data/models/search_result_model.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../shared/user_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProfileRepository _profileRepo = sl.profileRepo;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<SearchResult> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() { _loading = true; _hasSearched = true; _error = null; });
    try {
      final result = await _profileRepo.searchUsers(query.trim());
      setState(() => _results = result.data);
    } catch (e) {
      setState(() { _results = []; _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar por nome, curso ou habilidade...',
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_rounded,
                        size: 64, color: AppTokens.outline),
                    const SizedBox(height: 16),
                    Text(
                      'Pesquise estudantes por nome, curso ou habilidade',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTokens.onSurfaceVariant),
                    ),
                  ]),
                )
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppTokens.error),
                        const SizedBox(height: 8),
                        const Text('Erro ao buscar. Verifique sua conexão.'),
                      ]),
                    )
              : _results.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_off_outlined,
                            size: 64, color: AppTokens.outline),
                        const SizedBox(height: 16),
                        const Text('Nenhum resultado encontrado.'),
                      ]),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final u = _results[i];
                        return StitchCard(
                          child: ListTile(
                            leading: UserAvatar(
                              name: u.fullName,
                              imageUrl: u.avatarUrl,
                            ),
                            title: Text(u.fullName,
                                style: Theme.of(context).textTheme.titleSmall),
                            subtitle: Text(
                              [u.course, u.institution?.name]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: AppTokens.outline),
                            onTap: () => context.push(
                              AppRoutes.userProfile(u.id),
                              extra: u.fullName,
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
