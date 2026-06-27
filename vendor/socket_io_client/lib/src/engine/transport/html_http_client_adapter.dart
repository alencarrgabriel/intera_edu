// Stub web adapter — não compilado em build mobile.
import 'http_client_adapter.dart';

class HtmlHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<dynamic> connect(String uri, {Map<String, dynamic>? headers}) {
    throw UnsupportedError('HtmlHttpClientAdapter não suportado em mobile');
  }
}

HttpClientAdapter makePlatformHttpClientAdapter() {
  return HtmlHttpClientAdapter();
}
