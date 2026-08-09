import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

class TabTitleReminder {
  static const _defaultTitle = 'Expense Tracker';
  static const _reminderTitle = '⏰ Time to log your expenses';

  Timer? _timer;

  void start() {
    if (!kIsWeb) {
      return;
    }
    _updateTitle(); // set immediately on startup
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateTitle());
  }

  void _updateTitle() {
    final hour = DateTime.now().hour;
    web.document.title = hour >= 19 ? _reminderTitle : _defaultTitle;
  }

  void debugChange(){
    web.document.title = 'Hello, test title!';
  }

  void dispose() => _timer?.cancel();
}


final tabTitleChangerProvider = Provider<TabTitleReminder> ((_) => TabTitleReminder());