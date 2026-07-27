import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';

class SecondaryButton extends HookWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.padding,
    this.outline = true,
    required this.label,
  });
  final VoidCallback onPressed;
  final IconData? icon;
  final String label;
  final EdgeInsets? padding;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    return GestureDetector(
      onTapDown: (_) {
        pressed.value = true;
      },
      onTapCancel: () {
        pressed.value = false;
      },
      onTapUp: (_) {
        pressed.value = false;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: pressed.value ? 1.05 : 1.0,
        duration: kThemeAnimationDuration,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            // backgroundColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            side: outline
                ? BorderSide(color: FluentTheme.of(context).borderColor)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(32.0),
            ),
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          onPressed: () {
            onPressed();
            unawaited(HapticFeedback.mediumImpact());
          },
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Row(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    color:
                        FluentTheme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color:
                        FluentTheme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
