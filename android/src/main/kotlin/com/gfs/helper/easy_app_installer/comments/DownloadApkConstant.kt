package com.gfs.helper.easy_app_installer.comments

/**
 * 下载apk文件状态
 */
class DownloadApkConstant {

    companion object {
        //准备下载状态，此时已完成了权限申请
        const val ON_PREPARED = "ON_PREPARED"
        //下载中状态
        const val ON_DOWNLOADING = "ON_DOWNLOADING"
        //下载成功
        const val ON_SUCCESS = "ON_SUCCESS"
        //下载失败
        const val ON_ERROR = "ON_ERROR"
        //取消下载
        const val ON_CANCELED = "ON_CANCELED"
    }

}