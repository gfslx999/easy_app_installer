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
                openAppStore(appId: arguments?["appId"], result: result)
                break;
            case "openAppSettingDetail":
                openAppSettingDetail(result: result)
            default :
                result(FlutterMethodNotImplemented)
                break;
        }
    }
    
    /**
     打开当前APP系统设置页面
     */
    private func openAppSettingDetail(result: @escaping FlutterResult) {
        
        let url = URL(string: "\(UIApplication.openSettingsURLString)")
        
        if let url = url, UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:]) { openResult in
                    result(openResult)
                }
            } else {
                UIApplication.shared.openURL(url)
                result(true)
            }
        } else {
            result(FlutterError(code: "0", message: "URL can't open: \(String(describing: url))", details: ""))
        }
    }
    
    /**
     打开AppStore当前应用页面
     */
    private func openAppStore(appId: Any?, result: @escaping FlutterResult) {
        // 获取传入的appId
        guard let appId = appId as? String else {
            result(FlutterError(code: "0", message: "AppId can't be null or empty!", details: ""))
            return
        }
        if appId.isEmpty {
            result(FlutterError(code: "0", message: "AppId can't be null or empty!", details: ""))
            return
        }
        
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)") else {
            result(FlutterError(code: "0", message: "Transform to url failed!", details: ""))
            return
        }
        // 判断此链接是否能够打开
        if UIApplication.shared.canOpenURL(url) {
            // 区分不同版本
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { (openResult) in
                    print("openAppStore.openResult: \(openResult)")
                    //todo 根据打开结果来判断
                    result(openResult)
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
