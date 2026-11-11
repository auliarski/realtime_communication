import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(
  String broker,
  String clientIdentifier, {
  required int port,
}) {
  return MqttServerClient.withPort(broker, clientIdentifier, port);
}
