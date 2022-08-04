library easy_app_installer;

export 'package:easy_app_installer/constant/easy_app_installer_constant.dart';
export 'package:easy_app_installer/constant/easy_app_installer_state.dart';

import 'dart:async';
import 'package:easy_app_installer/constant/easy_app_installer_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'constant/easy_app_installer_state.dart';

typedef OnStateChangeListener = Function(EasyAppInstallerState state, String? attachParam);

class EasyAppInstaller {
  EasyAppInstaller.internal();

  static EasyAppInstaller get instance => _getInstance();
  static EasyAppInstaller? _instance;
  static const MethodChannel _channel = MethodChannel('easy_app_installer');

  static EasyAppInstaller _getInstance() {
    _instance ??= EasyAppInstaller.internal();
    return _instance!;
  }

  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');

    return version;
  }

  /// 下载APK到沙盒目录下，并执行安装操作
  ///
  /// 仅支持Android
  Future<bool> downloadAndInstallApk({
    required String fileUrl,
    required String fileDirectory,
    required String fileName,
    bool isDeleteOriginalFile = true,
    String? explainContent,
    String? positiveText,
    String? negativeText,
    Function(double progress)? onDownloadingListener,
    Function(String cancelTag)? onCancelTagListener,
    OnStateChangeListener? onStateListener,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final arguments = <String, dynamic>{
      "fileUrl": fileUrl,
      "fileDirectory": fileDirectory,
      "fileName": fileName,
      "isDeleteOriginalFile": isDeleteOriginalFile,
      "explainContent": explainContent,
      "positiveText": positiveText,
      "negativeText": negativeText,
    };

    if (onDownloadingListener != null ||
        onCancelTagListener != null ||
        onStateListener != null) {
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case EasyAppInstallerConstant.methodDownloadProgress:
            if (call.arguments is double && onDownloadingListener != null) {
              onDownloadingListener((call.arguments as double));
            }
            break;
          case EasyAppInstallerConstant.methodCancelTag:
            if (call.arguments is String && onCancelTagListener != null) {
              onCancelTagListener((call.arguments as String));
            }
            break;
          case EasyAppInstallerConstant.methodDownloadState:
            if (onStateListener != null && call.arguments != null) {
              _handleDownloadState(call.arguments, onStateListener);
            }
            break;
        }
      });
    }

    try {
      await _channel.invokeMethod("downloadAndInstallApk", arguments);
      return true;
    } catch (e) {
      debugPrint("EasyAppInstaller.downloadAndInstallApk: $e");
      return false;
    }
  }

  /// 取消下载中的任务
  /// 仅支持Android
  Future<void> cancelDownload(String cancelTag) async {
    final arguments = <String, dynamic>{"cancelTag": cancelTag};
    await _channel.invokeMethod("cancelDownload", arguments);
  }

  /// 安装apk，内部已处理 '允许应用内安装其他应用' 权限
  ///
  /// 仅支持Android
  Future<String> installApk(
    String filePath, {
    String? explainContent,
    String? positiveText,
    String? negativeText,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return "";
    }
    final arguments = <String, dynamic>{
      "filePath": filePath,
      "explainContent": explainContent,
      "positiveText": positiveText,
      "negativeText": negativeText,
    };
    final result = await _channel.invokeMethod("installApk", arguments);

    try {
      return _handleInstallResult(result, from: "installApk");
    } catch (e) {
      debugPrint("EasyAppInstaller.installApk: $e");
      return "";
    }
  }

  /// 打开应用市场-当前应用详情页面
  ///
  /// 仅支持Android
  Future<bool> openAppMarket({
    String applicationPackageName = "",
    String targetMarketPackageName = "",
    bool isOpenSystemMarket = true,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final arguments = <String, dynamic>{
      "applicationPackageName": applicationPackageName,
      "targetMarketPackageName": targetMarketPackageName,
      "isOpenSystemMarket": isOpenSystemMarket,
    };
    try {
      final result = await _channel.invokeMethod("openAppMarket", arguments);
      if (result is bool) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("EasyAppInstaller.openAppMarket: $e");
      return false;
    }
  }

  /// 打开AppStore
  ///
  /// 仅支持iOS
  Future<bool> openAppStore(String appId) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      final arguments = <String, dynamic>{
        "appId": appId,
      };
      return await _channel.invokeMethod("openAppStore", arguments) ?? false;
    } catch (e) {
      debugPrint("EasyAppInstaller.openAppStore: $e");
    }
    return false;
  }

  /// 打开设置-应用详情页
  ///
  /// iOS 仅支持打开当前应用设置页面，无需传值
  /// Android 支持打开指定应用详情页，传入对应包名即可；不传默认打开当前应用的设置页
  Future<bool> openAppSettingDetails({
    String applicationPackageName = "",
  }) async {
    final arguments = <String, dynamic>{
      "applicationPackageName": applicationPackageName,
    };
    try {
      final result =
          await _channel.invokeMethod("openAppSettingDetail", arguments);
      if (result is bool) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("EasyAppInstaller.openAppSettingDetails: $e");
      return false;
    }
  }

  /// 销毁资源
  void dispose() {
    _channel.setMethodCallHandler(null);
  }

  /// 处理安装返回结果
  String _handleInstallResult(dynamic result, {String from = ""}) {
    final apkPath = result['apkPath'];
    if (apkPath != null && apkPath is String && apkPath.isNotEmpty) {
      return apkPath;
    }
    debugPrint("EasyAppInstaller.$from error: ${result["errorMessage"]}");
    return "";
  }

  /// 处理下载状态回调
  void _handleDownloadState(
      dynamic arguments,
      Function(EasyAppInstallerState state, String? attachParam)
          stateChangeListener) {
    final newState = arguments["newState"] as String? ?? "";
    final filePath = arguments["apkFilePath"] as String? ?? "";
    final errorMsg = arguments["errorMsg"] as String? ?? "";

    if (newState.isNotEmpty) {
      switch (newState) {
        case "ON_PREPARED":
          stateChangeListener(EasyAppInstallerState.onPrepared, "");
          break;
        case "ON_DOWNLOADING":
          stateChangeListener(EasyAppInstallerState.onDownloading, "");
          break;
        case "ON_SUCCESS":
          stateChangeListener(EasyAppInstallerState.onSuccess, filePath);
          break;
        case "ON_ERROR":
          stateChangeListener(EasyAppInstallerState.onFailed, errorMsg);
          break;
        case "ON_CANCELED":
          stateChangeListener(EasyAppInstallerState.onCanceled, "");
          break;
      }
    }
  }
}
