// This is a generated file - do not edit.
//
// Generated from tempconv/v1/tempconv.proto.

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

import 'tempconv.pb.dart' as $0;

export 'tempconv.pb.dart';

/// TempConv converts between Celsius and Fahrenheit.
@$pb.GrpcServiceName('tempconv.v1.TempConv')
class TempConvClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TempConvClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.Value> celsiusToFahrenheit(
    $0.Value request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$celsiusToFahrenheit, request, options: options);
  }

  $grpc.ResponseFuture<$0.Value> fahrenheitToCelsius(
    $0.Value request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$fahrenheitToCelsius, request, options: options);
  }

  // method descriptors

  static final _$celsiusToFahrenheit = $grpc.ClientMethod<$0.Value, $0.Value>(
      '/tempconv.v1.TempConv/CelsiusToFahrenheit',
      ($0.Value value) => value.writeToBuffer(),
      $0.Value.fromBuffer);
  static final _$fahrenheitToCelsius = $grpc.ClientMethod<$0.Value, $0.Value>(
      '/tempconv.v1.TempConv/FahrenheitToCelsius',
      ($0.Value value) => value.writeToBuffer(),
      $0.Value.fromBuffer);
}

@$pb.GrpcServiceName('tempconv.v1.TempConv')
abstract class TempConvServiceBase extends $grpc.Service {
  $core.String get $name => 'tempconv.v1.TempConv';

  TempConvServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Value, $0.Value>(
        'CelsiusToFahrenheit',
        celsiusToFahrenheit_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Value.fromBuffer(value),
        ($0.Value value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Value, $0.Value>(
        'FahrenheitToCelsius',
        fahrenheitToCelsius_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Value.fromBuffer(value),
        ($0.Value value) => value.writeToBuffer()));
  }

  $async.Future<$0.Value> celsiusToFahrenheit_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Value> $request) async {
    return celsiusToFahrenheit($call, await $request);
  }

  $async.Future<$0.Value> celsiusToFahrenheit(
      $grpc.ServiceCall call, $0.Value request);

  $async.Future<$0.Value> fahrenheitToCelsius_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Value> $request) async {
    return fahrenheitToCelsius($call, await $request);
  }

  $async.Future<$0.Value> fahrenheitToCelsius(
      $grpc.ServiceCall call, $0.Value request);
}
