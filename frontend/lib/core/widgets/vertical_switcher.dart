import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';

/// A vertical segmented control: the options are stacked and a thumb slides
/// to the selected one. Tap an option, or drag along the control to scrub
/// through them.
class VerticalSwitcher<T> extends StatelessWidget {
  const VerticalSwitcher({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
    this.itemExtent = 30,
    this.width = 44,
  });

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  /// Height of one option.
  final double itemExtent;
  final double width;

  static const _inset = 3.0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final index = values.indexOf(value);

    void select(double dy) {
      final i = ((dy - _inset) ~/ itemExtent).clamp(0, values.length - 1);
      if (values[i] != value) {
        unawaited(HapticFeedback.selectionClick());
        onChanged(values[i]);
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => select(details.localPosition.dy),
      onVerticalDragUpdate: (details) => select(details.localPosition.dy),
      child: Container(
        width: width,
        height: itemExtent * values.length + _inset * 2,
        padding: const EdgeInsets.all(_inset),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(width / 2),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              alignment: Alignment(
                0,
                values.length < 2 ? 0 : -1 + 2 * index / (values.length - 1),
              ),
              child: Container(
                height: itemExtent,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(width / 2),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                for (final v in values)
                  Semantics(
                    button: true,
                    selected: v == value,
                    child: SizedBox(
                      height: itemExtent,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: (textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(
                                fontWeight: v == value
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: v == value
                                    ? theme.textColor
                                    : Theme.of(context).hintColor,
                              ),
                          child: Text(labelBuilder(v)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
