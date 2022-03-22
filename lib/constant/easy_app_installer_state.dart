/// 下载apk state
enum EasyAppInstallerState {
  //准备下载，该回调在获取到权限之后
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
