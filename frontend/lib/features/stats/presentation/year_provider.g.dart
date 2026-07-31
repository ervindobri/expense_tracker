// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(YearNotifier)
const yearProvider = YearNotifierProvider._();

final class YearNotifierProvider extends $NotifierProvider<YearNotifier, int> {
  const YearNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'yearProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$yearNotifierHash();

  @$internal
  @override
  YearNotifier create() => YearNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$yearNotifierHash() => r'c4444e4da73c1b8a9b3efc1d9d992b7575841fef';

abstract class _$YearNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
