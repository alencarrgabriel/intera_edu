import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intera_edu/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'refresh',
    });
  });

  test('login rejeitado preserva erro e não renova sessão', () async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://localhost',
      client: MockClient((r) async {
        calls++;
        return http.Response('{"message":"Credenciais inválidas"}', 401);
      }),
    );
    await expectLater(
      api.post('/auth/login'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Credenciais inválidas',
        ),
      ),
    );
    expect(calls, 1);
  });

  test('401 persistente repete requisição apenas uma vez', () async {
    var refreshes = 0;
    var requests = 0;
    final api = ApiClient(
      baseUrl: 'http://localhost',
      client: MockClient((r) async {
        if (r.url.path == '/auth/refresh') {
          refreshes++;
          return http.Response(
            jsonEncode({
              'tokens': {'access_token': 'new', 'refresh_token': 'rotated'},
            }),
            200,
          );
        }
        requests++;
        return http.Response('{"message":"Unauthorized"}', 401);
      }),
    );
    await expectLater(api.get('/feed'), throwsA(isA<ApiException>()));
    expect(refreshes, 1);
    expect(requests, 2);
  });

  for (final body in ['[]', 'null', '42', 'not json', '{"message":42}']) {
    test('erro com corpo inesperado é ApiException: $body', () async {
      final api = ApiClient(
        baseUrl: 'http://localhost',
        client: MockClient((r) async => http.Response(body, 500)),
      );
      await expectLater(api.get('/feed'), throwsA(isA<ApiException>()));
    });
  }
}
