import 'package:flutter/widgets.dart';

class HalfwaySnapPhysics extends ClampingScrollPhysics {

  const HalfwaySnapPhysics({
    super.parent,
    required this.snapExtent,
  });
  // The pixel extent of the "snap zone" — e.g. balanceHeight.
  // Below this, physics snaps to 0 or snapExtent. Beyond it, normal scrolling.
  final double snapExtent;

  @override
  HalfwaySnapPhysics applyTo(ScrollPhysics? ancestor) {
    return HalfwaySnapPhysics(
      parent: buildParent(ancestor),
      snapExtent: snapExtent,
    );
  }

  SpringDescription get _spring => SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100.0,
        ratio: 1.1,
      );

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final bool pastSnapZone = position.pixels > snapExtent;
    final bool atEdge =
        (velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
            (velocity >= 0.0 && position.pixels >= position.maxScrollExtent);

    // Once we're past the snap zone (or at a true scroll boundary),
    // hand off to normal fling/clamping behavior — no more snapping.
    if (pastSnapZone || atEdge) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double target = position.pixels >= snapExtent / 2
        ? snapExtent
        : 0.0;

    if (target == position.pixels) {
      return null;
    }

    return ScrollSpringSimulation(
      _spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}