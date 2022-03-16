package com.gfs.helper.easy_app_installer.model

import com.gfs.helper.easy_app_installer.comments.InstallApkState
import io.flutter.plugin.common.MethodChannel

data class InstallApkModel(
    //刚刚是否进入 '允许安装其他应用' 界面
    var isIntoOpenPermissionPage: Boolean = false,
    var currentState: InstallApkState = InstallApkState.NONE,
    var arguments: Map<*, *>? = null,
    var result: MethodChannel.Result? = null
) {

    fun copyWith(
        isIntoOpenPermissionPage: Boolean? = null,
        currentState: InstallApkState? = null,
        arguments: Map<*, *>? = null,
        result: MethodChannel.Result? = null
    ) : InstallApkModel {
        return InstallApkModel(
            isIntoOpenPermissionPage ?: this.isIntoOpenPermissionPage,
            currentState ?: this.currentState,
            arguments ?: this.arguments,
            result ?: this.result
        )
    }

}