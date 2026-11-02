
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Menentukan alamat server.
  String get serverUrl {
    if (kIsWeb) {
      return 'ws://localhost:3000';
    }

    return 'ws://10.0.2.2:3000';
  }

  // Membuat koneksi WebSocket.
  Future<void> connect({
    required Function(Map<String, dynamic>) onData,
    required Function(String) onError,
    required Function() onConnected,
    required Function() onDisconnected,
  }) async {
    if (_isConnected) return;

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(serverUrl),
      );

      _channel = channel;

      await channel.ready;

      _isConnected = true;
      onConnected();

      channel.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message.toString());

            if (decoded is Map<String, dynamic>) {
              onData(decoded);
            }
          } catch (e) {
            onError('Gagal membaca pesan: $e');
          }
        },
        onError: (error) {
          _isConnected = false;
          _channel = null;
          onError('Koneksi WebSocket error: $error');
          onDisconnected();
        },
        onDone: () {
          _isConnected = false;
          _channel = null;
          onDisconnected();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      _channel = null;
      onError('Gagal menghubungkan ke server: $e');
      onDisconnected();
    }
  }

  // Mengirim pesan ke server.
  void sendMessage(String message) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket belum terhubung');
    }

    _channel!.sink.add(
      jsonEncode({
        'message': message,
      }),
    );
  }

  // Memutus koneksi.
  Future<void> disconnect() async {
    _isConnected = false;

    final channel = _channel;
    _channel = null;

    await channel?.sink.close();
  }
}
