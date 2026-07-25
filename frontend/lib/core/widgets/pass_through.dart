import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PassthroughContainer extends SingleChildRenderObjectWidget {
  final double topPassThroughHeight;
  final bool enabled;

  const PassthroughContainer({
    super.key,
    required this.topPassThroughHeight,
    required super.child, this.enabled = true,
  });

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
  double topPassThroughHeight;
  bool enabled;

  RenderPassthroughContainer({required this.topPassThroughHeight, required this.enabled});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If touch falls within the transparent top area, pass it through to BalanceView
    if (enabled && position.dy < topPassThroughHeight) {
      return false; 
    }
    return super.hitTest(result, position: position);
  }
}