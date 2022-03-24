package com.gfs.helper.easy_app_installer

import android.app.Activity
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import com.fs.freedom.basic.helper.AppHelper
import com.fs.freedom.basic.helper.DownloadHelper
import com.fs.freedom.basic.helper.SystemHelper
import com.fs.freedom.basic.listener.CommonResultListener
import com.fs.freedom.basic.util.LogUtil
import com.gfs.helper.easy_app_installer.comments.CustomLifecycleObserver
import com.gfs.helper.easy_app_installer.comments.DownloadApkConstant
import com.gfs.helper.easy_app_installer.comments.InstallApkState
import com.gfs.helper.easy_app_installer.model.InstallApkModel

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** EasyAppInstallerPlugin */
class EasyAppInstallerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {

  private lateinit var mChannel : MethodChannel
  private var mInstallApkModel = InstallApkModel()
  private var mCurrentDownloadingState = DownloadApkConstant.ON_PREPARED
  private var mActivity: Activity? = null
  private var mLifecycle: Lifecycle? = null
  private val mLifecycleObserver = object : CustomLifecycleObserver {
    override fun onResume() {
      //校验是否获取到了权限
      if (mInstallApkModel.isIntoOpenPermissionPage) {
        when (mInstallApkModel.currentState) {
          InstallApkState.INSTALL -> {
            installApk(mInstallApkModel.arguments, mInstallApkModel.result)
          }
          InstallApkState.DOWNLOAD_AND_INSTALL -> {
            downloadAndInstallApk(mInstallApkModel.arguments, mInstallApkModel.result)
          }
          else -> {}
        }
      }
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    mChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "easy_app_installer")
    mChannel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    val arguments = call.arguments as Map<*, *>?
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "installApk" -> {
        installApk(arguments, result)
      }
      "downloadAndInstallApk" -> {
        downloadAndInstallApk(arguments, result)
      }
      "cancelDownload" -> {
        cancelDownload(arguments, result)
      }
      "openAppMarket" -> {
        openAppMarket(arguments, result)
      }
      "openAppSettingDetail" -> {
        openSettingAppDetails(arguments, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  /**
   * 打开设置-指定应用详情页
   */
  private fun openSettingAppDetails(arguments: Map<*, *>?, result: Result) {
    val applicationPackageName = arguments?.get("applicationPackageName") as String? ?: ""

    val openAppSettingDetail =
      AppHelper.openAppSettingDetail(mActivity, applicationPackageName = applicationPackageName)
    if (openAppSettingDetail) {
      result.success(true)
    } else {
      result.error("openSettingAppDetails", "open failed", "")
    }
  }

  /**
   * 打开应用市场-指定应用详情页
   */
  private fun openAppMarket(arguments: Map<*, *>?, result: Result) {
    val targetMarketPackageName = arguments?.get("targetMarketPackageName") as String? ?: ""
    val isOpenSystemMarket = arguments?.get("isOpenSystemMarket") as Boolean? ?: true
    val applicationPackageName = arguments?.get("applicationPackageName") as String? ?: ""

    val openResult = AppHelper.openAppMarket(
      mActivity,
      applicationPackageName = applicationPackageName,
      targetMarketPackageName = targetMarketPackageName,
      isOpenSystemMarket = isOpenSystemMarket
    )

    if (openResult) {
      result.success(true)
    } else {
      result.error("openAppMarket", "open market failed!", "")
    }
  }

  /**
   * 下载apk并安装
   */
  private fun downloadAndInstallApk(arguments: Map<*, *>?, result: Result?) {
    val fileUrl = arguments?.get("fileUrl") as String? ?: ""
    val fileDirectory = arguments?.get("fileDirectory") as String? ?: ""
    val fileName = arguments?.get("fileName") as String? ?: ""
    val isDeleteOriginalFile = arguments?.get("isDeleteOriginalFile") as Boolean? ?: true
    val explainContent = arguments?.get("explainContent") as String?
    val positiveText = arguments?.get("positiveText") as String?
    val negativeText = arguments?.get("negativeText") as String?

    mInstallApkModel = mInstallApkModel.copyWith(
      arguments = arguments,
      result = result,
      currentState = InstallApkState.DOWNLOAD_AND_INSTALL
    )

    SystemHelper.downloadAndInstallApk(
      activity = mActivity,
      fileUrl = fileUrl,
      filePath = "${mActivity?.filesDir}/$fileDirectory/",
      fileName = fileName,
      isDeleteOriginalFile = isDeleteOriginalFile,
      explainContent = explainContent,
      positiveText = positiveText,
      negativeText = negativeText,
      commonResultListener = object :CommonResultListener<File> {
        override fun onStart(attachParam: Any?) {
          resultCancelTag(attachParam)
          mInstallApkModel.isIntoOpenPermissionPage = false
        }

        override fun onSuccess(file: File) {
          resultDownloadState(DownloadApkConstant.ON_SUCCESS, apkFilePath = file.absolutePath)

          result?.success(true)
        }

        override fun onError(message: String) {
          if (message == SystemHelper.OPEN_INSTALL_PACKAGE_PERMISSION) {
            mInstallApkModel.isIntoOpenPermissionPage = true
          } else {
            result?.error("0", message, "")

            //由于取消下载也会回调 onError，所以要保证取消时仅回调 onCanceled
            if (mCurrentDownloadingState != DownloadApkConstant.ON_CANCELED) {
              resultDownloadState(DownloadApkConstant.ON_ERROR, message)
            }
          }
        }

        override fun onProgress(currentProgress: Float) {
          if (mCurrentDownloadingState == DownloadApkConstant.ON_PREPARED) {
            resultDownloadState(DownloadApkConstant.ON_DOWNLOADING)
          }
          resultDownloadProgress(currentProgress)
        }
      }
    )
  }

  /**
   * 取消下载
   */
  private fun cancelDownload(arguments: Map<*, *>?, result: Result?) {
    val cancelTag = arguments?.get("cancelTag") as String? ?: ""
    if (cancelTag.isEmpty()) {
      result?.error("cancelDownload", "cancelTag is must not be null!", "")
      return
    }
    DownloadHelper.cancelDownload(cancelTag)
    result?.success(true)

    //仅在 onPrepared 或 onDownloading 状态下允许回调 onCanceled
    if (mCurrentDownloadingState == DownloadApkConstant.ON_DOWNLOADING ||
      mCurrentDownloadingState == DownloadApkConstant.ON_PREPARED) {
      resultDownloadState(DownloadApkConstant.ON_CANCELED)
    }
  }

  /**
   * 安装apk
   */
  private fun installApk(arguments: Map<*, *>?, result: Result?) {
    val filePath = arguments?.get("filePath") as String? ?: ""
    val explainContent = arguments?.get("explainContent") as String?
    val positiveText = arguments?.get("positiveText") as String?
    val negativeText = arguments?.get("negativeText") as String?

    if (filePath.isNotEmpty()) {
      mInstallApkModel = mInstallApkModel.copyWith(
        arguments = arguments,
        result = result,
        currentState = InstallApkState.INSTALL
      )
      SystemHelper.installApk(
        mActivity,
        apkFile = File(filePath),
        explainContent = explainContent,
        positiveText = positiveText,
        negativeText = negativeText,
        commonResultListener = object : CommonResultListener<File> {
        override fun onStart(attachParam: Any?) {
          mInstallApkModel.isIntoOpenPermissionPage = false
        }

        override fun onSuccess(file: File) {
          val map = mapOf<String, Any>(
            "apkPath" to file.absolutePath
          )
          result?.success(map)
        }

        override fun onError(message: String) {
          if (message == SystemHelper.OPEN_INSTALL_PACKAGE_PERMISSION) {
            mInstallApkModel.isIntoOpenPermissionPage = true
          } else {
            result?.error("0", message, "")
          }
        }

      })
    } else {
      result?.error("0", "installApk：file path can't be empty!", "")
    }
  }

  /**
   * 回调下载进度
   */
  private fun resultDownloadProgress(progress: Float) {
    mChannel.invokeMethod("resultDownloadProgress", progress)
  }

  /**
   * 回调用于取消下载的 cancelTag
   */
  private fun resultCancelTag(attachParam: Any?) {
    if (attachParam is String && attachParam.isNotEmpty()) {
      mChannel.invokeMethod("resultCancelTag", attachParam)
    } else {
      //如果 attachParam 不为空，说明为首次 onStart 回调
      resultDownloadState(DownloadApkConstant.ON_PREPARED)
    }
  }

  /**
   * 回调当前下载状态
   *
   * [newState] 参见[DownloadApkConstant]
   * [apkFilePath] apk文件路径，仅在下载成功时传递
   * [errorMsg] 错误信息，仅在下载失败时传递
   */
  private fun resultDownloadState(newState: String, apkFilePath: String = "", errorMsg: String = "") {
    if (newState.isEmpty()) {
      return
    }

    val map = mutableMapOf<String, Any>()
    map["newState"] = newState
    if (apkFilePath.isNotEmpty()) {
      map["apkFilePath"] = apkFilePath
    }
    if (errorMsg.isNotEmpty()) {
      map["errorMsg"] = errorMsg
    }

    mChannel.invokeMethod("resultDownloadState", map)
    mCurrentDownloadingState = newState
  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    mChannel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    mActivity = binding.activity
    mLifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
    mLifecycle?.addObserver(mLifecycleObserver)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    mActivity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    mActivity = binding.activity
  }

  override fun onDetachedFromActivity() {
    mActivity = null
    mLifecycle?.removeObserver(mLifecycleObserver)
    mLifecycle = null
  }

}
