
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  late MqttBrowserClient client;

  static const String topic = 'kampus/demo/sensor01';

  bool get isConnected =>
      client.connectionStatus?.state ==
      MqttConnectionState.connected;

  Future<void> connect({
    required Function(Map<String, dynamic>) onData,
    required Function(String) onStatus,
  }) async {
    final clientId =
        'flutter_${DateTime.now().millisecondsSinceEpoch}';

    // Host dan path WebSocket HiveMQ
    client = MqttBrowserClient(
      'ws://broker.hivemq.com/mqtt',
      clientId,
    );

    // Port WebSocket HiveMQ
    client.port = 8000;

    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 10000;

    // Konfigurasi protokol MQTT
    client.setProtocolV311();

    // Subprotocol WebSocket
    client.websocketProtocols =
        MqttClientConstants.protocolsSingleDefault;

    client.onConnected = () {
      onStatus('Terhubung ke broker MQTT');
    };

    client.onDisconnected = () {
      onStatus('Terputus dari broker MQTT');
    };

    client.onSubscribed = (topic) {
      onStatus('Berhasil subscribe: $topic');
    };

    // Clean session
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      onStatus('Menghubungkan ke broker...');

      await client.connect();

      if (client.connectionStatus?.state !=
          MqttConnectionState.connected) {
        throw Exception(
          'Broker menolak koneksi: ${client.connectionStatus}',
        );
      }

      // Subscribe ke topik sensor
      client.subscribe(topic, MqttQos.atMostOnce);

      client.updates?.listen((events) {
        for (final event in events) {
          final publish =
              event.payload as MqttPublishMessage;

          final message =
              MqttPublishPayload.bytesToStringAsString(
            publish.payload.message,
          );

          try {
            final data = jsonDecode(message);

            if (data is Map<String, dynamic>) {
              onData(data);
            }
          } catch (e) {
            onStatus('Gagal membaca pesan: $e');
          }
        }
      });

      onStatus('MQTT berhasil terhubung');
    } catch (e) {
      client.disconnect();
      onStatus('Koneksi gagal: $e');
      rethrow;
    }
  }

  void publish(double temperature) {
    if (!isConnected) {
      throw Exception('MQTT belum terhubung');
    }

    final builder = MqttClientPayloadBuilder();

    builder.addString(jsonEncode({
      'temperature': temperature,
      'timestamp': DateTime.now().toIso8601String(),
    }));

    client.publishMessage(
      topic,
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    if (isConnected) {
      client.disconnect();
    }
  }
}
