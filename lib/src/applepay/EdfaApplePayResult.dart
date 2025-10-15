import 'package:edfapg_sdk/src/adapters/callbacks/ApplePayResponseCallback.dart';

class EdfaApplePayResult{
  // تم ترك الأنواع العامة Map? لتجنب تغيير الملفات الأخرى
  Map? authentication;
  Map? success;
  Map? failure;
  Map? error;

  EdfaApplePayResult(Map result){
    if(result.containsKey("authentication")) {
      // ✅ التعديل الرئيسي: تحويل النوع بشكل آمن
      authentication = Map<String, dynamic>.from(result["authentication"]);
    }

    if(result.containsKey("success")) {
      // ✅ التعديل الرئيسي: تحويل النوع بشكل آمن
      success = Map<String, dynamic>.from(result["success"]);
    }
    if(result.containsKey("failure")) {
      // ✅ التعديل الرئيسي: تحويل النوع بشكل آمن
      failure = Map<String, dynamic>.from(result["failure"]);
    }

    if(result.containsKey("error")) {
      // ✅ التعديل الرئيسي: تحويل النوع بشكل آمن
      error = Map<String, dynamic>.from(result["error"]);
    }
  }

  triggerCallbacks(ApplePayResponseCallback? callback, {Function(dynamic)? onFailure}){
    if(authentication != null) {
      // تم التأكد من أن authentication! هو Map<String, dynamic> الآن
      callback?.authentication(authentication!);
    }

    if(success != null) {
      // تم التأكد من أن success! هو Map<String, dynamic> الآن
      callback?.success(success!);
    }

    if(failure != null) {
      // تم التأكد من أن failure! هو Map<String, dynamic> الآن
      callback?.failure(failure!);
    }

    if(error != null) {
      // تم التأكد من أن error! هو Map<String, dynamic> الآن
      callback?.error(error!);
    }
  }
}
