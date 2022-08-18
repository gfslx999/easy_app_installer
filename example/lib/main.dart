import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:easy_app_installer/easy_app_installer.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:just_debounce_it/just_debounce_it.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _cancelTag = "";
  String _apkFilePath = "";
  String _currentDownloadStateCH = "当前下载状态：还未开始";

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    String platformVersion;
    try {
      platformVersion = await EasyAppInstaller.instance.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    // await dotenv.load(fileName: "assets/testdata.env");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_currentDownloadStateCH),
              _buildButton("打开AppStore", () async {
                // final appId = dotenv.get("IOS_APP_ID", fallback: "");
                final openAppStoreResult =
                    await EasyAppInstaller.instance.openAppStore("appId");
                print("gfs openAppStoreResult: $openAppStoreResult");
              }, autoFocus: true),
              _buildButton('下载并安装apk', () {
              }),
              _buildButton('取消下载任务', () {
                if (_cancelTag.isNotEmpty) {
                  EasyLoading.dismiss();
                  EasyAppInstaller.instance.cancelDownload(_cancelTag);
                } else {
                  EasyLoading.showError("没有下载中的任务");
                }
              }),
              _buildButton('仅安装', () async {
                final path =
                    await EasyAppInstaller.instance.installApk(_apkFilePath);
                print("gfs installApk: $path");
              }),
              _buildButton('打开应用市场', () {
                // EasyAppInstaller.instance.openAppMarket();
                Debounce.duration(const Duration(seconds: 2), () {
                  EasyLoading.showToast("执行---打开应用市场");
                  print("执行---打开应用市场");
                });
              }),
              _buildButton('打开设置详情页', () async {
                // final openResult =
                //     await EasyAppInstaller.instance.openAppSettingDetails();
                // print("gfs openResult: $openResult");
                // EasyLoading.showToast("执行---打开设置详情页");
                target () {
                  EasyLoading.showToast("执行---打开设置详情页");
                  print("执行---打开设置详情页");
                }
                print("_lastTarget: $_lastTarget, target: $target, ===: ${_lastTarget == target}");
                _lastTarget = target;
                Debounce.duration(const Duration(seconds: 2), target);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Function? _lastTarget;

  void downloadAndInstalApk() async {
    //fileUrl需替换为指定apk地址
    await EasyAppInstaller.instance.downloadAndInstallApk(
        fileUrl: "dotenv.get("", fallback: "")",
        fileDirectory: "updateApk",
        fileName: "newApk.apk",
        explainContent: "快去开启权限！！！",
        onDownloadingListener: (progress) {
          if (progress < 100) {
            EasyLoading.showProgress(progress / 100, status: "下载中");
          } else {
            EasyLoading.showSuccess("下载成功");
          }
        },
        onCancelTagListener: (cancelTag) {
          _cancelTag = cancelTag;
        },
        onStateListener: (newState, attachParam) {
          _handleDownloadStateChanged(newState, attachParam);
        });
  }

  /// 处理下载状态更改
  void _handleDownloadStateChanged(
      EasyAppInstallerState newState, String? attachParam) {
    switch (newState) {
      case EasyAppInstallerState.onPrepared:
        _currentDownloadStateCH = "当前下载状态：开始下载";
        break;
      case EasyAppInstallerState.onDownloading:
        _currentDownloadStateCH = "当前下载状态：下载中";
        break;
      case EasyAppInstallerState.onSuccess:
        if (attachParam != null) {
          _currentDownloadStateCH = "当前下载状态：下载成功, $attachParam";
          _apkFilePath = attachParam;
        }
        break;
      case EasyAppInstallerState.onFailed:
        _currentDownloadStateCH = "当前下载状态：下载失败, $attachParam";
        break;
      case EasyAppInstallerState.onCanceled:
        _currentDownloadStateCH = "当前下载状态：取消下载";
        break;
    }
    setState(() {});
  }

  Widget _buildButton(String text, Function function, {
    bool autoFocus = false,
  }) {
    return InkWell(
      onTap: () {
        function();
      },
      child: IntrinsicWidth(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          color: Colors.blue,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
    // return UsefulFocusParent(
    //   onClickListener: () {
    //     function();
    //   },
    //   intervalMillSeconds: 1000,
    //   autoFocus: autoFocus,
    //   childBuilder: ((hasFocus) {
    //     final backgroundColor = hasFocus ? Colors.blue : Colors.pink;
    //     return IntrinsicWidth(
    //       child: Container(
    //         margin: const EdgeInsets.only(top: 8),
    //         color: backgroundColor,
    //         child: Center(
    //           child: Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    //             child: Text(
    //               text,
    //               style: const TextStyle(color: Colors.white),
    //             ),
    //           ),
    //         ),
    //       ),
    //     );
    //   }),
    // );
    // return UsefulFocusParent(
    //     intervalMillSeconds: 1000,
    //     autoFocus: autoFocus,
    //     child: IntrinsicWidth(
    //       child: Container(
    //         color: Colors.blue,
    //         child: Center(
    //           child: Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    //             child: Text(
    //               text,
    //               style: const TextStyle(color: Colors.white),
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //     onClickListener: () {
    //       function();
    //     });
  }

  @override
  void dispose() {
    EasyAppInstaller.instance.dispose();
    super.dispose();
  }
}
