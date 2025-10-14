//
//  ApplePayEventHandler.swift
//  edfapay_sdk
//
//  Fahad Alashab 
//

import Foundation
import Flutter
import UIKit
import EdfaPgSdk
import PassKit

class ApplePayEventHandler: NSObject, FlutterStreamHandler {

    var eventSink: FlutterEventSink? = nil
    private let ENABLE_DEBUG = true   // ✅ تعريف ثابت للتحكم في وضع الـ debug
    
    private lazy var saleAdapter: EdfaPgSaleAdapter = {
        let adapter = EdfaPgAdapterFactory().createSale()
        adapter.delegate = self
        return adapter
    }()
    
    // MARK: - Flutter Stream Setup
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        if let params = arguments as? [String: Any],
           let orderDict = params["EdfaPgSaleOrder"] as? [String: Any?],
           let payerDict = params["EdfaPgPayer"] as? [String: Any?],
           let applePayMerchantId = params["applePayMerchantId"] as? String {
            
            let order = EdfaPgSaleOrder.from(dictionary: orderDict)
            let payer = EdfaPgPayer.from(dictionary: payerDict)
            
            EdfaApplePay()
                .set(order: order)
                .set(payer: payer)
                .set(applePayMerchantID: applePayMerchantId)
                .enable(logs: ENABLE_DEBUG)
                .on(authentication: { pk in
                    debugPrint("🔐 ApplePay Auth Token (masked): \(pk.token.transactionIdentifier)")
                    self.handleAuth(paymentToken: pk.token)
                    
                }).on(transactionFailure: { response in
                    debugPrint("❌ ApplePay Failure Response: \(response)")
                    self.handleFailure(error: response)
                    
                }).on(transactionSuccess: { response in
                    debugPrint("✅ ApplePay Success Response:")
                    if let ok = response as? EdfaPgGetTransactionDetailsSuccess {
                        self.handleSuccess(response: ok)
                    } else if let enc = response as? Encodable {
                        self.eventSink?(enc.toJSON(root: "success"))
                    } else if let resp = response {
                        self.eventSink?(["success": String(describing: resp)])
                    } else {
                        self.eventSink?(["success": [:]])
                    }
                    
                }).initialize(
                    target: UIApplication.currentViewController()!,
                    onError: { error in
                        self.eventSink?(["failure": [
                            "result": "ERROR",
                            "error_message": "\(error)"
                        ]])
                    },
                    onPresent: onPresent
                )
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // MARK: - ApplePay Handlers
    
    private func onPresent() {
        debugPrint("📲 ApplePay Sheet Presented")
        eventSink?(["onPresent": ":)"])
    }
    
    private func handleAuth(paymentToken: PKPaymentToken) {
        let data: [String: Any] = [
            "authentication": [
                "transactionIdentifier": paymentToken.transactionIdentifier,
                // ⚠️ عدم إرسال بيانات البطاقة الفعلية لأسباب أمنية
                "paymentMethod": [
                    "displayName": paymentToken.paymentMethod.displayName ?? "",
                    "network": paymentToken.paymentMethod.network?.rawValue ?? ""
                ]
            ]
        ]
        eventSink?(data)
    }
    
    // MARK: - Unified Success / Failure Handling
    
    private func handleSuccess(response: EdfaPgGetTransactionDetailsSuccess) {
        let json = response.toJSON(root: "success")
        debugPrint("✅ native.transactionSuccess.data => \(json)")
        eventSink?(json)
    }
    
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
}

// MARK: - EdfaPgAdapterDelegate
extension ApplePayEventHandler: EdfaPgAdapterDelegate {
    
    func willSendRequest(_ request: EdfaPgDataRequest) {
        // يمكن استخدامه لتتبع الطلبات قبل الإرسال
        if ENABLE_DEBUG {
            debugPrint("📤 EdfaPgAdapter will send request: \(request)")
        }
    }
    
    func didReceiveResponse(_ reponse: EdfaPgDataResponse?) {
        // تمرير أي JSON خام للـ Flutter لأغراض التشخيص
        if let data = reponse?.data,
           let dict = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) {
            eventSink?(["responseJSON": dict])
        }
    }
}
