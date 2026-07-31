// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SharedPrefs)
const sharedPrefsProvider = SharedPrefsProvider._();

final class SharedPrefsProvider
    extends $AsyncNotifierProvider<SharedPrefs, SharedPreferences> {
  const SharedPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPrefsHash();

  @$internal
  @override
  SharedPrefs create() => SharedPrefs();
}

String _$sharedPrefsHash() => r'cad83ffdeb978d8fa4069f8f14db77c2bc31d06f';

abstract class _$SharedPrefs extends $AsyncNotifier<SharedPreferences> {
  FutureOr<SharedPreferences> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<SharedPreferences>, SharedPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SharedPreferences>, SharedPreferences>,
              AsyncValue<SharedPreferences>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
