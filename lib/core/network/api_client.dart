import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  final String baseUrl;
  final SecureStorageService _storage = SecureStorageService();

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers())
        .timeout(AppConfig.receiveTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(AppConfig.receiveTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.patch(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(AppConfig.receiveTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(uri, headers: await _headers())
        .timeout(AppConfig.receiveTimeout);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : {'error': {'message': 'Unknown error', 'status': response.statusCode}};

    throw ApiException(
      statusCode: response.statusCode,
      message: errorBody['error']?['message'] ?? 'Request failed',
      code: errorBody['error']?['code'] ?? 'UNKNOWN',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String code;

  ApiException({required this.statusCode, required this.message, required this.code});

  @override
  String toString() => 'ApiException($statusCode): [$code] $message';
}
