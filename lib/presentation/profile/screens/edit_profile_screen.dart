import 'package:flutter/material.dart';
import '../../../data/repositories/profile_repository_impl.dart';
import '../../../domain/repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepositoryImpl();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _courseCtrl;
  int? _period;
  String _privacyLevel = 'local_only';
  bool _isLoading = false;
  List<Map<String, dynamic>> _allSkills = [];
  Set<String> _selectedSkillIds = {};
  bool _loadingSkills = true;

  static const _privacyOptions = [
    ('public', '🌎 Público'),
    ('local_only', '🏫 Somente minha instituição'),
    ('private', '🔒 Privado (apenas conexões)'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p['full_name']?.toString() ?? '');
    _bioCtrl = TextEditingController(text: p['bio']?.toString() ?? '');
    _courseCtrl = TextEditingController(text: p['course']?.toString() ?? '');
    _period = p['period'] as int?;
    _privacyLevel = p['privacy_level']?.toString() ?? 'local_only';

    final currentSkills = (p['skills'] as List<dynamic>? ?? []);
    _selectedSkillIds = currentSkills
        .map((s) => (s['id'] as String))
        .toSet();

    _loadSkills();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await _profileRepo.getSkills();
      setState(() {
        _allSkills = skills;
        _loadingSkills = false;
      });
    } catch (_) {
      setState(() => _loadingSkills = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome é obrigatório')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _profileRepo.updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'course': _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
        'period': _period,
        'privacy_level': _privacyLevel,
        'skill_ids': _selectedSkillIds.toList(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nome
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome Completo *',
              prefixIcon: Icon(Icons.person_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          TextFormField(
            controller: _bioCtrl,
            decoration: const InputDecoration(
              labelText: 'Sobre você',
              prefixIcon: Icon(Icons.info_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 300,
          ),
          const SizedBox(height: 8),

          // Curso
          TextFormField(
            controller: _courseCtrl,
            decoration: const InputDecoration(
              labelText: 'Curso',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Período
          DropdownButtonFormField<int>(
            value: _period,
            decoration: const InputDecoration(
              labelText: 'Período',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Não informar')),
              ...List.generate(12, (i) => i + 1)
                  .map((p) => DropdownMenuItem(value: p, child: Text('${p}º período'))),
            ],
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: 16),

          // Privacidade
          Text('Visibilidade do perfil',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._privacyOptions.map((opt) => RadioListTile<String>(
                title: Text(opt.$2),
                value: opt.$1,
                groupValue: _privacyLevel,
                onChanged: (v) => setState(() => _privacyLevel = v!),
                contentPadding: EdgeInsets.zero,
              )),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Habilidades
          Text('Habilidades',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_loadingSkills)
            const Center(child: CircularProgressIndicator())
          else if (_allSkills.isEmpty)
            const Text('Habilidades indisponíveis no momento.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allSkills.map((s) {
                final id = s['id'].toString();
                final selected = _selectedSkillIds.contains(id);
                return FilterChip(
                  label: Text(s['name'].toString()),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedSkillIds.add(id);
                    } else {
                      _selectedSkillIds.remove(id);
                    }
                  }),
                  selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
