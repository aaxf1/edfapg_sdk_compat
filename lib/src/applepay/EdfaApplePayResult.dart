
import 'package:edfapg_sdk/src/adapters/callbacks/ApplePayResponseCallback.dart';

class EdfaApplePayResult{
  Map? authentication;
  Map? success;
  Map? failure;
  Map? error; // سيظل موجودًا لدعم مفتاح الخطأ الصريح

  EdfaApplePayResult(Map result){
    if(result.containsKey("authentication")) {
      authentication = result["authentication"];
    }

    if(result.containsKey("success")) {
      success = result["success"];
    }
    if(result.containsKey("failure")) {
      failure = result["failure"];
    }

    // 💡 التعديل: إعطاء الأولوية لمفتاح "failure" لتوحيد منطق الأخطاء
    if(result.containsKey("error")) {
      error = result["error"];
    } else if (result.containsKey("failure")) { // في حالة وجود فشل ولم يتم تعريف الخطأ صراحة
      failure = result["failure"];
    }
    
    // ملاحظة: بما أننا وحدنا كل الأخطاء في Swift إلى "failure"، فإن الـ 'error' قد لا يكون مطلوبًا
    // ولكن نتركه لدعم الـ SDK الحالي. 
  }

  triggerCallbacks(ApplePayResponseCallback? callback, {Function(dynamic)? onFailure}){
    if(authentication != null) {
      callback?.authentication(authentication! as Map<String, dynamic>); // تم إضافة Cast هنا لزيادة السلامة
    }

    if(success != null) {
      callback?.success(success! as Map<String, dynamic>); // تم إضافة Cast هنا
    }

    if(failure != null) {
      callback?.failure(failure! as Map<String, dynamic>); // تم إضافة Cast هنا
    }

    if(error != null) {
      callback?.error(error! as Map<String, dynamic>); // تم إضافة Cast هنا
    }
  }
}
