import 'package:flutter/material.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_endpoints.dart';

/// RF-37/38/39 — Tela de administração: cadastro de IES, gestão de domínios
/// e fila de moderação. Acessível apenas se o usuário tem `role = 'admin'`.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Map<String, dynamic>> _institutions = [];
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final inst = await sl.apiClient.get('/institutions');
      final rep = await sl.apiClient.get(ApiEndpoints.reports);
      setState(() {
        _institutions = ((inst['data'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        _reports =
            ((rep['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createInstitution() async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final domainsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova instituição'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: slugCtrl,
                decoration:
                    const InputDecoration(labelText: 'Slug (ex.: ufmg)'),
              ),
              TextField(
                controller: domainsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Domínios (separados por vírgula)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Criar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sl.apiClient.post('/institutions', body: {
        'name': nameCtrl.text.trim(),
        'slug': slugCtrl.text.trim(),
        'domains': domainsCtrl.text
            .split(',')
            .map((d) => d.trim())
            .where((d) => d.isNotEmpty)
            .toList(),
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editDomains(Map<String, dynamic> inst) async {
    final domains = (inst['domains'] as List?) ?? const [];
    final ctrl =
        TextEditingController(text: domains.cast<String>().join(', '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Domínios de ${inst['name']}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Domínios separados por vírgula'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true) return;
    final newSet = ctrl.text
        .split(',')
        .map((d) => d.trim().toLowerCase())
        .where((d) => d.isNotEmpty)
        .toSet();
    final oldSet = domains.cast<String>().map((d) => d.toLowerCase()).toSet();
    final add = newSet.difference(oldSet).toList();
    final remove = oldSet.difference(newSet).toList();
    try {
      await sl.apiClient.patch(
        '/institutions/${inst['id']}/domains',
        body: {'add': add, 'remove': remove},
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _resolveReport(String id, String action) async {
    try {
      await sl.apiClient
          .patch('${ApiEndpoints.reports}/$id', body: {'action': action});
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
      appBar: AppBar(
        title: const Text('Administração'),
        backgroundColor: AppTokens.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Instituições'),
            Tab(text: 'Denúncias'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [_institutionsTab(), _reportsTab()],
            ),
    );
  }

  Widget _institutionsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _createInstitution,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar IES'),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _institutions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final inst = _institutions[i];
                final domains = (inst['domains'] as List? ?? const [])
                    .cast<String>()
                    .join(', ');
                return ListTile(
                  title: Text(inst['name']?.toString() ?? ''),
                  subtitle: Text(domains),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editDomains(inst),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportsTab() {
    if (_reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Nenhuma denúncia pendente.'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = _reports[i];
          return ListTile(
            title: Text(
                '${r['targetType']} · ${r['reason']}'.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(r['description']?.toString() ??
                'ID alvo: ${r['targetId']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Resolver',
                  onPressed: () => _resolveReport(r['id'].toString(), 'resolve'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTokens.error),
                  tooltip: 'Descartar',
                  onPressed: () =>
                      _resolveReport(r['id'].toString(), 'dismiss'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
