
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SseService {
  http.Client? _client;
  StreamSubscription<String>? _subscription;

  bool _isRunning = false;

  // Alamat server.
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    return 'http://10.0.2.2:3000';
  }

  // Memulai koneksi SSE.
  Future<void> connect({
    required Function(Map<String, dynamic>) onData,
    required Function(String) onError,
    required Function() onConnected,
    required Function() onDisconnected,
  }) async {
    if (_isRunning) return;

    _isRunning = true;

    final client = http.Client();
    _client = client;

    try {
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/api/events'),
      );

      request.headers['Accept'] = 'text/event-stream';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Koneksi SSE gagal: ${response.statusCode}',
        );
      }

      if (!_isRunning) return;

      onConnected();

      StringBuffer dataBuffer = StringBuffer();

      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          // Baris kosong menandakan akhir satu event.
          if (line.isEmpty) {
            final rawData = dataBuffer.toString().trim();

            if (rawData.isNotEmpty) {
              try {
                final decoded = jsonDecode(rawData);

                if (decoded is Map<String, dynamic> &&
                    decoded.isNotEmpty) {
                  onData(decoded);
                }
              } catch (e) {
                onError('Gagal membaca data SSE: $e');
              }
            }

            dataBuffer = StringBuffer();
          }

          // Mengambil isi data dari event SSE.
          else if (line.startsWith('data:')) {
            final value = line.substring(5).trim();

            if (dataBuffer.isNotEmpty) {
              dataBuffer.write('\n');
            }

            dataBuffer.write(value);
          }
        },
        onError: (error) {
          if (!_isRunning) return;

          _isRunning = false;
          onError('Koneksi SSE terputus: $error');
          onDisconnected();
        },
        onDone: () {
          if (!_isRunning) return;

          _isRunning = false;
          onDisconnected();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (_isRunning) {
        _isRunning = false;
        onError('Tidak dapat terhubung ke server: $e');
        onDisconnected();
      }
    }
  }

  // Menghentikan koneksi SSE.
  Future<void> disconnect() async {
    _isRunning = false;

    await _subscription?.cancel();
    _subscription = null;

    _client?.close();
    _client = null;
  }
}
