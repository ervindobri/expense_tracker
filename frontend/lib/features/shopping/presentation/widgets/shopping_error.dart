import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';

/// Toast for a shopping list change that couldn't be saved.
void showShoppingError(BuildContext context, Object error) {
  if (kDebugMode) {
    print(error);
  }
  if (!context.mounted) {
    return;
  }
  ToastificationService.showError(
    context: context,
    title: LocaleKeys.error_saving_shopping.tr(
      namedArgs: {'error': error.toString()},
    ),
    description: error.toString(),
  );
}
