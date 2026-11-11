
import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String url = 'ws://10.0.2.2:3000';

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect({
    required Function(Map<String, dynamic>) onData,
    required Function(String) onError,
    required Function() onConnected,
    required Function() onDisconnected,
  }) async {
    if (_channel != null) return;

    final channel = IOWebSocketChannel.connect(
      Uri.parse(url),
      connectTimeout: const Duration(seconds: 10),
    );
    _channel = channel;

    try {
      await channel.ready;
      _isConnected = true;
      onConnected();

      _subscription = channel.stream.listen(
        (dynamic rawData) {
          try {
            final decoded = jsonDecode(rawData as String);
            if (decoded is Map) {
              onData(Map<String, dynamic>.from(decoded));
            }
          } catch (error) {
            onError('Data WebSocket tidak valid: $error');
          }
        },
        onError: (Object error) {
          _isConnected = false;
          _channel = null;
          onError(error.toString());
        },
        onDone: () {
          _isConnected = false;
          _channel = null;
          _subscription = null;
          onDisconnected();
        },
      );
    } catch (error) {
      _isConnected = false;
      _channel = null;
      onError('Tidak dapat terhubung ke $url: $error');
      await channel.sink.close();
    }
  }

  void sendMessage(String message) {
    final channel = _channel;
    if (!_isConnected || channel == null) {
      throw StateError('WebSocket belum terhubung');
    }

    channel.sink.add(jsonEncode({'message': message}));
  }

  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null;
    _isConnected = false;

    await _subscription?.cancel();
    _subscription = null;
    await channel?.sink.close();
  }
}
