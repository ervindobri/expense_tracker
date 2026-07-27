import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HeightCrossFade extends StatefulWidget {
  const HeightCrossFade({
    super.key,
    required this.showFirst,
    required this.first,
    required this.second,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  });
  final bool showFirst;
  final Widget first;
  final Widget second;
  final Duration duration;
  final Curve curve;

  @override
  State<HeightCrossFade> createState() => _HeightCrossFadeState();
}

class _HeightCrossFadeState extends State<HeightCrossFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.showFirst ? 0 : 1,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  late final GlobalKey _firstKey;
  late final GlobalKey _secondKey;
  double? _firstHeight;
  double? _secondHeight;

  @override
  void initState() {
    super.initState();
    _firstKey = GlobalKey();
    _secondKey = GlobalKey();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  @override
  void didUpdateWidget(covariant HeightCrossFade old) {
    super.didUpdateWidget(old);
    if (old.showFirst != widget.showFirst) {
      widget.showFirst ? _controller.reverse() : _controller.forward();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  void _remeasure() {
    if (!mounted) {
      return;
    }
    final firstBox = _firstKey.currentContext?.findRenderObject() as RenderBox?;
    final secondBox =
        _secondKey.currentContext?.findRenderObject() as RenderBox?;
    final h1 = (firstBox?.hasSize ?? false)
        ? firstBox!.size.height
        : _firstHeight;
    final h2 = (secondBox?.hasSize ?? false)
        ? secondBox!.size.height
        : _secondHeight;
    if (h1 != _firstHeight || h2 != _secondHeight) {
      setState(() {
        _firstHeight = h1;
        _secondHeight = h2;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _layer({
    required Widget child,
    required Key key,
    required double opacity,
    required double dx,
    required double scale,
  }) {
    return IgnorePointer(
      ignoring: opacity < 0.05,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(dx)
            // ignore: deprecated_member_use
            ..scale(scale),
          child: KeyedSubtree(
            key: key,
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value; // 0 = first fully shown, 1 = second fully shown
        const slideDistance = 24.0; // px, tweak to taste

        final height = (_firstHeight != null && _secondHeight != null)
            ? _firstHeight! + (_secondHeight! - _firstHeight!) * t
            : (_firstHeight ?? _secondHeight);

        return ClipRect(
          clipBehavior: Clip.none,
          child: SizedBox(
            height: height,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0.0,
              maxHeight: MediaQuery.sizeOf(
                context,
              ).height, // was: double.infinity
              fit: OverflowBoxFit.deferToChild,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  _layer(
                    key: _firstKey,
                    opacity: 1 - t,
                    dx: -slideDistance * t,
                    scale: 1 - 0.06 * t,
                    child: widget.first,
                  ),
                  _layer(
                    key: _secondKey,
                    opacity: t,
                    dx: slideDistance * (1 - t),
                    scale: 0.94 + 0.06 * t,
                    child: widget.second,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
