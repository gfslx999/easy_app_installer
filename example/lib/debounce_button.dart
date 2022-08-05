
import 'package:flutter/material.dart';

/// 用于防止重复点击的按钮
class DebounceButton extends StatefulWidget {
  const DebounceButton({
    Key? key,
    required this.child,
    required this.onClickListener,
    this.intervelMillSeconds = 1000,
    this.margin,
  }) : super(key: key);

  /// 子控件，不要在子控件内处理点击事件，请使用 [onClickListener]
  final Widget child;
  /// 点击回调
  final VoidCallback onClickListener;
  /// 间隔时长，单位：毫秒
  final int intervelMillSeconds;
  final EdgeInsetsGeometry? margin;

  @override
  State<DebounceButton> createState() => _DebounceButtonState();
}

class _DebounceButtonState extends State<DebounceButton> {
  // 上次点击生效的时间
  int _currentLastTakeEffectClickTime = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        onTap: () {
          //todo 排查为何两个组件点击会受到影响
          print("gfs before _currentLastTakeEffectClickTime: $_currentLastTakeEffectClickTime");
          _currentLastTakeEffectClickTime = preventDoubleClick(
              widget.onClickListener,
              intervelMillSeconds: widget.intervelMillSeconds,
              lastTakeEffectClickTime: _currentLastTakeEffectClickTime
          );
          print("gfs after _currentLastTakeEffectClickTime: $_currentLastTakeEffectClickTime");
        },
        child: widget.child,
      ),
    );
  }
}

/// 上次点击生效的时间
int _lastTakeEffectClickTime = 0;

/// 防止重复点击
///
/// [func] 要执行的方法
/// [intervelMillSeconds] 防止重复点击的间隔
/// [lastTakeEffectClickTime] 用于自己定义上次点击生效的时间，无需传递此值
int preventDoubleClick(VoidCallback func,{
  required int intervelMillSeconds,
  int? lastTakeEffectClickTime
}) {
  final currentTime = DateTime.now().millisecondsSinceEpoch;
  // 获取上次点击生效的时间
  int useLastTakeEffectClickTime = lastTakeEffectClickTime ?? _lastTakeEffectClickTime;
  // 判断当前时间与上次点击时间是否已经大于了指定间隔
  if (currentTime - useLastTakeEffectClickTime >= intervelMillSeconds) {
    func();
    // 更新点击生效时间时间
    useLastTakeEffectClickTime = currentTime;
    if (lastTakeEffectClickTime == null) {
      _lastTakeEffectClickTime = currentTime;
    }
  }
  return useLastTakeEffectClickTime;
}