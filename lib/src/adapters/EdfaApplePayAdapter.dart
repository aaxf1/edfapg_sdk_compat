import 'dart:convert';
import 'package:edfapg_sdk/src/Helpers.dart';
import 'package:edfapg_sdk/src/adapters/BaseAdapter.dart';
import 'package:edfapg_sdk/src/applepay/EdfaApplePayResult.dart';
import 'package:edfapg_sdk/src/request/EdfaPgPayer.dart';
import 'package:edfapg_sdk/src/request/EdfaPgSaleOrder.dart';
import 'package:edfapg_sdk/src/request/EdfaPgConfig.dart';
import 'package:edfapg_sdk/src/request/EdfaPgRecurringOptions.dart';
import 'callbacks/ApplePayResponseCallback.dart';

/// ---------------------------------------------------------------------------
/// EdfaApplePayAdapter
/// ---------------------------------------------------------------------------
/// هذا الكلاس مسؤول عن تنفيذ عملية الدفع عبر Apple Pay.
/// يقوم بتجميع جميع البيانات المطلوبة (الطلب، العميل، البيئة، التاجر)
/// ويرسلها إلى القناة الأصلية الخاصة بـ iOS.
/// ---------------------------------------------------------------------------

class EdfaApplePayAdapter extends BaseAdapter {
  void execute({
    // البيانات الأساسية للعملية
    required EdfaPgSaleOrder order,
    required EdfaPgPayer payer,

    // إعدادات البيئة والتاجر
    required EdfaPgConfig config,

    // ردود الاستدعاء (callbacks)
    required ApplePayResponseCallback? callback,

    // خيار التكرار (recurring) — اختياري
    EdfaPgRecurringOptions? recurring,

    // رد الفشل العام (network, timeout, ...إلخ)
    Function(dynamic)? onFailure,
  }) {
    try {
      final params = {
        "order": order.toJson(),
        "payer": payer.toJson(),
        "config": config.toJson(),

        // Apple Pay Merchant ID مهم جدًا (من Apple Developer)
        "applePayMerchantId": config.merchantKey,

        // recurring اختياري، أضفه فقط إن وجد
        if (recurring != null) "recurring": recurring.toJson(),
      };

      Log("[EdfaApplePayAdapter.execute][Params] ${jsonEncode(params)}");

      // إرسال الطلب عبر EventChannel
      startApplePay(params).listen(
        (event) {
          Log("[EdfaApplePayAdapter.execute][Response] $event");
          EdfaApplePayResult(event).triggerCallbacks(callback);
        },
        onError: (err) {
          Log("[EdfaApplePayAdapter.execute][Error] $err");
          if (onFailure != null) onFailure(err);
        },
      );
    } catch (e) {
      Log("[EdfaApplePayAdapter.execute][Exception] $e");
      if (onFailure != null) onFailure(e);
    }
  }
}
