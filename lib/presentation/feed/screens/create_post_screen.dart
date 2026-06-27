import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/repositories/feed_repository.dart';
import '../../shared/mention_autocomplete_field.dart';

class CreatePostScreen extends StatefulWidget {
  final String? groupId;
  const CreatePostScreen({super.key, this.groupId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final FeedRepository _feedRepo = sl.feedRepo;
  String _scope = 'local';
  bool _isLoading = false;
  PlatformFile? _attachment;
  String? _attachmentMime;
  static const int _maxChars = 1000;

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      AppSnackbar.warning(context, 'Arquivo maior que 10 MB.');
      return;
    }
    final ext = (f.extension ?? '').toLowerCase();
    setState(() {
      _attachment = f;
      _attachmentMime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => 'image/jpeg',
      };
    });
  }

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
      await _feedRepo.createPost(
        content: content,
        scope: _scope,
        groupId: widget.groupId,
        fileBytes: _attachment?.bytes,
        filename: _attachment?.name,
        mimeType: _attachmentMime,
      );
      if (!mounted) return;
      // Retorna true para que o FeedScreen saiba que deve recarregar
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
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

            const SizedBox(height: 16),

            // Campo de texto (com autocomplete de @menções)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MentionAutocompleteField(
                  controller: _controller,
                  maxLength: _maxChars,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText:
                        'No que você está trabalhando?\nUse @ pra mencionar, # pra tag.',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // Anexo (RF-16)
            if (_attachment != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded,
                        size: 18, color: AppTokens.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _attachment!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _attachment = null;
                        _attachmentMime = null;
                      }),
                    ),
                  ],
                ),
              ),

            // Toolbar: anexar + contador
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _isLoading ? null : _pickAttachment,
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Anexar'),
                  ),
                  const Spacer(),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      color: remaining < 100
                          ? AppTokens.error
                          : AppTokens.outline,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ' / $_maxChars',
                    style: const TextStyle(
                      color: AppTokens.outline,
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
