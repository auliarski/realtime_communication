// This is a generated file - do not edit.
//
// Generated from sensor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Request dari client
class SensorRequest extends $pb.GeneratedMessage {
  factory SensorRequest({
    $core.String? deviceId,
  }) {
    final result = SensorRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  SensorRequest._();

  factory SensorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SensorRequest()..mergeFromBuffer(data, registry);
  factory SensorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SensorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'monitoring'),
      createEmptyInstance: SensorRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorRequest copyWith(void Function(SensorRequest) updates) =>
      super.copyWith((message) => updates(message as SensorRequest))
          as SensorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SensorRequest() / SensorRequest.new instead')
  static SensorRequest create() => SensorRequest._();
  static $pb.GeneratedMessage $_createMessage() => SensorRequest._();
  @$core.override
  SensorRequest createEmptyInstance() => SensorRequest._();
  @$core.pragma('dart2js:noInline')
  static SensorRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SensorRequest>(
          SensorRequest.$_createMessage);
  static SensorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

/// Data pembacaan sensor
class SensorReading extends $pb.GeneratedMessage {
  factory SensorReading({
    $core.String? deviceId,
    $core.double? value,
    $fixnum.Int64? timestamp,
  }) {
    final result = SensorReading._();
    if (deviceId != null) result.deviceId = deviceId;
    if (value != null) result.value = value;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  SensorReading._();

  factory SensorReading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SensorReading()..mergeFromBuffer(data, registry);
  factory SensorReading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SensorReading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorReading',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'monitoring'),
      createEmptyInstance: SensorReading.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aD(2, _omitFieldNames ? '' : 'value')
    ..aInt64(3, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorReading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorReading copyWith(void Function(SensorReading) updates) =>
      super.copyWith((message) => updates(message as SensorReading))
          as SensorReading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SensorReading() / SensorReading.new instead')
  static SensorReading create() => SensorReading._();
  static $pb.GeneratedMessage $_createMessage() => SensorReading._();
  @$core.override
  SensorReading createEmptyInstance() => SensorReading._();
  @$core.pragma('dart2js:noInline')
  static SensorReading getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SensorReading>(
          SensorReading.$_createMessage);
  static SensorReading? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get value => $_getN(1);
  @$pb.TagNumber(2)
  set value($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
