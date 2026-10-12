import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intera_edu/core/auth/auth_notifier.dart';
import 'package:intera_edu/core/storage/secure_storage.dart';
import 'package:intera_edu/domain/repositories/auth_repository.dart';

String token(String id, int exp) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({
      'sub': id,
      'exp': exp,
      'roles': ['admin'],
    })))}.signature';

class SessionRepository implements AuthRepository {
  int refreshes = 0;
  @override
  Future<void> refreshToken() async {
    refreshes++;
    await SecureStorageService().saveTokens(
      accessToken: token('renewed', 4102444800),
      refreshToken: 'rotated',
    );
  }

  @override
  Future<void> logout() => SecureStorageService().clearTokens();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final access in [null, token('expired', 1), 'invalid']) {
    test('restaura identidade após renovar token: $access', () async {
      FlutterSecureStorage.setMockInitialValues({
        if (access != null) 'access_token': access,
        'refresh_token': 'refresh',
      });
      final repo = SessionRepository();
      final notifier = AuthNotifier(authRepo: repo);
      await notifier.checkSession();
      expect(repo.refreshes, 1);
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.userId, 'renewed');
      expect(notifier.isAdmin, isTrue);
      await notifier.logout();
      expect(notifier.userId, isNull);
      expect(notifier.roles, isEmpty);
      notifier.dispose();
    });
  }
  test('token inválido sem refresh não autentica', () async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'invalid'});
    final notifier = AuthNotifier(authRepo: SessionRepository());
    await notifier.checkSession();
    expect(notifier.isAuthenticated, isFalse);
    expect(await SecureStorageService().getAccessToken(), isNull);
    notifier.dispose();
  });
}
