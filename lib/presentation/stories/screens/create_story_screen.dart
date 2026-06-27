import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_snackbar.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _caption = TextEditingController();
  PlatformFile? _file;
  bool _uploading = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.media,
    );
    if (res == null || res.files.isEmpty) return;
    setState(() => _file = res.files.first);
  }

  Future<void> _send() async {
    final f = _file;
    if (f == null) {
      AppSnackbar.warning(context, 'Selecione uma imagem antes.');
      return;
    }
    if (f.bytes == null) {
      AppSnackbar.error(context, 'Não foi possível ler a imagem escolhida.');
      return;
    }
    if (f.bytes!.length > 25 * 1024 * 1024) {
      AppSnackbar.warning(context, 'Mídia maior que 25 MB. Escolha outra.');
      return;
    }
    setState(() => _uploading = true);
    try {
      await sl.storiesRepo.create(
        fileBytes: f.bytes!,
        filename: f.name,
        mimeType: _guessMime(f.extension),
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Story publicado!');
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _guessMime(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        title: const Text('Novo Story',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: AppTokens.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: AppTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(color: AppTokens.outlineVariant),
                ),
                child: _file == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 40,
                                color: AppTokens.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('Toque pra escolher uma imagem',
                                style: TextStyle(
                                    color: AppTokens.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(_file!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caption,
              decoration: const InputDecoration(
                hintText: 'Legenda (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _uploading || _file == null ? null : _send,
              child: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
