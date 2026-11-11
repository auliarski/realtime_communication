// This is a generated file - do not edit.
//
// Generated from sensor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sensor.pb.dart' as $0;

export 'sensor.pb.dart';

/// Layanan komunikasi sensor
@$pb.GrpcServiceName('monitoring.SensorService')
class SensorServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SensorServiceClient(super.channel, {super.options, super.interceptors});

  /// Unary RPC: satu request, satu response
  $grpc.ResponseFuture<$0.SensorReading> getLatest(
    $0.SensorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getLatest, request, options: options);
  }

  /// Server Streaming: satu request, banyak response
  $grpc.ResponseStream<$0.SensorReading> watchSensor(
    $0.SensorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchSensor, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getLatest =
      $grpc.ClientMethod<$0.SensorRequest, $0.SensorReading>(
          '/monitoring.SensorService/GetLatest',
          ($0.SensorRequest value) => value.writeToBuffer(),
          $0.SensorReading.fromBuffer);
  static final _$watchSensor =
      $grpc.ClientMethod<$0.SensorRequest, $0.SensorReading>(
          '/monitoring.SensorService/WatchSensor',
          ($0.SensorRequest value) => value.writeToBuffer(),
          $0.SensorReading.fromBuffer);
}

@$pb.GrpcServiceName('monitoring.SensorService')
abstract class SensorServiceBase extends $grpc.Service {
  $core.String get $name => 'monitoring.SensorService';

  SensorServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SensorRequest, $0.SensorReading>(
        'GetLatest',
        getLatest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SensorRequest.fromBuffer(value),
        ($0.SensorReading value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SensorRequest, $0.SensorReading>(
        'WatchSensor',
        watchSensor_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.SensorRequest.fromBuffer(value),
        ($0.SensorReading value) => value.writeToBuffer()));
  }

  $async.Future<$0.SensorReading> getLatest_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SensorRequest> $request) async {
    return getLatest($call, await $request);
  }

  $async.Future<$0.SensorReading> getLatest(
      $grpc.ServiceCall call, $0.SensorRequest request);

  $async.Stream<$0.SensorReading> watchSensor_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SensorRequest> $request) async* {
    yield* watchSensor($call, await $request);
  }

  $async.Stream<$0.SensorReading> watchSensor(
      $grpc.ServiceCall call, $0.SensorRequest request);
}
