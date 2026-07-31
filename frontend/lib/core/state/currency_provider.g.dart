// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrencyNotifier)
const currencyProvider = CurrencyNotifierProvider._();

final class CurrencyNotifierProvider
    extends $NotifierProvider<CurrencyNotifier, Currency> {
  const CurrencyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currencyNotifierHash();

  @$internal
  @override
  CurrencyNotifier create() => CurrencyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Currency value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Currency>(value),
    );
  }
}

String _$currencyNotifierHash() => r'20f0297512495d72cd6b116976a41f3bdeddf58b';

abstract class _$CurrencyNotifier extends $Notifier<Currency> {
  Currency build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Currency, Currency>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Currency, Currency>,
              Currency,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
