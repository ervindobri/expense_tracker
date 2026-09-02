import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabTitleReminder {
  static const _defaultTitle = 'Expense Tracker';
  static const _reminderTitle = '⏰ Time to log your expenses';

  Timer? _timer;

  void start() {
    _updateTitle(); // set immediately on startup
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateTitle());
  }

  void _updateTitle() {
    final hour = DateTime.now().hour;
    _setTitle(hour >= 19 ? _reminderTitle : _defaultTitle);
  }

  void debugChange() => _setTitle('Hello, test title!');

  /// Works on every platform: on web this updates the browser tab title, on
  /// desktop/mobile the application switcher label.
  void _setTitle(String title) {
    unawaited(
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(label: title),
      ),
    );
  }

  void dispose() => _timer?.cancel();
}

final tabTitleChangerProvider = Provider<TabTitleReminder>(
  (_) => TabTitleReminder(),
);
