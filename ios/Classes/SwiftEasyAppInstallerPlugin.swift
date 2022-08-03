import Flutter
import UIKit

public class SwiftEasyAppInstallerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "easy_app_installer", binaryMessenger: registrar.messenger())
        let instance = SwiftEasyAppInstallerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        switch (call.method) {
            case "getPlatformVersion":
                result("iOS " + UIDevice.current.systemVersion)
                break;
            case "openAppStore":
                if let appId = arguments?["appId"] as? String {
                    if (appId.isEmpty) {
                        result(FlutterError(code: "0", message: "AppId can't be null or empty!", details: ""))
                    }
                    openAppStore(appId: appId, result: result)
                } else {
                    result(FlutterError(code: "0", message: "AppId can't be null or empty!", details: ""))
                }
                break;
            default :
                result(FlutterMethodNotImplemented)
                break;
        }
    }
    
    /**
     打开AppStore当前应用页面
     */
    private func openAppStore(appId: String, result: @escaping FlutterResult) {
        print("openAppStore.appId: \(appId)")
        let stringUrl = "itms-apps://itunes.apple.com/app/id\(appId)"
        
        guard let url = URL(string: stringUrl) else {
            result(FlutterError(code: "0", message: "Transform to url failed!", details: ""))
            return
        }
        print("openAppStore.url: \(url)")
        // 判断此链接是否能够打开
        if UIApplication.shared.canOpenURL(url) {
            // 区分不同版本
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { (openResult) in
                    print("openAppStore.openResult: \(openResult)")
                    //todo 根据打开结果来判断
                    result(true)
                }
            } else {
                UIApplication.shared.openURL(url)
                result(true)
            }
        } else {
            result(FlutterError(code: "0", message: "Url can't open, \(url)", details: ""))
        }
    }
    
}
