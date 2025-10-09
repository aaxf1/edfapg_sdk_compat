import 'package:flutter/cupertino.dart';
import 'package:edfapg_sdk/src/Helpers.dart';
import 'package:edfapg_sdk/src/adapters/callbacks/ApplePayResponseCallback.dart';
import 'package:edfapg_sdk/src/adapters/BaseAdapter.dart';
import 'package:edfapg_sdk/src/applepay/EdfaApplePayResult.dart';
import 'package:edfapg_sdk/src/request/EdfaPgPayer.dart';
import 'package:edfapg_sdk/src/request/EdfaPgSaleOrder.dart';
import 'package:edfapg_sdk/src/request/EdfaPgRecurringOptions.dart';
import 'package:edfapg_sdk/src/request/EdfaPgConfig.dart';

class EdfaApplePay {
  Function(Map response)? _onTransactionFailure;
  Function(Map response)? _onTransactionSuccess;
  Function(Map response)? _onAuthentication;
  Function(Map response)? _onError;
  Function(BuildContext)? _onPresent;

  EdfaPgSaleOrder? _order;
  EdfaPgPayer? _payer;
  EdfaPgConfig? _config;
  EdfaPgRecurringOptions? _recurring;

  EdfaApplePay setOrder(EdfaPgSaleOrder order) {
    _order = order;
    return this;
  }

  EdfaApplePay setPayer(EdfaPgPayer payer) {
    _payer = payer;
    return this;
  }

  EdfaApplePay setConfig(EdfaPgConfig config) {
    _config = config;
    return this;
  }

  EdfaApplePay setRecurring(EdfaPgRecurringOptions recurring) {
    _recurring = recurring;
    return this;
  }

  EdfaApplePay onTransactionFailure(Function(Map response) callback) {
    _onTransactionFailure = callback;
    return this;
  }

  EdfaApplePay onTransactionSuccess(Function(Map response) callback) {
    _onTransactionSuccess = callback;
    return this;
  }

  EdfaApplePay onAuthentication(Function(Map response) callback) {
    _onAuthentication = callback;
    return this;
  }

  EdfaApplePay onError(Function(Map response) callback) {
    _onError = callback;
    return this;
  }

  EdfaApplePay onPresent(Function(BuildContext context) callback) {
    _onPresent = callback;
    return this;
  }

  void initialize(BuildContext context) {
    if (_order == null || _payer == null || _config == null) {
      Log("[EdfaApplePay] Missing required fields: order/payer/config");
      throw Exception("Order, Payer, and Config must be provided before initializing ApplePay.");
    }

    try {
      EdfaPgSdk.instance.ADAPTER.APPLE_PAY.execute(
        order: _order!,
        payer: _payer!,
        config: _config!,
        recurring: _recurring,
        callback: ApplePayResponseCallback(
          authentication: (Map response) {
            Log("[EdfaApplePay][Auth] $response");
            _onAuthentication?.call(response);
          },
          success: (Map response) {
            Log("[EdfaApplePay][Success] $response");
            _onTransactionSuccess?.call(response);
          },
          failure: (Map response) {
            Log("[EdfaApplePay][Failure] $response");
            _onTransactionFailure?.call(response);
          },
          error: (Map error) {
            Log("[EdfaApplePay][Error] $error");
            _onError?.call(error);
          },
        ),
        onFailure: (err) {
          Log("[EdfaApplePay][onFailure] $err");
          _onError?.call({"error": err.toString()});
        },
      );

      Future.delayed(const Duration(milliseconds: 200)).then((_) {
        if (_onPresent != null) _onPresent!(context);
      });
    } catch (e) {
      Log("[EdfaApplePay][Exception] $e");
      _onError?.call({"exception": e.toString()});
    }
  }

  Widget widget() {
    return const SizedBox();
  }
}
