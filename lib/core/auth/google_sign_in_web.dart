import 'dart:async';
import 'dart:js_interop';

/// Bridge para o Google Identity Services injetado em `web/index.html`.
///
/// A função JS `window.interaeduGoogleSignIn()` devolve uma `Promise<String>`
/// com o ID Token. Aqui apenas convertemos para um `Future<String>` em Dart.
@JS('interaeduGoogleSignIn')
external JSPromise<JSString> _interaeduGoogleSignIn();

/// Wraps a chamada ao GIS para retornar um Future<String> com o ID token.
/// Lança [Exception] se o GIS não estiver configurado ou o usuário cancelar.
Future<String> fetchGoogleIdToken() async {
  try {
    final jsString = await _interaeduGoogleSignIn().toDart;
    return jsString.toDart;
  } catch (e) {
    // O erro vem como JS Error com message tipo 'NOT_CONFIGURED' | 'USER_DISMISSED' | etc.
    final raw = e.toString();
    if (raw.contains('NOT_CONFIGURED')) {
      throw const GoogleSignInNotConfigured();
    }
    if (raw.contains('USER_DISMISSED')) {
      throw const GoogleSignInCancelled();
    }
    throw Exception('Falha no login com Google: $raw');
  }
}

class GoogleSignInNotConfigured implements Exception {
  const GoogleSignInNotConfigured();
  @override
  String toString() =>
      'Configure o Google Client ID em web/index.html (meta google-signin-client_id) '
      'e a env GOOGLE_CLIENT_ID no auth-service.';
}

class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
  @override
  String toString() => 'Login com Google cancelado.';
}
