import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Callback chamado quando o refresh de token falha (ex: refresh expirado).
typedef OnForceLogout = void Function();

class ApiClient {
  final String baseUrl;
  final SecureStorageService _storage = SecureStorageService();
  OnForceLogout? onForceLogout;

  /// Flag para evitar múltiplos refreshes simultâneos
  bool _isRefreshing = false;

  ApiClient({String? baseUrl, this.onForceLogout})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<Map<String, String>> _headers({String? overrideToken}) async {
    final token = overrideToken ?? await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    final response =
        await http.get(uri, headers: await _headers()).timeout(AppConfig.receiveTimeout);
    return _handleResponse(response, () => get(endpoint, queryParams: queryParams));
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .post(uri,
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null)
        .timeout(AppConfig.receiveTimeout);
    return _handleResponse(response, () => post(endpoint, body: body));
  }

  Future<Map<String, dynamic>> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .patch(uri,
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null)
        .timeout(AppConfig.receiveTimeout);
    return _handleResponse(response, () => patch(endpoint, body: body));
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response =
        await http.delete(uri, headers: await _headers()).timeout(AppConfig.receiveTimeout);
    return _handleResponse(response, () => delete(endpoint));
  }

  Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
    Future<Map<String, dynamic>> Function() retry,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Token expirado — tentar refresh automático
    if (response.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return retry(); // Retentar a requisição original com o novo token
      } else {
        onForceLogout?.call();
        throw ApiException(
          statusCode: 401,
          message: 'Sessão expirada. Faça login novamente.',
          code: 'SESSION_EXPIRED',
        );
      }
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : {'error': {'message': 'Erro desconhecido', 'status': response.statusCode}};

    throw ApiException(
      statusCode: response.statusCode,
      message: errorBody['error']?['message'] ?? 'Requisição falhou',
      code: errorBody['error']?['code'] ?? 'UNKNOWN',
    );
  }

  /// Tenta renovar o access token usando o refresh token armazenado.
  /// Retorna true se o refresh foi bem-sucedido.
  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tokens = data['tokens'] as Map<String, dynamic>;
        await _storage.saveTokens(
          accessToken: tokens['access_token'] as String,
          refreshToken: tokens['refresh_token'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String code;

  ApiException(
      {required this.statusCode, required this.message, required this.code});

  @override
  String toString() => 'ApiException($statusCode): [$code] $message';
}
