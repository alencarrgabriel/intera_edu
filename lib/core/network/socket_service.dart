import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

/// Manages the Socket.IO connection to the messaging-service WebSocket gateway.
/// Exposes a broadcast stream of incoming messages so any listener can react.
class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _connected = false;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  bool get connected => _connected;
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;

  void connect(String accessToken) {
    if (_socket != null && _connected) return;

    final wsUrl = AppConfig.wsBaseUrl;

    _socket = io.io(
      '$wsUrl/ws',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .enableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _connected = true;
        notifyListeners();
        debugPrint('[SocketService] Connected to $wsUrl');
      })
      ..onDisconnect((_) {
        _connected = false;
        notifyListeners();
        debugPrint('[SocketService] Disconnected');
      })
      ..on('message:new', (data) {
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('typing:indicator', (data) {
        if (data is Map) {
          _typingController.add(Map<String, dynamic>.from(data));
        }
      })
      ..onError((err) => debugPrint('[SocketService] Error: $err'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    notifyListeners();
  }

  void sendMessage(String chatId, String content) {
    _socket?.emit('message:send', {'chatId': chatId, 'content': content});
  }

  void emitTyping(String chatId, {required bool isTyping}) {
    _socket?.emit(
      isTyping ? 'typing:start' : 'typing:stop',
      {'chatId': chatId},
    );
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    super.dispose();
  }
}
