import 'dart:convert';
import 'package:edfapg_sdk/src/Helpers.dart';
import 'package:edfapg_sdk/src/adapters/BaseAdapter.dart';
import 'package:edfapg_sdk/src/applepay/EdfaApplePayResult.dart';
import 'package:edfapg_sdk/src/request/EdfaPgPayer.dart';
import 'package:edfapg_sdk/src/request/EdfaPgSaleOrder.dart';
import 'package:edfapg_sdk/src/request/EdfaPgRecurringOptions.dart';
import 'callbacks/ApplePayResponseCallback.dart';

class EdfaApplePayAdapter extends BaseAdapter {
  execute({
    required EdfaPgSaleOrder order,
    required EdfaPgPayer payer,
    required ApplePayResponseCallback? callback,
    EdfaPgRecurringOptions? recurring,
    Function(dynamic)? onFailure,
  }) {
    final params = {
      "order": order.toJson(),
      "payer": payer.toJson(),
      if (recurring != null) "recurring": recurring.toJson(),
    };

    startApplePay(params).listen((event) {
      Log(event);
      EdfaApplePayResult(event).triggerCallbacks(callback);
    });

    Log("[EdfaApplePayAdapter.execute][Params] ${jsonEncode(params)}");
  }
}
