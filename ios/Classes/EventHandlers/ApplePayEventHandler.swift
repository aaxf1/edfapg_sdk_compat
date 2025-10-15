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


class ApplePayEventHandler : NSObject, FlutterStreamHandler{
    
    var eventSink:FlutterEventSink? = nil
    
    // (SaleAdapter code remains the same, assuming it's correctly linked)
    private lazy var saleAdapter: EdfaPgSaleAdapter = {
        let adapter = EdfaPgAdapterFactory().createSale()
        adapter.delegate = self
        return adapter
    }()
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        if let params = arguments as? [String:Any],
           let order = params["EdfaPgSaleOrder"] as? [String : Any?],
           let payer =  params["EdfaPgPayer"] as? [String : Any?],
           let applePayMerchantId = params["applePayMerchantId"] as? String{
             
            let order = EdfaPgSaleOrder.from(dictionary: order)
            let payer = EdfaPgPayer.from(dictionary: payer)
            
            // ⚠️ التعديل الأول: استخدام rootViewController لزيادة الموثوقية وتجنب nil
            guard let targetVC = UIApplication.shared.keyWindow?.rootViewController else {
                self.handleFailure(error: "Cannot find root view controller to present Apple Pay sheet.")
                return FlutterError(code: "VIEW_ERROR", message: "Root VC not found.", details: nil)
            }
            
            // The precise way to present by sdk it self
            EdfaApplePay()
                .set(order: order)
                .set(payer: payer)
                .set(applePayMerchantID: applePayMerchantId)
                .enable(logs: ENABLE_DEBUG)
                .on(authentication: { pk in
                    debugPrint(pk)
                    self.handleAuth(paymentToken: pk.token)
                    
                }).on(transactionFailure: { [weak self] response in
                    guard let self = self else { return }
                    debugPrint(response)
                    self.handleFailure(error: response) // يرسل تحت مفتاح "failure"
                    
                }).on(transactionSuccess: { [weak self] response in
                    guard let self = self else { return }
                    debugPrint(response ?? "")
                    // ضمان تحويل كائن النجاح إلى JSON تحت مفتاح "success"
                    if let encodableResponse = response as? Encodable {
                        self.eventSink?(encodableResponse.toJSON(root: "success"))
                    } else {
                        // Fallback
                        let defaultSuccess = [
                            "result" : "SUCCESS",
                            "error_code" : 0,
                            "error_message" : "Transaction successful, but response object was unencodable."
                        ] as [String : Any]
                        self.eventSink?(["success": defaultSuccess])
                    }
                    
                }).initialize(
                    target: targetVC, // تم استخدام targetVC المعدل
                    onError: { [weak self] error in
                        guard let self = self else { return }
                        // ⚠️ التعديل الثاني: توجيه كل الأخطاء لـ handleFailure لتوحيد المفتاح إلى "failure"
                        self.handleFailure(error: error) 
                    },
                    onPresent: onPresent
                )
            
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
    
    private func onPresent(){
        debugPrint("onPresent :)")
        eventSink?(["onPresent" : ":)"])
    }
    
    private func handleAuth(paymentToken:PKPaymentToken){
        let data = [
            "authentication":[
                "transactionIdentifier":paymentToken.transactionIdentifier,
                "paymentData":paymentToken.paymentData,
                "paymentMethod":[
                    "displayName" : paymentToken.paymentMethod.displayName,
                    "network" : paymentToken.paymentMethod.network?.rawValue ?? "",
                ]
            ]
        ]
        self.eventSink?(data)
    }
    
    // تم إزالة handleSuccess القديمة غير المستخدمة لـ GetTransactionDetailsSuccess
    
    private func handleFailure(error:Any){
        if let e = error as? EdfaPgError{
            // ⚠️ التعديل: إرسال الـ EdfaPgError تحت مفتاح "failure"
            eventSink?(e.toJSON(root: "failure")) 
        }else if let e = error as? Encodable{
            // ⚠️ التعديل: إرسال الردود المرفوضة (failure response) تحت مفتاح "failure"
            eventSink?(e.toJSON(root: "failure"))
        }else{
            // ⚠️ التعديل: معالجة الأخطاء غير القابلة للترميز تحت مفتاح "failure"
            let errorMap = [
                "result" : "ERROR",
                "error_code" : 100000,
                "error_message" : "\(error)",
                "errors" : [],
            ] as [String : Any]
            eventSink?(["failure":errorMap]) 
        }
    }
    
}

extension ApplePayEventHandler : EdfaPgAdapterDelegate{
    
    func willSendRequest(_ request: EdfaPgDataRequest) {
        
    }
    
    func didReceiveResponse(_ reponse: EdfaPgDataResponse?) {
        
    }
    
}
