import 'dart:async';
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:frontend/core/app/theme.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

/// Data for a single tab in the [LiquidGlassTabBar].
class LiquidGlassTabItem {
  const LiquidGlassTabItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// A floating, frosted-glass bottom tab bar that mimics the iOS 26
/// "Liquid Glass" look: a translucent, blurred pill-shaped bar with
/// a soft glowing indicator that slides smoothly between tabs.
///
/// This is a visual approximation built from [BackdropFilter] blur +
/// saturation, layered gradients for the glossy highlight/rim light,
/// and an animated pill behind the selected icon. True light refraction
/// (actual liquid-glass bending) needs a fragment shader and isn't
/// something Flutter's standard widgets can do, but this gets you very
/// close for real-world use.
class LiquidGlassTabBar extends StatefulWidget {
  const LiquidGlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 64,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.tintColor,
    this.indicatorColor = const Color(0xFF3a3a3a),
    this.blurSigma = 12,
    this.axis = Axis.horizontal,
  });
  final List<LiquidGlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Height of the bar itself (excludes outer margin).
  final double height;

  /// Margin around the floating bar.
  final EdgeInsets margin;

  /// Tint color of the glass. Defaults to white (adapts a little to
  /// [Brightness] automatically if you don't override it).
  final Color? tintColor;

  /// Color of the sliding indicator pill / selected icon accent.
  final Color indicatorColor;

  /// How strong the frosted blur is.
  final double blurSigma;

  /// Direction the tabs are laid out in. [Axis.vertical] turns the bar into
  /// a side rail; [height] then becomes the rail's width.
  final Axis axis;

  @override
  State<LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar> {
  static const itemWidth = 100.0;

  var xPosition = 0.0;
  var selectedIndex = 0;

  @override
  void initState() {
    selectedIndex = widget.currentIndex;
    xPosition = itemWidth * selectedIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final double radius = widget.height / 2 + 8;
    final isVertical = widget.axis == Axis.vertical;
    final barLength = 101.0 * widget.items.length;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: widget.margin,
        child: SizedBox(
          height: isVertical ? barLength : widget.height,
          width: isVertical ? widget.height : barLength,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: Material(
                color: FluentTheme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.35),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: GradientBoxBorder(
                      width: 0.5,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: FluentTheme.of(context).gradientBorderColors2,
                      ),
                    ),
                  ),
                  child: Builder(
                    builder: (_) {
                      const pillInset = 8.0;
                      const pillWidth = itemWidth - pillInset * 2;
                      final pillHeight = widget.height - 14;

                      void snapBack() {
                        if (xPosition > 0) {
                          // dragging
                          final snapToIndex = (xPosition ~/ (itemWidth / 2))
                              .clamp(0, widget.items.length - 1);
                          widget.onTap(snapToIndex);
                          setState(() {
                            xPosition = itemWidth * snapToIndex;
                            selectedIndex = snapToIndex;
                          });
                        } else {
                          setState(() {
                            xPosition = 0.0;
                            selectedIndex = 0;
                          });
                        }
                      }

                      return GestureDetector(
                        onPanUpdate: (tapInfo) {
                          setState(() {
                            xPosition += isVertical
                                ? tapInfo.delta.dy
                                : tapInfo.delta.dx;
                          });
                        },
                        onPanCancel: () {
                          snapBack();
                        },
                        onPanEnd: (details) {
                          snapBack();
                        },
                        onTapCancel: () => snapBack(),
                        child: Stack(
                          children: [
                            // Sliding indicator pill.
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              left: isVertical
                                  ? (widget.height - pillHeight) / 2
                                  : xPosition + pillInset,
                              top: isVertical
                                  ? xPosition + pillInset
                                  : (widget.height - pillHeight) / 2,
                              width: isVertical ? pillHeight : pillWidth,
                              height: isVertical ? pillWidth : pillHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    pillHeight / 2,
                                  ),
                                  color: widget.indicatorColor,
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.25 : 0.6,
                                    ),
                                    width: 0.75,
                                  ),
                                ),
                              ),
                            ),
                            // Tab buttons.
                            Flex(
                              direction: widget.axis,
                              children: List.generate(widget.items.length, (
                                index,
                              ) {
                                final selected = index == selectedIndex;
                                final item = widget.items[index];
                                return SizedBox(
                                  width: isVertical ? null : itemWidth,
                                  height: isVertical ? itemWidth : null,
                                  child: _TabButton(
                                    item: item,
                                    selected: selected,
                                    isDark: isDark,
                                    onTap: () {
                                      widget.onTap(index);
                                      setState(() {
                                        selectedIndex = index;
                                        xPosition = itemWidth * index;
                                      });
                                      unawaited(HapticFeedback.lightImpact());
                                    },
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });
  final LiquidGlassTabItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isDark ? Colors.white : Colors.black87;
    final Color inactiveColor = (isDark ? Colors.white : Colors.black87)
        .withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            scale: selected ? 1.0 : .95,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(selected),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? (item.selectedIcon ?? item.icon) : item.icon,
                    size: 24,
                    color: selected ? activeColor : inactiveColor,
                  ),
                  // Shrinks instead of overflowing when the label doesn't
                  // fit the bar's fixed height (large text scales, wide
                  // translations).
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w300,
                          color: selected ? activeColor : inactiveColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
