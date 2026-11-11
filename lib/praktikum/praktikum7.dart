import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import '../generated/sensor.pb.dart';
import '../services/grpc_sensor_service.dart';

class Praktikum7 extends StatefulWidget {
  const Praktikum7({super.key});

  @override
  State<Praktikum7> createState() => _Praktikum7State();
}

class _Praktikum7State extends State<Praktikum7> {
  final GrpcSensorService _sensorService = GrpcSensorService();
  final TextEditingController _hostController = TextEditingController(
    text: defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '50051',
  );
  final TextEditingController _deviceIdController = TextEditingController(
    text: 'sensor-01',
  );

  StreamSubscription<SensorReading>? _subscription;
  SensorReading? _reading;
  String _status = 'Belum terhubung';
  String? _errorMessage;
  bool _isLoading = false;
  bool _streamFailed = false;

  bool get _isStreaming => _subscription != null;

  int? get _port {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) return null;
    return port;
  }

  bool _validateInput() {
    if (_hostController.text.trim().isEmpty ||
        _deviceIdController.text.trim().isEmpty ||
        _port == null) {
      setState(() {
        _errorMessage = 'Host, port, dan Device ID harus diisi dengan benar.';
      });
      return false;
    }
    return true;
  }

  Future<void> _getLatest() async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _status = 'Mengambil data...';
    });

    try {
      final reading = await _sensorService.getLatest(
        host: _hostController.text.trim(),
        port: _port!,
        deviceId: _deviceIdController.text.trim(),
      );
      if (!mounted) return;

      setState(() {
        _reading = reading;
        _status = 'Data terbaru diterima';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Gagal mengambil data gRPC: $error\n'
            'Pastikan backend aktif dengan perintah "go run ./server" '
            'di folder grpc_backend, lalu periksa host dan port.';
        _status = 'Koneksi gagal';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startStreaming() {
    if (!_validateInput()) return;

    setState(() {
      _errorMessage = null;
      _streamFailed = false;
      _status = 'Menghubungkan... menunggu data pertama (maksimal 10 detik)';
    });

    _subscription = _sensorService
        .watchSensor(
          host: _hostController.text.trim(),
          port: _port!,
          deviceId: _deviceIdController.text.trim(),
        )
        .listen(
          (reading) {
            if (!mounted) return;
            setState(() {
              _reading = reading;
              _status = 'Streaming aktif';
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _subscription = null;
              _streamFailed = true;
              _errorMessage =
                  'Streaming gRPC gagal: $error\n'
                  'Pastikan backend aktif dengan perintah "go run ./server" '
                  'di folder grpc_backend, lalu periksa host dan port.';
              _status = 'Koneksi gagal';
            });
          },
          onDone: () {
            if (!mounted) return;
            setState(() {
              _subscription = null;
              if (!_streamFailed) {
                _status = 'Streaming selesai';
              }
            });
          },
        );
  }

  Future<void> _stopStreaming() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();

    if (!mounted) return;
    setState(() {
      _status = 'Streaming dihentikan';
    });
  }

  @override
  void dispose() {
    final subscription = _subscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _hostController.dispose();
    _portController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputEnabled = !_isStreaming && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum 7 - gRPC'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Monitoring Sensor',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pastikan server gRPC berjalan di folder grpc_backend dengan '
            '"go run ./server". Android Emulator memakai 10.0.2.2; '
            'desktop memakai 127.0.0.1. Untuk perangkat fisik, masukkan '
            'alamat IP komputer server.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _hostController,
            enabled: inputEnabled,
            decoration: const InputDecoration(
              labelText: 'Host backend',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dns),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            enabled: inputEnabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lan),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceIdController,
            enabled: inputEnabled,
            decoration: const InputDecoration(
              labelText: 'Device ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sensors),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.circle,
                color: _isStreaming ? Colors.green : Colors.grey,
              ),
              title: const Text('Status gRPC'),
              subtitle: Text(_status),
            ),
          ),
          if (_reading != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.thermostat, color: Colors.orange),
                title: Text('Sensor ${_reading!.deviceId}'),
                subtitle: Text(
                  'Diperbarui: ${DateTime.fromMillisecondsSinceEpoch(_reading!.timestamp.toInt() * 1000).toLocal()}',
                ),
                trailing: Text(
                  '${_reading!.value.toStringAsFixed(2)} °C',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading || _isStreaming ? null : _getLatest,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: const Text('Ambil Data Terbaru'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isStreaming ? null : _startStreaming,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mulai Streaming'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isStreaming ? _stopStreaming : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Streaming'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
