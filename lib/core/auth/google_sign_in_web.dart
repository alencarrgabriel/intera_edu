import 'dart:async';

/// Bridge para o Google Identity Services. No build mobile (Android/iOS)
/// retorna sempre erro de não-configurado — o Sign-In nativo via SDK Google
/// não está habilitado para o APK de teste.
///
/// (Versão web original usava `dart:js_interop` para chamar
/// `window.interaeduGoogleSignIn()`. Aqui é stub para evitar o bug do depfile
/// writer no Dart 3.10-3.12 quando o symbol está presente em qualquer caminho
/// transitivamente importado pelo `main.dart`.)
Future<String> fetchGoogleIdToken() async {
  throw const GoogleSignInNotConfigured();
}

class GoogleSignInNotConfigured implements Exception {
  const GoogleSignInNotConfigured();
  @override
  String toString() =>
      'Login com Google não disponível neste build. Use email + OTP.';
}

class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
  @override
  String toString() => 'Login com Google cancelado.';
}
