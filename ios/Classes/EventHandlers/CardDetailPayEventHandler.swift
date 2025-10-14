//
//  ApplePayEventHandler.swift
//  edfapg_sdk
//
//

import Foundation
import edfapg_ios_sdk

class ApplePayEventHandler: NSObject, FlutterStreamHandler, EdfaPgAdapterDelegate {
    
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        // ✅ تفعيل تمرير الأحداث إلى Flutter مع تحويلها إلى JSON منظم
        EdfaApplePay()
            .on(transactionFailure: { error in
                self.handleFailure(error: error)
            })
            .on(transactionSuccess: { response in
                if let ok = response as? EdfaPgGetTransactionDetailsSuccess {
                    self.handleSuccess(response: ok)
                } else if let enc = response as? Encodable {
                    self.eventSink?(enc.toJSON(root: "success"))
                } else if let resp = response {
                    self.eventSink?(["success": String(describing: resp)])
                } else {
                    self.eventSink?(["success": [:]])
                }
            })
            .initialize(
                EdfaPgSdk.instance.config.key,
                password: EdfaPgSdk.instance.config.password,
                debugMode: EdfaPgSdk.instance.config.enableDebug
            )
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // ✅ عند فشل العملية - نحولها إلى JSON منظم
    private func handleFailure(error: Any) {
        if let e = error as? EdfaPgError {
            eventSink?(["failure": e.json()])
        } else if let e = error as? Encodable {
            eventSink?(e.toJSON(root: "failure"))
        } else {
            eventSink?(["failure": [
                "result": "ERROR",
                "error_code": 100000,
                "error_message": "\(error)",
                "errors": []
            ]])
        }
    }
    
    // ✅ عند النجاح - تحويل الرد إلى JSON
    private func handleSuccess(response: EdfaPgGetTransactionDetailsSuccess) {
        eventSink?(response.toJSON(root: "success"))
    }
    
    // ✅ تمرير الرد الخام في حال الفشل الداخلي بالـ SDK
    func didReceiveResponse(_ reponse: EdfaPgDataResponse?) {
        if let data = reponse?.data,
           let dict = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) {
            eventSink?(["responseJSON": dict])
        }
    }
}
