// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logging_reminder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoggingReminder)
const loggingReminderProvider = LoggingReminderProvider._();

final class LoggingReminderProvider
    extends $NotifierProvider<LoggingReminder, ReminderFrequency> {
  const LoggingReminderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggingReminderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggingReminderHash();

  @$internal
  @override
  LoggingReminder create() => LoggingReminder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderFrequency value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderFrequency>(value),
    );
  }
}

String _$loggingReminderHash() => r'c3abae146854d4a07a305176ecb6e5e2c6adf142';

abstract class _$LoggingReminder extends $Notifier<ReminderFrequency> {
  ReminderFrequency build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ReminderFrequency, ReminderFrequency>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReminderFrequency, ReminderFrequency>,
              ReminderFrequency,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
