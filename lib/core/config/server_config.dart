import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';

/// Configuração de servidor — permite que o APK aceite qualquer host
/// sem ser recompilado. O usuário define a URL na primeira abertura ou
/// pelo menu "Configurar servidor".
///
/// Armazena o host base (ex. `http://192.168.1.9`). Derivamos:
///   apiBaseUrl  = `<host>:3000/api/v1`
///   wsBaseUrl   = `<host>:3004`
///
/// Se nada foi configurado, cai no `AppConfig.apiBaseUrl` da build.
class ServerConfig extends ChangeNotifier {
  ServerConfig._();
  static final ServerConfig instance = ServerConfig._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'custom_server_host';

  String? _customHost;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// `true` quando o usuário ainda não definiu nenhum host E nenhuma URL
  /// foi embutida via --dart-define (build com URL fixa não precisa de setup).
  bool get needsSetup =>
      _initialized &&
      (_customHost == null || _customHost!.isEmpty) &&
      AppConfig.apiBaseUrl == 'http://localhost:3000/api/v1';

  String get customHost => _customHost ?? '';

  String get apiBaseUrl {
    final host = _customHost;
    if (host != null && host.isNotEmpty) return '$host:3000/api/v1';
    return AppConfig.apiBaseUrl;
  }

  String get wsBaseUrl {
    final host = _customHost;
    if (host != null && host.isNotEmpty) return '$host:3004';
    return AppConfig.wsBaseUrl;
  }

  Future<void> init() async {
    try {
      _customHost = await _storage.read(key: _key);
    } catch (_) {
      _customHost = null;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setHost(String input) async {
    final host = _normalize(input);
    await _storage.write(key: _key, value: host);
    _customHost = host;
    notifyListeners();
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    _customHost = null;
    notifyListeners();
  }

  /// Testa o endpoint de health do gateway. Retorna `null` se OK,
  /// ou string com motivo do erro.
  Future<String?> testHost(String input) async {
    final host = _normalize(input);
    if (host.isEmpty) return 'Endereço vazio.';
    try {
      final uri = Uri.parse('$host:3000/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode >= 200 && res.statusCode < 500) return null;
      return 'Servidor respondeu HTTP ${res.statusCode}.';
    } catch (e) {
      return 'Não foi possível alcançar $host.';
    }
  }

  /// Normaliza: aceita `192.168.1.9`, `http://192.168.1.9`, `192.168.1.9:3000`
  /// e retorna sempre `http://192.168.1.9` (sem porta).
  String _normalize(String raw) {
    var input = raw.trim();
    if (input.isEmpty) return '';
    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      input = 'http://$input';
    }
    final uri = Uri.tryParse(input);
    if (uri == null || uri.host.isEmpty) return input;
    return '${uri.scheme}://${uri.host}';
  }
}
