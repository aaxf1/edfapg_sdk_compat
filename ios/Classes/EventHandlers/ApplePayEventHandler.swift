//
//  SaleEventHandler.swift
//  edfapay_sdk
//
//  Created by fahad alashab on 14/10/2025.
//

import Foundation
import Flutter
import UIKit
import EdfaPgSdk
import PassKit


class ApplePayEventHandler: NSObject, FlutterStreamHandler {

    var eventSink: FlutterEventSink? = nil
    // ✅ يمكنك التحكم في إظهار سجلات الـ debug من هنا
    private let ENABLE_DEBUG = true
    
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
                    debugPrint("🔐 ApplePay Auth...")
                    self.handleAuth(paymentToken: pk)
                })
                .on(error: { error in
                    debugPrint("❌ ApplePay Error...")
                    self.handleFailure(error: error)
                })
                .on(success: { response in
                    debugPrint("✅ ApplePay Success...")
                    self.handleSuccess(response: response)
                })
                .set(viewController: UIApplication.shared.keyWindow?.rootViewController)
                .execute(adapter: self.saleAdapter)
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: - Internal Handlers
    
    private func handleAuth(paymentToken: PKPaymentToken) {
        let data: [String: Any] = [
            "authentication": [
                "transactionIdentifier": paymentToken.transactionIdentifier,
                "paymentData": paymentToken.paymentData,
                "paymentMethod": [
                    "displayName": paymentToken.paymentMethod.displayName,
                    "network": paymentToken.paymentMethod.network?.rawValue ?? ""
                ]
            ]
        ]
        eventSink?(data)
    }
    
    // MARK: - Unified Success / Failure Handling
    
    private func handleSuccess(response: EdfaPgGetTransactionDetailsSuccess) {
        let json = response.toJSON(root: "success")
        debugPrint("✅ native.transactionSuccess.data => \(json ?? [:])")
        eventSink?(json)
    }
    
    // 🛑 الدالة المعدَّلة لـ handleFailure 🛑
    private func handleFailure(error: Any) {
        if let e = error as? EdfaPgError {
            // حالة خطأ SDK قياسي
            eventSink?([ "failure": e.json() ])
        } else {
            // حالة خطأ فك الترميز (Decoding Error) أو أي خطأ غير متوقع (Type: Encodable, String, etc.)
            let errorMessage: String
            
            if let encodableError = error as? Encodable {
                // حاول تحويل الخطأ إلى JSON قياسي أولاً (إذا أمكن)
                if let jsonError = encodableError.toJSON(root: "error") {
                    eventSink?(jsonError)
                    return
                }
                // إذا فشل التحويل عبر toJSON، أرسل رسالة توضيحية لـ Flutter
                // (هذه الكتلة تحل مشكلة الـ Type Cast)
                errorMessage = "Decoding Failed (check EdfaPgStatus enum). Raw error: \(error)"
            } else {
                // خطأ غير مصنف (مثل String أو Error)
                errorMessage = "Native SDK Error: \(error)"
            }
            
            // بناء خريطة خطأ قياسية ومضمونة لـ Flutter
            let errorMap: [String: Any] = [
                "result": "ERROR",
                "error_code": 100000,
                "error_message": errorMessage,
                "errors": []
            ]
            
            // نستخدم قناة "failure" هنا حيث أن الخطأ نتج عن عملية فاشلة
            eventSink?([ "failure": errorMap ])
            debugPrint("❌ NATIVE ERROR HANDLED (FAILURE) => \(errorMap)")
        }
    }
}

// MARK: - EdfaPgAdapterDelegate
extension ApplePayEventHandler: EdfaPgAdapterDelegate {
    
    func willSendRequest(_ request: EdfaPgDataRequest) {
        if ENABLE_DEBUG {
            debugPrint("📤 EdfaPgAdapter will send request: \(request)")
        }
    }
    
    func didReceiveResponse(_ reponse: EdfaPgDataResponse?) {
        if let data = reponse?.data,
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            debugPrint("📢 SDK Response Raw => \(dict)")
        }
    }
}
