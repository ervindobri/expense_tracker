import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PassthroughContainer extends SingleChildRenderObjectWidget {

  const PassthroughContainer({
    super.key,
    required this.topPassThroughHeight,
    required super.child, this.enabled = true,
  });
  final double topPassThroughHeight;
  final bool enabled;

  @override
  RenderPassthroughContainer createRenderObject(BuildContext context) {
    return RenderPassthroughContainer(topPassThroughHeight: topPassThroughHeight, enabled: enabled);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPassthroughContainer renderObject) {
    renderObject.topPassThroughHeight = topPassThroughHeight;
    renderObject.enabled = enabled;
  }
}

class RenderPassthroughContainer extends RenderProxyBox {

  RenderPassthroughContainer({required this.topPassThroughHeight, required this.enabled});
  double topPassThroughHeight;
  bool enabled;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If touch falls within the transparent top area, pass it through to BalanceView
    if (enabled && position.dy < topPassThroughHeight) {
      return false; 
    }
    return super.hitTest(result, position: position);
  }
}