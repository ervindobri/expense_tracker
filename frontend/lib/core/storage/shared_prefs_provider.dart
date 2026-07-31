import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/settings/domain/reminder_frequency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';


part 'shared_prefs_provider.g.dart';


const loggingKey = 'logging_reminders';

@Riverpod(keepAlive: true)
class SharedPrefs extends AsyncNotifier<SharedPreferences>{
  @override
  Future<SharedPreferences> build() async {
    return SharedPreferences.getInstance();
  }
}


extension Ext on SharedPreferences {
  Future<bool> setLoggingReminder(int value) async {
    return setInt(loggingKey, value);
  }

  ReminderFrequency getLoggingReminder() {
    final index = getInt(loggingKey);
    if (index == null) {
      return ReminderFrequency.none;
    }
    return ReminderFrequency.values[index];
  }
}