import 'package:fluent_ui/fluent_ui.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:toastification/toastification.dart';

// ignore: avoid_classes_with_only_static_members
class ToastificationService {
  static void show({
    required BuildContext context,
    required String title,
    String? description,
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      title: Text(title, style: context.bodyLarge),
      type: type,
      dismissDirection: DismissDirection.up,
      alignment: Alignment.topCenter,
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(99.0),
      boxShadow: FluentTheme.of(context).boxShadow,
      backgroundColor: FluentTheme.of(context).scaffoldBackgroundColor,
      autoCloseDuration: const Duration(seconds: 2),
      showProgressBar: false,
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    String? description,
  }) async {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastificationType.success,
    );
  }

  static void showError({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastificationType.error,
    );
  }
}
