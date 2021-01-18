import 'package:double_tap_player_view/src/model/double_tap_config.dart';
import 'package:double_tap_player_view/src/model/double_tap_model.dart';
import 'package:double_tap_player_view/src/ui/double_tap_animated.dart';
import 'package:double_tap_player_view/src/viewmodel/double_tap_view_model.dart';
import 'package:double_tap_player_view/src/model/swipe_config.dart';
import 'package:double_tap_player_view/src/ui/horizontal_drag_detector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'model/lr.dart';
import 'model/swipe_model.dart';

typedef OnDragCallback = void Function(SwipeData data);

typedef TapCountWidgetBuilder = Widget Function(Lr lr, int tapCount);

typedef TextBuilder = String Function(Lr lr, int tapCount);

final kPrvViewModel = StateNotifierProvider.autoDispose
    .family<DoubleTapViewModel, ViewModelConfig>(
        (ref, conf) => DoubleTapViewModel(conf));

class DoubleTapPlayerView extends StatelessWidget {
  DoubleTapPlayerView({
    Key key,
    this.doubleTapConfig,
    this.child,
    this.swipeConfig,
  })  : enabledDoubleTap = doubleTapConfig != null,
        enabledSwipe = swipeConfig != null;

  final DoubleTapConfig doubleTapConfig;
  final SwipeConfig swipeConfig;
  final Widget child;

  final bool enabledDoubleTap;
  final bool enabledSwipe;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if (child != null) child,
          LayoutBuilder(
            builder: (context, constrains) => SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTapDown: enabledDoubleTap ? (details) =>
                    _onDoubleTapDown(context, constrains, details) : null,
                onDoubleTap: enabledDoubleTap ? () => _onDoubleTap(context, constrains) : null,
                onHorizontalDragStart: enabledSwipe ? (details) =>
                    _onDragStart(context, details) : null,
                onHorizontalDragUpdate: enabledSwipe ? (details) =>
                    _onDragUpdate(context, details) : null,
                onHorizontalDragCancel: enabledSwipe ? () => _onDragCancel(context) : null,
                onHorizontalDragEnd: enabledSwipe ? (details) => _onDragEnd(context, details) : null,
                child: Stack(
                  children: [
                    if (enabledDoubleTap)
                      DoubleTapWidget(
                        config: doubleTapConfig,
                        enabledDrag: enabledSwipe,
                      ),
                    if (enabledSwipe)
                      DragOverlayWrapper(
                        backDrop: swipeConfig.backDrop,
                        overlayBuilder: swipeConfig.overlayBuilder,
                        vmConfR: doubleTapConfig.vmConfR,
                        vmConfL: doubleTapConfig.vmConfL,
                        enableDoubleTap: enabledDoubleTap,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  void _onDoubleTapDown(BuildContext context, BoxConstraints constraints,
      TapDownDetails details) {
    final centerX = constraints.maxWidth / 2;
    final vmConf = details.localPosition.dx < centerX
        ? doubleTapConfig.vmConfL
        : doubleTapConfig.vmConfR;
    final dx = vmConf == doubleTapConfig.vmConfL
        ? details.localPosition.dx
        : details.localPosition.dx - centerX;
    final dy = details.localPosition.dy;
    context.read(kPrvViewModel(vmConf)).noteTapPosition(dx, dy);
  }

  void _onDoubleTap(BuildContext context, BoxConstraints constraints) {
    final lastTapTimeL =
        context.read(kPrvViewModel(doubleTapConfig.vmConfL).state).lastTapTime;
    final lastTapTimeR =
        context.read(kPrvViewModel(doubleTapConfig.vmConfR).state).lastTapTime;
    final vmConf = lastTapTimeL < lastTapTimeR
        ? doubleTapConfig.vmConfR
        : doubleTapConfig.vmConfL;

    context.read(kPrvViewModel(vmConf)).notifyTap(constraints.maxWidth);
    if (doubleTapConfig.onDoubleTap != null) doubleTapConfig.onDoubleTap();
  }

  void _onDragStart(BuildContext context, DragStartDetails details) =>
      context.read(kPrvDragVm).setStart(details.globalPosition.dx);

  void _onDragUpdate(BuildContext context, DragUpdateDetails details) =>
      context.read(kPrvDragVm).update(details.globalPosition.dx);

  void _onDragCancel(BuildContext context) => context.read(kPrvDragVm).clear();

  void _onDragEnd(BuildContext context, DragEndDetails details) {
    final data = context.read(kPrvDragVm.state).data.copyWith();
    context.read(kPrvDragVm).clear();
    if (swipeConfig.onDragEnd != null) swipeConfig.onDragEnd(data);
  }
}
