import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/app/app.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _linkLazyLibraries();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('hu', 'HU'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('hu', 'HU'),
      child: const ProviderScope(child: ToastificationWrapper(child: App())),
    ),
  );
}

/// Dart-to-JS debug builds link a library the first time one of its members is
/// read. [LucideIcons] is huge, and linking it from inside the first widget
/// build - already hundreds of frames deep - overflows the browser's JS stack,
/// which is what turned every web hot restart into a `StackOverflowError`.
/// Reading one icon here links it while the stack is still shallow.
void _linkLazyLibraries() {
  if (LucideIcons.home.codePoint == 0) {
    debugPrint('Lucide icon font is unavailable');
  }
}
