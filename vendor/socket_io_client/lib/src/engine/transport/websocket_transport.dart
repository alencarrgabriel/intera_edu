// Web WebSocket transport — stubbed em build mobile.
// O socket_io_client real usa esse arquivo só em build web; no Android/iOS
// a engine usa IO/native sockets.
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:socket_io_client/src/engine/transport.dart';

class WebSocketTransport extends Transport {
  static final Logger _logger =
      Logger('socket_io_client:transport.WebSocketTransport');

  @override
  String? name = 'websocket';

  WebSocketTransport(Map opts) : super(opts) {
    _logger.warning('WebSocketTransport (web) não suportado em build mobile.');
  }

  @override
  void doOpen() {
    onError('Mobile build não usa WebSocketTransport web', null);
  }

  @override
  void doClose() {}

  @override
  void write(List packets) {}
}
