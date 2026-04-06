import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../notifiers/profile_notifier.dart';

class EditProfileScreen extends StatefulWidget {
  final User profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Skills ainda são buscadas diretamente — não pertencem ao ProfileNotifier
  final ProfileRepository _profileRepo = sl.profileRepo;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _courseCtrl;
  int? _period;
  String _privacyLevel = 'local_only';
  bool _isLoading = false;
  List<Skill> _allSkills = [];
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
    _nameCtrl = TextEditingController(text: p.fullName);
    _bioCtrl = TextEditingController(text: p.bio ?? '');
    _courseCtrl = TextEditingController(text: p.course ?? '');
    _period = p.period;
    _privacyLevel = p.privacyLevel;
    _selectedSkillIds = p.skills.map((s) => s.id).toSet();

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
      await context.read<ProfileNotifier>().update({
        'full_name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'course': _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
        'period': _period,
        'privacy_level': _privacyLevel,
        'skill_ids': _selectedSkillIds.toList(),
      });
      if (!mounted) return;
      context.pop();
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

          const SizedBox(height: 20),

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
                final selected = _selectedSkillIds.contains(s.id);
                return FilterChip(
                  label: Text(s.name),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedSkillIds.add(s.id);
                    } else {
                      _selectedSkillIds.remove(s.id);
                    }
                  }),
                  selectedColor: AppTokens.primaryContainer,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
