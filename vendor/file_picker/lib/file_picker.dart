/// Vendored minimal file_picker — apenas pra Android.
/// Usa image_picker por baixo. Sem dart:js_interop para evitar bug
/// do depfile writer no Dart 3.10-3.12.
library file_picker;

import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

enum FileType { any, media, image, video, audio, custom }

class PlatformFile {
  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
  final String? extension;

  PlatformFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
    this.extension,
  });
}

class FilePickerResult {
  final List<PlatformFile> files;
  FilePickerResult(this.files);
}

class FilePicker {
  static final FilePicker platform = FilePicker._();
  FilePicker._();

  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
  }) async {
    final picker = ImagePicker();
    XFile? picked;
    if (type == FileType.image ||
        (allowedExtensions != null &&
            allowedExtensions.every((e) =>
                ['jpg', 'jpeg', 'png', 'webp'].contains(e.toLowerCase())))) {
      picked = await picker.pickImage(source: ImageSource.gallery);
    } else if (type == FileType.video) {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    } else if (type == FileType.media) {
      picked = await picker.pickMedia();
    } else {
      // Para tipos genéricos (PDF, doc) caímos no picker de imagem:
      // Android padrão não tem document picker no image_picker.
      picked = await picker.pickImage(source: ImageSource.gallery);
    }
    if (picked == null) return null;
    final file = File(picked.path);
    final size = await file.length();
    final name = picked.name;
    final ext = name.contains('.') ? name.split('.').last : null;
    final bytes = withData ? await file.readAsBytes() : null;
    return FilePickerResult([
      PlatformFile(
        name: name,
        size: size,
        path: picked.path,
        bytes: bytes,
        extension: ext,
      ),
    ]);
  }
}
