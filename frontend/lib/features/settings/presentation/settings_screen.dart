import 'package:fluent_ui/fluent_ui.dart' hide ListTile;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/state/currency_provider.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/settings/domain/reminder_frequency.dart';
import 'package:frontend/features/settings/presentation/logging_reminder_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timezone/timezone.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16.0),
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: context.headlineSmall),
            Material(
              color: FluentTheme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24.0),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99.0),
                      ),
                      title: Text('App theme', style: context.bodyMedium),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      trailing: ContextMenuOverlay<ThemeMode>(
                        items: ThemeMode.values,
                        initialValue: ref.watch(themeModeProvider),

                        itemBuilder: (_, t) => Text(t.name),
                        onSelected: (mode) {
                          ref.read(themeModeProvider.notifier).set(mode);
                        },
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Text(ref.watch(themeModeProvider).name),
                            const Icon(LucideIcons.chevronDown),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99.0),
                      ),
                      title: Text(
                        'Logging Reminder (20:00)',
                        style: context.bodyMedium,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      trailing: ContextMenuOverlay<ReminderFrequency>(
                        width: 120,
                        items: ReminderFrequency.values,
                        initialValue: ref.watch(loggingReminderProvider),
                        itemBuilder: (_, t) => Text(t.display),
                        onSelected: (mode) {
                          ref.read(loggingReminderProvider.notifier).set(mode);
                        },
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ref.watch(loggingReminderProvider).display),
                            const Icon(LucideIcons.chevronDown),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      title: Text('Currency', style: context.bodyMedium),
                      trailing: ContextMenuOverlay<Currency>(
                        items: Currency.values,
                        initialValue: defaultCurrency,
                        itemBuilder: (_, t) => Text(t.display),
                        onSelected: (currency) {
                          ref.read(currencyProvider.notifier).set(currency);
                        },
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Text(ref.watch(currencyProvider).display),
                            const Icon(LucideIcons.chevronDown),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (kDebugMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                    ),
                    title: Text(
                      'Debug show local notification',
                      style: context.bodyMedium,
                    ),
                    onTap: () async {
                      final _plugin = FlutterLocalNotificationsPlugin();
                      final name = await FlutterTimezone.getLocalTimezone();

                      final budapest = getLocation(name.identifier);
                      await _plugin.zonedSchedule(
                        id: 1001,
                        title: 'title',
                        body: 'This is the body',
                        scheduledDate: TZDateTime.from(
                          DateTime.now().add(const Duration(seconds: 1)),
                          budapest,
                        ),
                        androidScheduleMode: AndroidScheduleMode.exact,
                        notificationDetails: const NotificationDetails(
                          iOS: DarwinNotificationDetails(
                            presentBadge: true,
                            presentAlert: true,
                            presentList: true,
                            presentSound: true,
                            sound: 'noti.wav',
                            presentBanner: true,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    onTap: () {
                      print(
                        'Exchange rate: ${ref.read(hufExchangeRateProvider).value}',
                      );
                    },
                    title: Text(
                      'Test currency conversion: ${ref.watch(convertedAmountProvider(1000.00)).value}',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
