import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:edfapg_sdk/edfapg_sdk.dart';
import 'package:edfapg_sdk/src/Helpers.dart';
import 'package:edfapg_sdk/src/adapters/BaseAdapter.dart';
import 'package:edfapg_sdk/src/applepay/EdfaApplePayResult.dart';
import 'package:edfapg_sdk/src/request/EdfaPgPayer.dart';
import 'package:edfapg_sdk/src/request/EdfaPgSaleOrder.dart';
import 'callbacks/ApplePayResponseCallback.dart';

/// Adapter for integrating Apple Pay with EdfaPay SDK.
/// This class handles the communication between Dart and iOS native Swift code.
class EdfaApplePayAdapter extends BaseAdapter {
  /// The Flutter MethodChannel connecting Dart ↔ iOS native plugin.
  static const MethodChannel _channel = MethodChannel('edfapg_sdk');

  /// Sends payment data to the iOS plugin and listens for the result.
  /// This function directly invokes the native method defined in EdfaPgSdkPlugin.swift
  Stream<dynamic> startApplePay(Map<String, dynamic> params) async* {
    try {
      Log("📡 Invoking native ApplePay via channel: edfapg_sdk");
      final result = await _channel.invokeMethod('applePay', params);
      yield result;
    } catch (e, s) {
      Log("💥 ApplePay Channel Error: $e\n$s");
      yield {'error': e.toString()};
    }
  }

  /// Executes an Apple Pay transaction by sending the required data
  /// (order, payer, and merchant ID) to the iOS side.
  execute({
    required String applePayMerchantId,
    required EdfaPgSaleOrder order,
    required EdfaPgPayer payer,
    required ApplePayResponseCallback? callback,
    Function(dynamic)? onFailure,
  }) {
    final params = {
      order.runtimeType.toString(): order.toJson(),
      payer.runtimeType.toString(): payer.toJson(),
      "applePayMerchantId": applePayMerchantId,
    };

    Log("🧾 [EdfaApplePayAdapter.execute] Params => ${jsonEncode(params)}");

    startApplePay(params).listen((event) {
      Log("📩 ApplePay Event => $event");
      try {
        EdfaApplePayResult(event).triggerCallbacks(callback);
      } catch (err) {
        Log("⚠️ Failed to parse ApplePayResult: $err");
        if (onFailure != null) onFailure({'error': err.toString()});
      }
    });
  }
}
