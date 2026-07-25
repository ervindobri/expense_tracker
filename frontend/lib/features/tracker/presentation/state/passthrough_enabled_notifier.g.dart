// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passthrough_enabled_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PassThroughEnabledNotifier)
const passThroughEnabledProvider = PassThroughEnabledNotifierProvider._();

final class PassThroughEnabledNotifierProvider
    extends $NotifierProvider<PassThroughEnabledNotifier, bool> {
  const PassThroughEnabledNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passThroughEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passThroughEnabledNotifierHash();

  @$internal
  @override
  PassThroughEnabledNotifier create() => PassThroughEnabledNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$passThroughEnabledNotifierHash() =>
    r'61c2becec0a084bb3137ff25c4525ea67913f342';

abstract class _$PassThroughEnabledNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
