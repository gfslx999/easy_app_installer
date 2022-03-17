# easy_app_installer

It provides easy installation and upgrade for applications.

* Download and install apk (Related permissions have been processed).
* Cancel downloading task.
* Only install apk (Related permissions have been processed).
* Jump to AppMarket-Current application details page.

Results：[Results demonstrate](https://github.com/gfslx999/easy_app_installer/blob/master/example/PREVIEW.md)

中文文档：[中文文档](https://github.com/gfslx999/easy_app_installer/blob/master/README.md)

## Config

### 1.In `android - build.gradle`，find:
```kotlin
ext.kotlin_version = '1.3.10'
```
or
```kotlin
classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.3.10"
```
Change `1.3.10` to `1.5.20`.

### 2.Configure FileProvider

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

In pubspec.yaml：

```kotlin
dependencies:
  easy_app_installer: ^$latestVersion
```
latestVersion: [latestVersion](https://pub.flutter-io.cn/packages/flutter_native_helper/install)

### Import

In the class to be used:

```kotlin
import 'package:easy_app_installer/easy_app_installer.dart';
```

### API Document

#### `Note: All apis already handle the related permissions internally and do not need to do so again.`

On Android 11, granting permissions for the first time causes the application process to shut down. 
This is system behavior and has been fixed in Android 12.

#### 1.Download and install apk

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| fileUrl | Apk url | yes |
| fileDirectory | Folder path (without concatenating backslashes at the beginning and end) | yes |
| fileName | File name (no concatenation backslash required) | yes |
| isDeleteOriginalFile | Whether to delete the same file if it already exists on the local PC (default:true)) | no |
| downloadListener | Download progress, type is double, 0~100 | no |
| cancelTagListener | The tag used to cancel the task in the download | no |

```kotlin
String _cancelTag = "";

/// Take this example, it's finally path is '/data/user/0/$applicationPackageName/files/updateApk/new.apk'.
/// What if I want to specify two levels of directories, very simple, just set [fileDirectory] to 'updateApk/second'.
/// And then, it will generate '/data/user/0/$applicationPackageName/files/updateApk/second/new.apk'.
///
/// If this method is called consecutively and arguments are passed exactly the same, 
/// the Native end will refuse to perform subsequent tasks until the task in the download completes.
EasyAppInstaller.instance.downloadAndInstallApp(
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
    }
);
```

#### 2.Cancel downloading task

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| cancelTag | Untag the task | yes |

```kotlin
EasyAppInstaller.instance.cancelDownload(_cancelTag);
```

#### 3.Only install apk

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| filePath | The absolute path of the apk | yes |

```kotlin
EasyAppInstaller.instance.installApk(filePath);
```

#### 4.Jump to AppMarket-Current application details page.

| Param name | Param sense | Is require |
| ------ | :------: | :------: |
| targetMarketPackageName | Specify the application market package name (default: "") | no |
| isOpenSystemMarket | Whether to open vendor app market (default: true) | no |

```kotlin
/// Attention, the 'targetMarketPackageName' priority is higher than 'isOpenSystemMarket',
/// So just in 'targetMarketPackageName' is empty 'isOpenSystemMarket' will be available。
///
/// In simple terms, if you have a specified app marketplace, pass 'targetMarketPackageName' as the package name;
/// if you don't specify a market, but want the manufacturer's store open on most devices, 
/// set 'isOpenSystemMarket' to true
EasyAppInstaller.instance.openAppMarket();
```