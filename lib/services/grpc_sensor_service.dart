import 'dart:async';

import 'package:grpc/grpc.dart';

import '../generated/sensor.pbgrpc.dart';

class GrpcSensorService {
  Future<SensorReading> getLatest({
    required String host,
    required int port,
    required String deviceId,
  }) async {
    final channel = _createChannel(host, port);

    try {
      return await SensorServiceClient(channel).getLatest(
        SensorRequest(deviceId: deviceId),
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );
    } finally {
      await channel.shutdown();
    }
  }

  Stream<SensorReading> watchSensor({
    required String host,
    required int port,
    required String deviceId,
  }) async* {
    final channel = _createChannel(host, port);
    final responses = SensorServiceClient(channel).watchSensor(
      SensorRequest(deviceId: deviceId),
    );
    final iterator = StreamIterator<SensorReading>(responses);

    try {
      while (await iterator.moveNext().timeout(const Duration(seconds: 10))) {
        yield iterator.current;
      }
    } finally {
      await iterator.cancel();
      await channel.shutdown();
    }
  }

  ClientChannel _createChannel(String host, int port) {
    return ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
  }
}
