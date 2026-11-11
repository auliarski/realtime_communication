import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_factory.dart';

class MqttService {
  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;
  static const String topic = 'kampus/demo/sensor01';

  MqttClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect({
    required Function(Map<String, dynamic>) onData,
    required Function(String) onStatus,
  }) async {
    if (_isConnected) return;

    final clientIdentifier =
        'realtime_comm_${DateTime.now().millisecondsSinceEpoch}';
    final client = createMqttClient(
      broker,
      clientIdentifier,
      port: port,
    );
    client
      ..logging(on: false)
      ..keepAlivePeriod = 20
      ..connectTimeoutPeriod = 10000
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientIdentifier)
          .startClean()
      ..onDisconnected = () {
        _isConnected = false;
        if (identical(_client, client)) {
          onStatus('MQTT terputus');
        }
      };

    onStatus('Menghubungkan ke broker MQTT...');

    try {
      final connectionStatus = await client.connect().timeout(
        const Duration(seconds: 15),
      );

      if (connectionStatus?.state != MqttConnectionState.connected) {
        throw StateError(
          'Broker menolak koneksi: ${connectionStatus?.returnCode}',
        );
      }

      _client = client;
      _isConnected = true;
      client.subscribe(topic, MqttQos.atLeastOnce);

      _updates = client.updates?.listen((messages) {
        for (final message in messages) {
          final publishMessage = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message,
          );

          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) {
              onData(decoded);
            }
          } on FormatException {
            onStatus('Data MQTT tidak berformat JSON yang valid');
          }
        }
      });

      onStatus('Terhubung ke broker MQTT');
    } catch (error) {
      _isConnected = false;
      if (identical(_client, client)) _client = null;
      client.disconnect();
      onStatus('Koneksi MQTT gagal: $error');
      rethrow;
    }
  }

  void publish(double temperature) {
    final client = _client;
    if (!_isConnected || client == null) {
      throw StateError('Belum terhubung ke broker MQTT');
    }

    final builder = MqttClientPayloadBuilder()
      ..addString(
        jsonEncode({
          'temperature': temperature,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _isConnected = false;
    final client = _client;
    _client = null;
    final updates = _updates;
    _updates = null;
    if (updates != null) unawaited(updates.cancel());
    client?.disconnect();
  }
}
