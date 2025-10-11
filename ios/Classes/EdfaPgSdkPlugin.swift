import Flutter
import UIKit
import PassKit

public class EdfaPgSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "edfapg_sdk", binaryMessenger: registrar.messenger())
        let instance = EdfaPgSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "executeApplePay":
            // لاحقًا هنا نربط ApplePay الحقيقي
            print("🟢 Apple Pay method called from Flutter")
            result("Apple Pay executed (test response)")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
