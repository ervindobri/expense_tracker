// core/widgets/blurred_container.dart
// ignore_for_file: dead_code

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A container that applies a blur effect on high-end devices and
/// falls back to a solid color background on low-end devices.
///
/// This improves performance on devices with limited resources.
class BlurredContainer extends StatelessWidget {
  const BlurredContainer({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.borderRadius,
    this.sigmaX = 24,
    this.sigmaY = 24,
    this.border,
    this.gradient,
    this.padding,
    this.margin,
    this.decoration,
    this.shadow,
  });

  /// The child widget to display inside the container.
  final Widget child;

  /// The background color to use. On high-end devices, this is applied
  /// with opacity. On low-end devices, this is used as a solid color.
  final Color backgroundColor;

  /// The blur radius in X direction. Default is 24.
  final double sigmaX;

  /// The blur radius in Y direction. Default is 24.
  final double sigmaY;

  /// Optional border radius for clipping the blur effect.
  final BorderRadius? borderRadius;

  /// Optional border for the container.
  final BoxBorder? border;

  /// Optional gradient overlay.
  final Gradient? gradient;

  /// Optional padding inside the container.
  final EdgeInsetsGeometry? padding;

  /// Optional margin outside the container.
  final EdgeInsetsGeometry? margin;

  /// Optional full decoration (overrides backgroundColor on low-end devices).
  final BoxDecoration? decoration;

  /// Optional shadow for the container.
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final enableBlur = true;

    if (kDebugMode || enableBlur) {
      return _buildBlurredVersion();
    } else {
      return _buildSolidVersion();
    }
  }

  Widget _buildBlurredVersion() {
    Widget content = Container(
      decoration:
          decoration ??
          BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: border,
            gradient: gradient,
            boxShadow: shadow != null ? [shadow!] : null,
          ),
      padding: padding,
      margin: margin,
      child: child,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: content,
        ),
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: content,
    );
  }

  Widget _buildSolidVersion() {
    // For low-end devices, use solid color without opacity
    final solidColor = _getSolidColor();

    return Container(
      decoration:
          decoration?.copyWith(
            color: solidColor,
            gradient: null, // Remove gradient for performance
          ) ??
          BoxDecoration(
            color: solidColor,
            borderRadius: borderRadius,
            border: border,
            boxShadow: shadow != null ? [shadow!] : null,
          ),
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  /// Get a solid version of the background color (remove alpha/opacity).
  Color _getSolidColor() {
    // If the color has opacity, make it solid by blending with a neutral color
    if (backgroundColor.a < 1.0) {
      // Blend the transparent color with a background approximation
      return Color.alphaBlend(
        backgroundColor,
        _isLightColor(backgroundColor) ? Colors.white : Colors.black,
      );
    }
    return backgroundColor;
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }
}

/// A wrapper that conditionally applies BackdropFilter based on device capability.
/// Use this when you need more control over the blur effect.
class ConditionalBackdropFilter extends StatelessWidget {
  const ConditionalBackdropFilter({
    super.key,
    required this.child,
    this.sigmaX = 24,
    this.sigmaY = 24,
    this.borderRadius,
  });

  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final enableBlur = true;

    if (!enableBlur) {
      return child;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: child,
        ),
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );
  }
}

/// A Material widget that conditionally applies blur backdrop.
class BlurredMaterial extends StatelessWidget {
  const BlurredMaterial({
    super.key,
    required this.child,
    required this.color,
    this.sigmaX = 24,
    this.sigmaY = 24,
    this.borderRadius,
    this.elevation = 0,
  });

  final Widget child;
  final Color color;
  final double sigmaX;
  final double sigmaY;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final enableBlur =
        kDebugMode || true;

    final solidColor = enableBlur ? color : _getSolidColor(color);

    final material = Material(
      color: solidColor,
      borderRadius: borderRadius,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      animateColor: true,
      child: child,
    );

    if (!enableBlur) {
      return material;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: material,
        ),
      );
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: material,
      ),
    );
  }

  Color _getSolidColor(Color color) {
    if (color.a < 1.0) {
      return Color.alphaBlend(
        color,
        color.computeLuminance() > 0.5 ? Colors.white : Colors.black,
      );
    }
    return color;
  }
}

/// Extension to easily check blur capability from BuildContext.
extension BlurCapabilityExtension on BuildContext {
  /// Whether blur effects should be enabled on this device.
  bool get enableBlurEffects =>
      true;

  /// Whether this is a low-end device.
  bool get isLowEndDevice => false;
}