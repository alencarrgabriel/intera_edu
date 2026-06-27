// Polling transport — stubbed em build mobile.
// O socket_io_client real usa esse arquivo só em build web (depende de
// XMLHttpRequest/window). Em Android/iOS a engine usa WebSocket nativo.
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:socket_io_client/src/engine/transport.dart';
import 'package:socket_io_common/src/util/event_emitter.dart';

final Logger _logger = Logger('socket_io:transport.PollingTransport');

class PollingTransport extends Transport {
  @override
  String? name = 'polling';
  bool polling = false;
  dynamic pollXhr;

  PollingTransport(Map opts) : super(opts) {
    _logger.warning('PollingTransport (web) não suportado em build mobile.');
  }

  @override
  void doOpen() {
    onError('Polling não suportado em mobile', null);
  }

  @override
  void doClose() {}

  @override
  void write(List packets) {}
}

class Request extends EventEmitter {
  Request(String uri, Map opts);
  void abort() {}
}
