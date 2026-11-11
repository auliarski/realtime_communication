import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(
  String broker,
  String clientIdentifier, {
  required int port,
}) {
  return MqttBrowserClient('ws://$broker/mqtt', clientIdentifier)
    ..port = 8000
    ..setProtocolV311()
    ..websocketProtocols = MqttClientConstants.protocolsSingleDefault;
}
