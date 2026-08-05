import 'package:flutter/material.dart';

class AnimatedIndexedStack extends StatefulWidget { // Distance for the subtle slide (e.g., 0.03 = 3%)

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = 0.03,
  });
  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;
  final double slideOffset;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;

  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _initAnimations();
    _controller.forward().then((_) {
      _previousIndex = _currentIndex;
    });
  }

  void _initAnimations() {
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _leftSlideAnimation = Tween<Offset>(
      begin: Offset(-widget.slideOffset, 0.0), // Subtle slide from the right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _rightSlideAnimation = Tween<Offset>(
      begin: Offset(widget.slideOffset, 0.0), // Subtle slide from the right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      setState(() {
        _currentIndex = widget.index;
      });
      _controller.forward(from: 0.0).then((_) {
        _previousIndex = _currentIndex;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final bool isSelected = i == _currentIndex;

        return IgnorePointer(
          ignoring: !isSelected,
          child: TickerMode(
            enabled: isSelected,
            child: Visibility(
              visible: isSelected,
              maintainState:
                  true, // Keeps state (scroll positions, form data, etc.)
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _currentIndex < _previousIndex
                          ? _leftSlideAnimation
                          : _rightSlideAnimation,
                      child: child,
                    ),
                  );
                },
                child: widget.children[i],
              ),
            ),
          ),
        );
      }),
    );
  }
}
