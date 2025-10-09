import 'dart:convert';
import 'package:edfapg_sdk/src/Helpers.dart';
import 'package:edfapg_sdk/src/adapters/BaseAdapter.dart';
import 'package:edfapg_sdk/src/applepay/EdfaApplePayResult.dart';
import 'package:edfapg_sdk/src/request/EdfaPgPayer.dart';
import 'package:edfapg_sdk/src/request/EdfaPgSaleOrder.dart';
import 'package:edfapg_sdk/src/request/EdfaPgRecurringOptions.dart';
import 'package:edfapg_sdk/src/request/EdfaPgConfig.dart'; // ✅ مفقودة في نسختك
import 'callbacks/ApplePayResponseCallback.dart';

class EdfaApplePayAdapter extends BaseAdapter {
  execute({
    required EdfaPgSaleOrder order,
    required EdfaPgPayer payer,
    required ApplePayResponseCallback? callback,
    required EdfaPgConfig config, // ✅ ضروري حتى يتم تهيئة البيئة و merchantKey
    EdfaPgRecurringOptions? recurring,
    Function(dynamic)? onFailure,
  }) {
    final params = {
      "order": order.toJson(),
      "payer": payer.toJson(),
      "config": config.toJson(), // ✅ مهم جدًا حتى يقرأ الـ SDK بيانات البيئة والتاجر
      if (recurring != null) "recurring": recurring.toJson(),
    };

    Log("[EdfaApplePayAdapter.execute][Params] ${jsonEncode(params)}");

    try {
      // ✅ هذا السطر يشغّل الدفع فعليًا
      startApplePay(params).listen((event) {
        Log("[EdfaApplePayAdapter][Event]: $event");
        EdfaApplePayResult(event).triggerCallbacks(callback);
      });
    } catch (e) {
      Log("[EdfaApplePayAdapter.execute][Error] $e");
      if (onFailure != null) {
        onFailure!(e);
      }
    }
  }
}
