import Foundation
import Flutter

class EdfapaySdkMethodChannels {

    var edfaPaySdk: FlutterMethodChannel? = nil

    // Method names used from Flutter
    let methodGetPlatformVersion = "getPlatformVersion"
    let methodConfig = "config"
    let methodApplePay = "applePay"

    func initiate(with controller: FlutterViewController) {
        // IMPORTANT: Channel name must match the one used in Dart side
        edfaPaySdk = FlutterMethodChannel(name: "edfapg_sdk", binaryMessenger: controller.binaryMessenger)
    }
}
