import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opens [builder] as a centered dialog on web and as a bottom sheet
/// elsewhere, the same way the entry sheets are shown.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (kIsWeb) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 540),
        child: builder(dialogContext),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Rounded, gradient-bordered card the app's sheets are drawn in. Grows with
/// its content up to most of the screen, then scrolls.
class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.bottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.height * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(40.0),
            border: GradientBoxBorder(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientBorderColors,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(64),
                blurRadius: 32,
                spreadRadius: -4,
              ),
            ],
          ),
          margin: const EdgeInsets.all(12.0),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Title row with the round close button used at the top of every sheet.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.leading});

  final Widget title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        ?leading,
        Expanded(
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: title,
          ),
        ),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: FluentTheme.of(context).menuColor,
            iconSize: 24,
          ),
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            Navigator.pop(context);
          },
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }
}
