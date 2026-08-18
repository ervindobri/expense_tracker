import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/widgets/blurred_container.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: BlurredContainer,
  path: 'core/widgets',
)
Widget blurredContainerUseCase(BuildContext context) {
  final theme = FluentTheme.of(context);
  final sigma = context.knobs.double.slider(
    label: 'Sigma',
    initialValue: 24,
    max: 60,
  );
  return Stack(
    alignment: Alignment.center,
    children: [
      // Something colourful behind the container, so the blur is visible.
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox.expand(),
      ),
      BlurredContainer(
        backgroundColor: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        sigmaX: sigma,
        sigmaY: sigma,
        padding: const EdgeInsets.all(24),
        border: Border.all(color: theme.dividerColor),
        child: Text(
          context.knobs.string(label: 'Text', initialValue: 'Blurred surface'),
          style: TextStyle(color: theme.textColor),
        ),
      ),
    ],
  );
}
