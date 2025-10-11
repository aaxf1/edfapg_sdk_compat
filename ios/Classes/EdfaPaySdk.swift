import Flutter
import UIKit
import PassKit
import Foundation

fileprivate let events: EdfaPaySdkEventChannels = EdfaPaySdkEventChannels()
fileprivate let methods: EdfapaySdkMethodChannels = EdfapaySdkMethodChannels()

fileprivate let PAYMENT_URL = "https://api.edfapay.com/payment/post"

public class EdfaPgSdkPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        if let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            events.initiate(with: flutterViewController)
            methods.initiate(with: flutterViewController)
        }
        if let channel = methods.edfaPaySdk {
            registrar.addMethodCallDelegate(EdfaPgSdkPlugin(), channel: channel)
        } else {
            // Fallback channel creation if initiate didn't run with a FlutterViewController
            let channel = FlutterMethodChannel(name: "edfapg_sdk", binaryMessenger: registrar.messenger())
            registrar.addMethodCallDelegate(EdfaPgSdkPlugin(), channel: channel)
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case methods.methodGetPlatformVersion:
            getPlatformVersion(call, result: result)

        case methods.methodConfig:
            config(call, result: result)

        case methods.methodApplePay:
            // Expecting arguments from Flutter
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing arguments for applePay", details: nil))
                return
            }
            let merchantId = (args["merchantId"] as? String) ?? "merchant.com.fared"
            let label = (args["label"] as? String) ?? "EdfaPay Checkout"
            let amount = (args["amount"] as? Double) ?? 1.0

            if let vc = UIApplication.shared.delegate?.window??.rootViewController {
                let handler = EdfaPgApplePayHandler(viewController: vc)
                handler.startApplePay(merchantId: merchantId, label: label, amount: amount, result: result)
            } else {
                result(FlutterError(code: "NO_VC", message: "No root view controller found", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Private helpers
extension EdfaPgSdkPlugin {
    private func getPlatformVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }
}

extension EdfaPgSdkPlugin {
    private func config(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let params = call.arguments as? [Any],
           let key = params[0] as? String,
           let pass = params[1] as? String,
           let enableDebug = params[2] as? Bool {

            let credentials = EdfaPgCredential(
                clientKey: key,
                clientPass: pass,
                paymentUrl: PAYMENT_URL
            )

            if enableDebug {
                EdfaPgSdk.enableLogs()
                print("🧩 EdfaPgSdk Debug mode enabled.")
            }

            EdfaPgSdk.config(credentials)
            print("🔑 EdfaPgSdk configured successfully.")
            result(true)
        } else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid config parameters", details: nil))
        }
    }
}
