import Flutter
import UIKit
import EdfaPgSdk
import PassKit

fileprivate let events: EdfaPaySdkEventChannels = EdfaPaySdkEventChannels()
fileprivate let methods: EdfapaySdkMethodChannels = EdfapaySdkMethodChannels()

fileprivate let PAYMENT_URL = "https://api.edfapay.com/payment/post"

public class EdfaPgSdkPlugin: NSObject, FlutterPlugin, PKPaymentAuthorizationViewControllerDelegate {

    // MARK: - Apple Pay Authorization Delegate
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
        print("💳 ApplePay finished or cancelled.")
    }

    // MARK: - Flutter Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        if let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
            events.initiate(with: flutterViewController)
            methods.initiate(with: flutterViewController)
        }
        registrar.addMethodCallDelegate(EdfaPgSdkPlugin(), channel: methods.edfaPaySdk!)
    }

    // MARK: - Flutter Method Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == methods.methodGetPlatformVersion {
            getPlatformVersion(call, result: result)
        } else if call.method == methods.methodConfig {
            config(call, result: result)
        } else if call.method == "applePay" {
            if let vc = UIApplication.shared.delegate?.window??.rootViewController as? UIViewController {
                print("🚀 ApplePay triggered from Flutter")

                // القيم الافتراضية للاختبار — عدّلها لاحقاً من Dart
                apple(
                    viewController: vc,
                    merchantId: "merchant.com.fared",
                    label: "EdfaPay Checkout",
                    amount: 1.00
                )
                result("ApplePay started")
            } else {
                result(FlutterError(code: "NO_VC", message: "No root view controller found", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Apple Pay Core Logic
    func apple(viewController: UIViewController, merchantId: String, label: String, amount: Double) {
        let request = PKPaymentRequest()
        request.countryCode = "SA"
        request.currencyCode = "SAR"
        request.merchantIdentifier = merchantId
        request.merchantCapabilities = .capability3DS
        request.supportedNetworks = [.visa, .masterCard, .mada]

        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount))
        ]

        if let payvc = PKPaymentAuthorizationViewController(paymentRequest: request) {
            payvc.delegate = self
            DispatchQueue.main.async {
                print("✅ Presenting Apple Pay sheet...")
                viewController.present(payvc, animated: true)
            }
        } else {
            print("❌ ApplePay view controller creation failed")
        }
    }
}

// MARK: - Extensions
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
