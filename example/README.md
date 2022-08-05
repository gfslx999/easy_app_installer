# easy_app_installer

It provides easy installation and upgrade for applications.

* [Download and install apk](#downloadAndInstallApk) - Only support android
* [Cancel downloading task](#cancelDownloadingTask) - Only support android
* [Only install apk](#onlyInstallApk) - Only support android
* [Open AppMarket-Specif the application details page](#openAppMarket) - Support android & iOS
* [Open Setting-Specif the application details page](#openAppSettingDetails) - Support android & iOS

## Preview：[Preview demonstrate](https://github.com/gfslx999/easy_app_installer/blob/master/example/PREVIEW.md)

## 中文文档：[中文文档](https://github.com/gfslx999/easy_app_installer/blob/master/README.md)

## Config

### 1.Configure FileProvider

In `android - app - src - main - res`, to create `xml` directory,
And then, in `xml` to create `file_provider_path.xml` file, content is:

```kotlin
<?xml version="1.0" encoding="utf-8"?>
<paths>
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
At last，Open `android - app - src - main - AndroidManifest.xml`，
In the `application` label, add this：

```kotlin
<provider
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true"
    android:name="androidx.core.content.FileProvider">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_provider_path" />
</provider>
```

example：[example file](https://github.com/gfslx999/easy_app_installer/blob/master/example/android/app/src/main/AndroidManifest.xml)

## How to use

### Installing

[Look at here](https://pub.flutter-io.cn/packages/easy_app_installer/install)

### API Document

On Android 11, granting 'Allow applications to be installed' permissions for the first time causes the application process to shut down. 
This is system behavior and has been fixed in Android 12.

#### <span id="downloadAndInstallApk">1.Download and install apk.</span>

Only support Android

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| fileUrl | Apk url | yes |
| fileDirectory | Folder path (without concatenating backslashes at the beginning and end) | yes |
| fileName | File name (no concatenation backslash required) | yes |
| explainContent | Permission popup hint content | no |
| positiveText | Permission popup confim text | no |
| negativeText | Permission popup cancel text | no |
| isDeleteOriginalFile | Whether to delete the same file if it already exists on the local PC (default:true)) | no |
| downloadListener | Download progress, type is double, 0~100 | no |
| cancelTagListener | The tag used to cancel the task in the download | no |
| stateListener | Changes when the download status changes，Please refer to bottom [Download state](#classDesDownloadState) | no |

In detail, look at here: [example/lib/main.dart](https://github.com/gfslx999/easy_app_installer/blob/master/example/lib/main.dart)

```kotlin
/// Take this example, it's finally path is '/data/user/0/$applicationPackageName/files/updateApk/new.apk'.
///
/// If this method is called consecutively and arguments are passed exactly the same, 
/// the Native end will refuse to perform subsequent tasks until the task in the download completes.
EasyAppInstaller.instance.downloadAndInstallApk(
    fileUrl: "https://xxxx.apk",
    fileDirectory: "updateApk",
    fileName: "new.apk",
    downloadListener: (progress) {
        if (progress < 100) {
            EasyLoading.showProgress(progress / 100, status: "Downloading");
        } else {
            EasyLoading.showSuccess("Success");
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

#### <span id="cancelDownloadingTask">2.Cancel downloading task.</span>

Only support Android

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| cancelTag | Untag the task | yes |

```kotlin
EasyAppInstaller.instance.cancelDownload(_cancelTag);
```

#### 3.<span id="onlyInstallApk">Only install apk.</span>

Only support Android

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| filePath | The absolute path of the apk | yes |
| explainContent | Permission popup hint content | no |
| positiveText | Permission popup confim text | no |
| negativeText | Permission popup cancel text | no |

```kotlin
EasyAppInstaller.instance.installApk(filePath);
```

#### <span id="openAppMarket">4.Open AppMarket - assign application details page.</span>

Only support Android

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| applicationPackageName | Specify the application package name (default: "") | no |
| targetMarketPackageName | Specify the application market package name (default: "") | no |
| isOpenSystemMarket | Whether to open vendor app market (default: true) | no |

```kotlin
/// If 'applicationPackageName' is empty, It will open the current app by default.
/// Attention, the 'targetMarketPackageName' priority is higher than 'isOpenSystemMarket',
/// So just in 'targetMarketPackageName' is empty 'isOpenSystemMarket' will be available。
///
/// In simple terms, if you have a specified app marketplace, pass 'targetMarketPackageName' as the package name;
/// if you don't specify a market, but want the manufacturer's store open on most devices, 
/// set 'isOpenSystemMarket' to true
EasyAppInstaller.instance.openAppMarket();
```

#### 5.Open AppStore assign application details page.

Only support iOS

| Param Name | Param sense | Is require |
| ------ | :------: | :------: |
| appId | The appId generated by Apple for the application | yes |

```kotlin
EasyAppInstaller.instance.openAppStore(appId: "${appId}");
```

#### <span id="openAppSettingDetails">6.Open Setting - assign application details page.</span>

Support Android & iOS

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| applicationPackageName | Specify the application package name (default: "") | no |

```kotlin
/// Android support open specified app Setting details page，if 'applicationPackageName' is empty, will open current app Setting details page;
/// iOS only support open current app Setting details page, need not param to pass.
EasyAppInstaller.instance.openAppSettingDetails(applicationPackageName: "$targetAppPackage");
```

### Class description

#### <span id="classDesDownloadState">Download state</span>

```kotlin
enum EasyAppInstallerState {
    //The status callback comes after permissions have been obtained
    onPrepared,
    onDownloading,
    onSuccess,
    onFailed,
    onCanceled
}
```
