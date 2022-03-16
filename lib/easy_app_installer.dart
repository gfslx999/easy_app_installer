library easy_app_installer;

export 'package:easy_app_installer/easy_app_installer_constant.dart';

import 'dart:async';

import 'package:easy_app_installer/easy_app_installer_constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  /// [downloadListener] 下载进度回调，值为 0~100
  /// [cancelTagListener] 回调用于取消下载中任务的tag
  ///
  /// 返回：如果成功跳转到应用安装页面，将返回apk的真实路径，否则为空字符串。
  ///
  /// 关于 [fileDirectory]、[fileName] 的说明
  /// 如沙盒目录为：/data/user/0/com.xxxxx.flutter_native_helper_example/files
  /// [fileDirectory] 为 'updateApk' ，[fileName] 为 'new.apk'，
  /// 那么最终生成的路径就是: /data/user/0/com.xxxxx.flutter_native_helper_example/files/updateApk/new.apk
  /// 即你无需关心反斜杠拼接，如果 [fileDirectory] 想要为两级，那就为 'updateApk/second'，
  /// 最终路径就为：/data/user/0/com.xxxxx.flutter_native_helper_example/files/updateApk/second/new.apk
  Future<String> downloadAndInstallApk({
    required String fileUrl,
    required String fileDirectory,
    required String fileName,
    bool isDeleteOriginalFile = true,
    Function(double progress)? downloadListener,
    Function(String cancelTag)? cancelTagListener
  }) async {
    final arguments = <String, dynamic>{
      "fileUrl": fileUrl,
      "fileDirectory": fileDirectory,
      "fileName": fileName,
      "isDeleteOriginalFile": isDeleteOriginalFile,
    };
    if (downloadListener != null || cancelTagListener != null) {
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
        }
      });
    }

    final result = await _channel.invokeMethod("downloadAndInstallApk", arguments);
    return _handleInstallResult(result, from: "downloadAndInstallApk");
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
  Future<String> installApk(String filePath) async {
    final arguments = <String, dynamic>{"filePath": filePath};
    final result = await _channel.invokeMethod("installApk", arguments);

    return _handleInstallResult(result, from: "installApk");
  }

  /// 打开应用市场-当前应用详情页面
  ///
  /// [targetMarketPackageName] 指定应用市场包名
  /// [isOpenSystemMarket] 如 'targetMarketPackageName' 为空，是否打开本机自带应用市场，
  ///
  /// 简单来说，如果你有指定的应用市场，就传递 'targetMarketPackageName' 为对应的包名；
  /// 如果你没有指定的应用市场，但是想让大部分机型都打开厂商应用商店，那么就设置 'isOpenSystemMarket' 为true
  Future<bool> openAppMarket(
      {String targetMarketPackageName = "",
      bool isOpenSystemMarket = true}) async {
    final arguments = <String, dynamic>{
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
      debugPrint("openAppMarket: $e");
      return false;
    }
  }

  /// 销毁资源
  void dispose() {
    _channel.setMethodCallHandler(null);
  }

  /// 处理安装返回结果
  String _handleInstallResult(dynamic result, {String from = ""}) {
    print("gfs _handleInstallResult: $result");
    final apkPath = result['apkPath'];
    if (apkPath != null && apkPath is String && apkPath.isNotEmpty) {
      return apkPath;
    }
    debugPrint("EasyAppInstaller.$from error: ${result["errorMessage"]}");
    return "";
  }

}
