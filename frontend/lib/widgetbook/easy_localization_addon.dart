import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// A locale switcher that drives `easy_localization` instead of a plain
/// [Localizations] override.
///
/// The app resolves its strings through `LocaleKeys.x.tr()`, which reads the
/// globally installed `easy_localization` controller. Widgetbook's built-in
/// [LocalizationAddon] only swaps the [Localizations] widget, so translations
/// would not follow the dropdown. This addon calls `context.setLocale` instead.
class EasyLocalizationAddon extends WidgetbookAddon<Locale> {
  EasyLocalizationAddon({required this.locales, this.initialLocale})
    : assert(locales.isNotEmpty, 'locales cannot be empty'),
      super(name: 'Locale');

  final List<Locale> locales;
  final Locale? initialLocale;

  @override
  List<Field<dynamic>> get fields => [
    ObjectDropdownField<Locale>(
      name: 'name',
      values: locales,
      initialValue: initialLocale ?? locales.first,
      labelBuilder: (locale) => locale.toLanguageTag(),
    ),
  ];

  @override
  Locale valueFromQueryGroup(Map<String, String> group) =>
      valueOf('name', group)!;

  @override
  Widget buildUseCase(BuildContext context, Widget child, Locale setting) {
    if (context.locale != setting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          unawaited(context.setLocale(setting));
        }
      });
    }
    return child;
  }
}
