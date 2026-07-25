// core/widgets/context_menu_overlay.dart
import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/widgets/blurred_container.dart';

/// iOS-style context menu overlay: shows a list of items without selection state.
/// Opens centered on the trigger widget and calls [onSelected] when an item is pressed.
class ContextMenuOverlay<T> extends HookWidget {
  const ContextMenuOverlay({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onSelected,
    required this.child,
    this.title,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final void Function(T item) onSelected;
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final isOpen = useState(false);
    final triggerKey = useRef(GlobalKey());

    void openOverlay() {
      final box =
          triggerKey.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final triggerRect = box.localToGlobal(Offset.zero) & box.size;

      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      void close() {
        entry.remove();
        isOpen.value = false;
      }

      entry = OverlayEntry(
        builder: (_) => _ContextMenuOverlayContent<T>(
          triggerRect: triggerRect,
          items: items,
          itemBuilder: itemBuilder,
          title: title,
          onSelected: (item) {
            onSelected(item);
            close();
          },
          onDismiss: close,
        ),
      );
      overlay.insert(entry);
      isOpen.value = true;
    }

    return GestureDetector(
      onTap: openOverlay,
      behavior: HitTestBehavior.opaque,
      child: KeyedSubtree(key: triggerKey.value, child: child),
    );
  }
}

class _ContextMenuOverlayContent<T> extends StatefulWidget {
  const _ContextMenuOverlayContent({
    required this.triggerRect,
    required this.items,
    required this.itemBuilder,
    required this.onSelected,
    required this.onDismiss,
    this.title,
  });

  final Rect triggerRect;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String? title;
  final void Function(T item) onSelected;
  final VoidCallback onDismiss;

  @override
  State<_ContextMenuOverlayContent<T>> createState() =>
      _ContextMenuOverlayContentState<T>();
}

class _ContextMenuOverlayContentState<T>
    extends State<_ContextMenuOverlayContent<T>>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 150);
  static const _curve = Curves.easeOut;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: _curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final panelMaxWidth = screen.width * 0.6;
    final itemHeight = 48.0;
    final itemCount = widget.items.length;
    final hasTitle = widget.title != null && widget.title!.isNotEmpty;
    final panelMaxHeight = itemHeight * itemCount + 16;

    const horizontalPadding = 16.0;
    const verticalPadding = 16.0;
    final endWidth = panelMaxWidth.clamp(
      widget.triggerRect.width,
      double.infinity,
    );
    final endHeight = panelMaxHeight.clamp(
      widget.triggerRect.height,
      double.infinity,
    );

    final triggerCenter = widget.triggerRect.center;
    var endLeft = triggerCenter.dx - endWidth / 2;
    var endTop = triggerCenter.dy - 24;
    endLeft = endLeft.clamp(
      horizontalPadding,
      screen.width - endWidth - horizontalPadding,
    );
    endTop = endTop.clamp(
      verticalPadding,
      screen.height - endHeight - verticalPadding,
    );
    final endRect = Rect.fromLTWH(endLeft, endTop, endWidth, endHeight);

    final color = FluentTheme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              _controller.reverse().then((value) {
                widget.onDismiss();
              });
            },
            behavior: HitTestBehavior.opaque,
          ),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final rect = Rect.lerp(
              widget.triggerRect,
              endRect,
              _animation.value,
            )!;
            final radius = 32.0;
            final animationValue = _animation.value;
            return Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: BlurredMaterial(
                color: color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(radius),
                sigmaX: 128,
                sigmaY: 128,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: FluentTheme.of(context).scaffoldBackgroundColor,
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hasTitle)
                        Padding(
                          padding: EdgeInsets.lerp(
                            EdgeInsets.zero,
                            const EdgeInsets.symmetric(
                              horizontal: 24 + 8,
                              vertical: 8,
                            ),
                            animationValue,
                          )!,
                          child: FittedBox(
                            child: Text(
                              widget.title!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: lerpDouble(
                                      0,
                                      12,
                                      animationValue,
                                    )!,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.5),
                                  ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            return ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99),
                              ),
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              minVerticalPadding: 0,
                              onTap: () => widget.onSelected(item),
                              title: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: widget.itemBuilder(context, item),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
