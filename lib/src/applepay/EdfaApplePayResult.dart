import 'package:edfapg_sdk/src/adapters/callbacks/ApplePayResponseCallback.dart';

class EdfaApplePayResult{
  Map? authentication; 
  Map? success;
  Map? failure;
  Map? error;

  EdfaApplePayResult(Map result){
    // ✅ التعديل الرئيسي: استخدام Map<String, dynamic>.from() لتحويل النوع بشكل آمن
    if(result.containsKey("authentication")) {
      authentication = Map<String, dynamic>.from(result["authentication"]); 
    }

    if(result.containsKey("success")) {
      success = Map<String, dynamic>.from(result["success"]);
    }
    if(result.containsKey("failure")) {
      failure = Map<String, dynamic>.from(result["failure"]);
    }

    if(result.containsKey("error")) {
      error = Map<String, dynamic>.from(result["error"]);
    }
  }

  triggerCallbacks(ApplePayResponseCallback? callback, {Function(dynamic)? onFailure}){
    if(authentication != null) {
      callback?.authentication(authentication!);
    }

    if(success != null) {
      callback?.success(success!);
    }

    if(failure != null) {
      callback?.failure(failure!);
    }

    if(error != null) {
      callback?.error(error!);
    }
  }
}
