# easy_app_installer

为Flutter提供简便的应用内升级（暂时仅支持安卓）

* 下载并安装apk (已处理相关权限)
* 取消下载中的任务
* 仅安装apk
* 跳转到应用市场-指定应用详情页
* 跳转到设置-指定应用详情页

## 效果：[效果演示](https://github.com/gfslx999/easy_app_installer/blob/master/example/PREVIEW.md)

## English document：[English document](https://github.com/gfslx999/easy_app_installer/blob/master/example/README.md)

## 配置

1.如果要使用应用内升级的相关功能，则需要配置 FileProvider

在 `android - app - src - main - res` 下，新建 `xml` 文件夹， 随后在 `xml` 内新建 `file_provider_path.xml` 文件，内容如下:

```kotlin
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <root-path name="root" path="."/>
    
    <files-path
    name="files"
    path="."/>
    
    <cache-path
    name="cache"
    path="."/>
    
    <external-path
    name="external"
    path="."/>
    
    <external-cache-path
    name="external_cache"
    path="."/>
    
    <external-files-path
    name="external_file"
    path="."/>
</paths>
```

最后，打开 `android - app - src - main - AndroidManifest.xml` 文件， 在 `application` 标签下添加：

```kotlin
<provider
android:authorities = "${applicationId}.fileprovider"
android:exported = "false"
android:grantUriPermissions = "true"
android:name = "androidx.core.content.FileProvider">
    <meta-data
    android:name = "android.support.FILE_PROVIDER_PATHS"
    android:resource = "@xml/file_provider_path" />
</provider >
```

示例：[示例文件](https://github.com/gfslx999/easy_app_installer/blob/master/example/android/app/src/main/AndroidManifest.xml)

## 使用

### 安装

在 pubspec.yaml 内：

```kotlin
dependencies:
easy_app_installer: ^$latestVersion
```

latestVersion: [latestVersion](https://pub.flutter-io.cn/packages/easy_app_installer/install)

### 导入

在要使用的类中：

```kotlin
import 'package:easy_app_installer/easy_app_installer.dart';
```

### 文档说明

#### `注意：所有API已经在内部处理了相关的权限，无需再次进行处理。`

在Android 11上，首次同意'允许安装应用'权限会造成应用进程关闭，这是系统行为，这个问题在Android 12上已经修复。

#### 1.下载并安装apk

| 参数名称 | 参数意义 | 是否必传 |
| ------ | :------: | :------: |
| fileUrl | 要下载apk的url地址 | 是 |
| fileDirectory | 文件夹路径(首尾无须拼接反斜杠) | 是 |
| fileName | 文件名称(无需拼接反斜杠) | 是 |
| explainContent | Android 6 ~ 10 中自定义权限弹窗的提示内容 | 否 |
| positiveText | Android 6 ~ 10 中自定义权限弹窗的确认文字内容 | 否 |
| negativeText | Android 6 ~ 10 中自定义权限弹窗的取消文字内容 | 否 |
| isDeleteOriginalFile | 如果本地已存在相同文件，是否要删除(默认为true) | 否 |
| downloadListener | 下载进度回调，double类型，值为 0~100 | 否 |
| cancelTagListener | 回调用于取消下载中任务的tag | 否 |
| stateListener | 下载状态变化时改变，详请请参考底部[下载状态](#classDesDownloadState) | 否 |

[参考](https://github.com/gfslx999/easy_app_installer/blob/master/example/lib/main.dart)

```kotlin
String _cancelTag = "";

/// 当前这个示例最终生成的文件路径就是 '/data/user/0/$applicationPackageName/files/updateApk/new.apk'
/// 如果我想指定两层目录怎么办呢，很简单，只需要将 [fileDirectory] 设置为 'updateApk/second'
/// 那么他就会生成 '/data/user/0/$applicationPackageName/files/updateApk/second/new.apk'
///
/// 如果连续调用此方法，并且参数传递的完全一致，那么Native端将拒绝执行后续任务，直到下载中的任务执行完毕。
EasyAppInstaller.instance.downloadAndInstallApk(
    fileUrl: "https://xxxx.apk",
    fileDirectory: "updateApk",
    fileName: "new.apk",
    downloadListener: (progress) {
        if (progress < 100) {
            EasyLoading.showProgress(progress / 100, status: "下载中");
        } else {
            EasyLoading.showSuccess("下载成功");
        }
    },
    cancelTagListener: (cancelTag) {
        _cancelTag = cancelTag;
    },
    stateListener: (newState, attachParam) {
        _handleDownloadStateChanged(newState, attachParam);
    }
);
```

#### 2.取消下载中的任务

| 参数名称 | 参数意义 | 是否必传 |
| ------ | :------: | :------: |
| cancelTag | 要取消任务的tag | 是 |

```kotlin
EasyAppInstaller.instance.cancelDownload(_cancelTag);
```

#### 3.仅安装apk

| 参数名称 | 参数意义 | 是否必传 |
| ------ | :------: | :------: |
| filePath | apk文件的绝对路径 | 是 |

```kotlin
EasyAppInstaller.instance.installApk(filePath);
```

#### 4.跳转到应用市场-当前应用页面

| 参数名称 | 参数意义 | 是否必传 |
| ------ | :------: | :------: |
| applicationPackageName | 指定应用包名(默认为空) | 否 |
| targetMarketPackageName | 指定应用市场包名(默认为空) | 否 |
| isOpenSystemMarket | 是否打开厂商应用市场(默认为true) | 否 |

```kotlin
/// 'applicationPackageName' 如果为空，则默认打开当前应用。
/// 注意，'targetMarketPackageName' 的优先级是高于 'isOpenSystemMarket' 的，
/// 所以仅在 'targetMarketPackageName' 为空的情况下 'isOpenSystemMarket' 才会生效。
///
/// 简单来说，如果你有指定的应用市场，就传递 'targetMarketPackageName' 为对应的包名；
/// 如果你没有指定的应用市场，但是想让大部分机型都打开厂商应用商店，那么就设置 'isOpenSystemMarket' 为true
EasyAppInstaller.instance.openAppMarket();
```

#### 5.跳转到设置-指定应用详情页

| 参数名称 | 参数意义 | 是否必传 |
| ------ | :------: | :------: |
| applicationPackageName | 指定应用包名(默认为空) | 否 |

```kotlin
/// 'applicationPackageName' 如果为空，则默认打开当前应用。
EasyAppInstaller.instance.openAppSettingDetails(applicationPackageName: "$targetAppPackage");
```

### 类说明

#### <span id="classDesDownloadState">下载状态</span>

```kotlin
enum EasyAppInstallerState {
    //准备下载 (该状态回调在获取到权限之后)
    onPrepared,
    //下载中
    onDownloading,
    //下载成功
    onSuccess,
     //下载失败
    onFailed,
    //取消下载
    onCanceled
}
```

