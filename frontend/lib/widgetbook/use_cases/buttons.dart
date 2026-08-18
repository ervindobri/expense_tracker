import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/secondary_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: PrimaryButton, path: 'core/widgets')
Widget primaryButtonUseCase(BuildContext context) {
  return Center(
    child: PrimaryButton(
      label: context.knobs.string(label: 'Label', initialValue: 'Add income'),
      icon: context.knobs.boolean(label: 'With icon')
          ? LucideIcons.plus
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: context.knobs.double.slider(
          label: 'Horizontal padding',
          initialValue: 8,
          max: 48,
        ),
        vertical: 4,
      ),
      onPressed: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Default',
  type: SecondaryButton,
  path: 'core/widgets',
)
Widget secondaryButtonUseCase(BuildContext context) {
  return Center(
    child: SecondaryButton(
      label: context.knobs.string(label: 'Label', initialValue: 'Cancel'),
      outline: context.knobs.boolean(label: 'Outline', initialValue: true),
      icon: context.knobs.boolean(label: 'With icon') ? LucideIcons.x : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onPressed: () {},
    ),
  );
}
