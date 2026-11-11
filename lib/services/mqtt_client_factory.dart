import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart' as platform;

MqttClient createMqttClient(
  String broker,
  String clientIdentifier, {
  required int port,
}) {
  return platform.createMqttClient(
    broker,
    clientIdentifier,
    port: port,
  );
}
