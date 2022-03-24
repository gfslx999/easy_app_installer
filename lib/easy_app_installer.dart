library easy_app_installer;

export 'package:easy_app_installer/constant/easy_app_installer_constant.dart';
export 'package:easy_app_installer/constant/easy_app_installer_state.dart';

import 'dart:async';

import 'package:easy_app_installer/constant/easy_app_installer_constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'constant/easy_app_installer_state.dart';

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
  /// [fileUrl] apk远程地址
  /// [fileDirectory] 在沙盒目录下的文件夹路径
  /// [fileName] 文件名称，示例：newApk.apk(注意要拼接后缀.apk或.xxx)，无需传递 '/'
  /// [isDeleteOriginalFile] 如果本地存在相同文件，是否删除已存在文件，默认为true
  /// [explainContent] Android 6 ~ Android 10 中自定义权限弹窗的提示内容
  /// [positiveText] Android 6 ~ Android 10 中自定义权限弹窗的确认文字内容
  /// [negativeText] Android 6 ~ Android 10 中自定义权限弹窗的取消文字内容
  /// [downloadListener] 下载进度回调，值为 0~100
  /// [cancelTagListener] 回调用于取消下载中任务的tag
  /// [stateListener] 下载状态变化时改变，state 参见 [EasyAppInstallerState],
  /// 'attachParam' 仅在 onSuccess/onFailed 时回调, 'onSuccess' 时为apk路径, 'onFailed' 时为错误信息
  ///
  /// 关于 [fileDirectory]、[fileName] 的说明
  /// 如沙盒目录为：/data/user/0/com.xxxxx.flutter_native_helper_example/files
  /// [fileDirectory] 为 'updateApk' ，[fileName] 为 'new.apk'，
  /// 那么最终生成的路径就是: /data/user/0/com.xxxxx.flutter_native_helper_example/files/updateApk/new.apk
  /// 即你无需关心反斜杠拼接，如果 [fileDirectory] 想要为两级，那就为 'updateApk/second'，
  /// 最终路径就为：/data/user/0/com.xxxxx.flutter_native_helper_example/files/updateApk/second/new.apk
  Future<bool> downloadAndInstallApk({
    required String fileUrl,
    required String fileDirectory,
    required String fileName,
    bool isDeleteOriginalFile = true,
    String? explainContent,
    String? positiveText,
    String? negativeText,
    Function(double progress)? downloadListener,
    Function(String cancelTag)? cancelTagListener,
    Function(EasyAppInstallerState state, String? attachParam)? stateListener,
  }) async {
    final arguments = <String, dynamic>{
      "fileUrl": fileUrl,
      "fileDirectory": fileDirectory,
      "fileName": fileName,
      "isDeleteOriginalFile": isDeleteOriginalFile,
      "explainContent": explainContent,
      "positiveText": positiveText,
      "negativeText": negativeText,
    };

    if (downloadListener != null ||
        cancelTagListener != null ||
        stateListener != null) {
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case EasyAppInstallerConstant.methodDownloadProgress:
            if (call.arguments is double && downloadListener != null) {
              downloadListener((call.arguments as double));
            }
            break;
          case EasyAppInstallerConstant.methodCancelTag:
            if (call.arguments is String && cancelTagListener != null) {
              cancelTagListener((call.arguments as String));
            }
            break;
          case EasyAppInstallerConstant.methodDownloadState:
            if (stateListener != null && call.arguments != null) {
              _handleDownloadState(call.arguments, stateListener);
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
  ///
  /// [cancelTag] 根据 [downloadAndInstallApp] 的 'cancelTagListener' 回调来获得。
  Future<void> cancelDownload(String cancelTag) async {
    final arguments = <String, dynamic>{"cancelTag": cancelTag};
    await _channel.invokeMethod("cancelDownload", arguments);
  }

  /// 安装apk，内部已处理 '允许应用内安装其他应用' 权限
  ///
  /// [filePath] 要安装的apk绝对路径
  /// [explainContent] Android 6 ~ Android 10 中自定义权限弹窗的提示内容
  /// [positiveText] Android 6 ~ Android 10 中自定义权限弹窗的确认文字内容
  /// [negativeText] Android 6 ~ Android 10 中自定义权限弹窗的取消文字内容
  Future<String> installApk(
    String filePath, {
    String? explainContent,
    String? positiveText,
    String? negativeText,
  }) async {
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
  /// [applicationPackageName] 要打开的应用名称，如果为空，则默认打开当前应用
  /// [targetMarketPackageName] 指定应用市场包名
  /// [isOpenSystemMarket] 如 'targetMarketPackageName' 为空，是否打开本机自带应用市场，
  ///
  /// 简单来说，如果你有指定的应用市场，就传递 'targetMarketPackageName' 为对应的包名；
  /// 如果你没有指定的应用市场，但是想让大部分机型都打开厂商应用商店，那么就设置 'isOpenSystemMarket' 为true
  Future<bool> openAppMarket({
    String applicationPackageName = "",
    String targetMarketPackageName = "",
    bool isOpenSystemMarket = true,
  }) async {
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

  /// 打开设置-指定应用详情页
  ///
  /// [applicationPackageName] 指定应用包名，如果为空，则默认为当前应用
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
