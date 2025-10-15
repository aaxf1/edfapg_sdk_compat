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
    
    private lazy var saleAdapter: EdfaPgSaleAdapter = {
        let adapter = EdfaPgAdapterFactory().createSale()
        adapter.delegate = self
        return adapter
    }()
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        // ⚠️ ملاحظة: تم إبقاء منطق التنفيذ هنا للتوافق مع بنية الـ SDK/Plugin Bridge
        // لكن التنفيذ الفعلي للعرض يعتمد على initialize() الذي يتم تشغيله من Flutter عند ضغط الزر.
        if let params = arguments as? [String:Any],
           let order = params["EdfaPgSaleOrder"] as? [String : Any?],
           let payer =  params["EdfaPgPayer"] as? [String : Any?],
           let applePayMerchantId = params["applePayMerchantId"] as? String{
             
            let order = EdfaPgSaleOrder.from(dictionary: order)
            let payer = EdfaPgPayer.from(dictionary: payer)
            
            // ⚠️ التعديل الأول: استخدام rootViewController لزيادة الموثوقية
            guard let targetVC = UIApplication.shared.keyWindow?.rootViewController else {
                self.handleFailure(error: "Cannot find root view controller to present Apple Pay sheet.")
                return FlutterError(code: "VIEW_ERROR", message: "Root VC not found.", details: nil)
            }
            
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
                    self.handleFailure(error: response)
                    
                }).on(transactionSuccess: { [weak self] response in
                    guard let self = self else { return }
                    debugPrint(response ?? "")
                    if let encodableResponse = response as? Encodable {
                        self.eventSink?(encodableResponse.toJSON(root: "success"))
                    } else {
                         // Fallback for unencodable or null response
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
                        // ⚠️ التعديل الثاني: توحيد المفتاح إلى "failure" بدلاً من "error"
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
    
    private func handleSuccess(response: EdfaPgGetTransactionDetailsSuccess){
        debugPrint("native.transactionSuccess.data ==> \(String(describing: response.toJSON(root: "success")))")
         eventSink?(response.toJSON(root: "success"))
     }
    
    private func handleFailure(error:Any){
        if let e = error as? EdfaPgError{
            // ⚠️ التعديل الثالث: إرسال الخطأ تحت مفتاح "failure"
            eventSink?(e.toJSON(root: "failure")) 
        }else if let e = error as? Encodable{
            eventSink?(e.toJSON(root: "failure"))
        }else{
            let errorMap = [
                "result" : "ERROR",
                "error_code" : 100000,
                "error_message" : "\(error)",
                "errors" : [],
            ] as [String : Any]
            // ⚠️ التعديل الثالث: إرسال الخطأ تحت مفتاح "failure"
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
