import 'package:edfapg_sdk/edfapg_sdk.dart';
import 'package:edfapg_sdk/src/adapters/callbacks/ApplePayResponseCallback.dart';
import 'package:edfapg_sdk/src/request/EdfaPgPayer.dart';
import 'package:edfapg_sdk/src/request/EdfaPgSaleOrder.dart';
import 'package:flutter/cupertino.dart';
import 'package:edfapg_sdk/src/Helpers.dart';

class EdfaApplePay {
  Function(Map response)? _onTransactionFailure;
  Function(Map response)? _onTransactionSuccess;
  Function(Map response)? _onAuthentication;
  Function(Map response)? _onError;
  Function(BuildContext)? _onPresent;

  EdfaPgSaleOrder? _order;
  EdfaPgPayer? _payer;

  // تم حذف applePayMerchantID لأنها لم تعد مطلوبة أو مدعومة
  // String? _applePayMerchantID;

  EdfaApplePay setOrder(EdfaPgSaleOrder order) {
    _order = order;
    return this;
  }

  EdfaApplePay setPayer(EdfaPgPayer payer) {
    _payer = payer;
    return this;
  }

  // تم حذف setApplePayMerchantID بالكامل لأنه لم يعد يستخدم
  /*
  EdfaApplePay setApplePayMerchantID(String applePayMerchantID) {
    _applePayMerchantID = applePayMerchantID;
    return this;
  }
  */

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

  initialize(BuildContext context) {
    EdfaPgSdk.instance.ADAPTER.APPLE_PAY.execute(
      // تمت إزالة applePayMerchantId لأنها غير مطلوبة الآن
      order: _order!,
      payer: _payer!,
      callback: ApplePayResponseCallback(
        authentication: (Map response) {
          Log(response.toString());
          _onAuthentication?.call(response);
        },
        success: (Map response) {
          Log(response.toString());
          _onTransactionSuccess?.call(response);
        },
        failure: (Map response) {
          Log(response.toString());
          _onTransactionFailure?.call(response);
        },
        error: (Map error) {
          _onError?.call(error);
        },
      ),
    );

    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      if (_onPresent != null) {
        _onPresent!(context);
      }
    });
  }

  Widget widget() {
    return const SizedBox();
  }
}
