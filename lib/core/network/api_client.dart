import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/server_config.dart';
import '../storage/secure_storage.dart';

/// Callback chamado quando o refresh de token falha (ex: refresh expirado).
typedef OnForceLogout = void Function();

class ApiClient {
  /// Base URL fixa (passada na construção) — quando null, lemos sempre do
  /// `ServerConfig.instance.apiBaseUrl` no momento da requisição. Isso permite
  /// trocar de servidor em tempo de execução pelo `ServerSetupScreen`.
  final String? _fixedBaseUrl;
  final SecureStorageService _storage = SecureStorageService();
  OnForceLogout? onForceLogout;

  Completer<bool>? _refreshCompleter;

  ApiClient({String? baseUrl, this.onForceLogout}) : _fixedBaseUrl = baseUrl;

  String get baseUrl =>
      _fixedBaseUrl ?? ServerConfig.instance.apiBaseUrl;

  Future<Map<String, String>> _headers({String? overrideToken}) async {
    final token = overrideToken ?? await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(AppConfig.receiveTimeout);
      return _handleResponse(
          response, () => get(endpoint, queryParams: queryParams));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
          statusCode: 408,
          message: 'Tempo limite excedido. Verifique sua conexão.',
          code: 'TIMEOUT');
    } on SocketException {
      throw ApiException(
          statusCode: 0,
          message: 'Sem conexão com a internet.',
          code: 'NO_NETWORK');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(uri,
              headers: await _headers(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(AppConfig.receiveTimeout);
      return _handleResponse(response, () => post(endpoint, body: body));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
          statusCode: 408,
          message: 'Tempo limite excedido. Verifique sua conexão.',
          code: 'TIMEOUT');
    } on SocketException {
      throw ApiException(
          statusCode: 0,
          message: 'Sem conexão com a internet.',
          code: 'NO_NETWORK');
    }
  }

  Future<Map<String, dynamic>> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .patch(uri,
              headers: await _headers(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(AppConfig.receiveTimeout);
      return _handleResponse(response, () => patch(endpoint, body: body));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
          statusCode: 408,
          message: 'Tempo limite excedido. Verifique sua conexão.',
          code: 'TIMEOUT');
    } on SocketException {
      throw ApiException(
          statusCode: 0,
          message: 'Sem conexão com a internet.',
          code: 'NO_NETWORK');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .delete(uri, headers: await _headers())
          .timeout(AppConfig.receiveTimeout);
      return _handleResponse(response, () => delete(endpoint));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
          statusCode: 408,
          message: 'Tempo limite excedido. Verifique sua conexão.',
          code: 'TIMEOUT');
    } on SocketException {
      throw ApiException(
          statusCode: 0,
          message: 'Sem conexão com a internet.',
          code: 'NO_NETWORK');
    }
  }

  Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
    Future<Map<String, dynamic>> Function() retry,
  ) async {
    _log('${response.request?.method} ${response.request?.url} → ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // DELETE/PUT sem retorno: NestJS pode devolver "" (corpo vazio) ou
      // "\"\"" (string vazia serializada). Ambos significam sucesso sem payload.
      final body = response.body.trim();
      if (body.isEmpty || body == '""') return {};
      try {
        final decoded = jsonDecode(body);
        if (decoded == null) return {};
        if (decoded is Map<String, dynamic>) return decoded;
        // Resposta válida porém não é um objeto (ex.: lista raiz, string).
        // Empacotamos sob a chave "result" para o chamador não quebrar.
        return {'result': decoded};
      } on FormatException {
        throw ApiException(
            statusCode: 0,
            message: 'Resposta inválida do servidor.',
            code: 'INVALID_RESPONSE');
      }
    }

    // Token expirado — tentar refresh automático
    if (response.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return retry();
      } else {
        onForceLogout?.call();
        throw ApiException(
          statusCode: 401,
          message: 'Sessão expirada. Faça login novamente.',
          code: 'SESSION_EXPIRED',
        );
      }
    }

    // Extrair mensagem de erro no formato canônico ou no formato NestJS padrão
    throw _parseErrorBody(response.body, response.statusCode);
  }

  /// Suporta dois formatos de erro:
  /// 1. Formato canônico (gateway): `{ "error": { "code": "...", "message": "..." } }`
  /// 2. Formato NestJS padrão:      `{ "statusCode": 400, "message": "...", "error": "..." }`
  ApiException _parseErrorBody(String body, int statusCode) {
    if (body.isEmpty) {
      return ApiException(
          statusCode: statusCode,
          message: 'Requisição falhou.',
          code: 'HTTP_$statusCode');
    }

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Formato 1: canônico { error: { code, message } }
      final errorObj = json['error'];
      if (errorObj is Map<String, dynamic> && errorObj['code'] != null) {
        final msg = errorObj['message'] as String? ?? 'Erro desconhecido';
        final code = errorObj['code'] as String? ?? 'UNKNOWN';
        _log('Erro [$code]: $msg', isError: true);
        return ApiException(statusCode: statusCode, message: msg, code: code);
      }

      // Formato 2: NestJS padrão { statusCode, message, error }
      final raw = json['message'];
      final message = raw is List
          ? raw.join('; ')
          : (raw as String? ?? 'Requisição falhou.');
      final code = errorObj is String
          ? errorObj.toUpperCase().replaceAll(' ', '_')
          : 'HTTP_$statusCode';
      _log('Erro [$code]: $message', isError: true);
      return ApiException(statusCode: statusCode, message: message, code: code);
    } on FormatException {
      return ApiException(
          statusCode: statusCode,
          message: 'Requisição falhou.',
          code: 'HTTP_$statusCode');
    }
  }

  /// Tenta renovar o access token usando o refresh token armazenado.
  /// Usa Completer para coordenar requests concorrentes — se um refresh
  /// já está em andamento, as demais requisições aguardam o resultado.
  Future<bool> _tryRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

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
        _refreshCompleter!.complete(true);
        return true;
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  void _log(String message, {bool isError = false}) {
    if (!AppConfig.devMode) return;
    if (isError) {
      debugPrint('[ApiClient] ⚠ $message');
    } else {
      debugPrint('[ApiClient] $message');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String code;

  ApiException(
      {required this.statusCode, required this.message, required this.code});

  /// `toString()` retorna apenas a mensagem amigável ao usuário,
  /// pra ser seguro usar em SnackBars/Dialogs sem expor código interno.
  @override
  String toString() => message;
}
