import 'package:flutter/material.dart';
import '../../../data/repositories/feed_repository_impl.dart';
import '../../../domain/repositories/feed_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final FeedRepository _feedRepo = FeedRepositoryImpl();
  String _scope = 'local';
  bool _isLoading = false;
  static const int _maxChars = 1000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _feedRepo.createPost(content: content, scope: _scope);
      if (!mounted) return;
      // Retorna true para que o FeedScreen saiba que deve recarregar
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
    final remaining = _maxChars - _controller.text.length;
    final canPublish = _controller.text.trim().isNotEmpty && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Publicação'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: canPublish ? _handlePublish : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Seletor de escopo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visibilidade',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'local',
                        icon: Icon(Icons.school_outlined),
                        label: Text('Minha instituição'),
                      ),
                      ButtonSegment(
                        value: 'global',
                        icon: Icon(Icons.public_outlined),
                        label: Text('Todas as instituições'),
                      ),
                    ],
                    selected: {_scope},
                    onSelectionChanged: (s) =>
                        setState(() => _scope = s.first),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Campo de texto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  maxLength: _maxChars,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'No que você está trabalhando?\nCompartilhe um projeto, dúvida ou conquista...',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // Contador de caracteres
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$remaining',
                    style: TextStyle(
                      color: remaining < 100
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ' / $_maxChars',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
