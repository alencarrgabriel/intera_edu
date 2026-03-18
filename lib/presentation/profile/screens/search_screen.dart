import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/profile_repository_impl.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
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
    setState(() { _loading = true; _hasSearched = true; });
    try {
      final res = await _profileRepo.searchUsers(query.trim());
      final data = (res['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      setState(() => _results = data);
    } catch (_) {
      setState(() => _results = []);
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
                    Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text('Pesquise estudantes por nome, curso ou habilidade'),
                  ]),
                )
              : _results.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person_off_outlined,
                            size: 64, color: Theme.of(context).colorScheme.outline),
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
                        final name = (u['full_name'] ?? 'Sem nome').toString();
                        final course = u['course']?.toString();
                        final institution = (u['institution']?['name'])?.toString();

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              [course, institution]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  userId: u['id'].toString(),
                                  initialName: name,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
