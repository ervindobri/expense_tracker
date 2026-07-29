// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(balance)
const balanceProvider = BalanceFamily._();

final class BalanceProvider
    extends $FunctionalProvider<AsyncValue<Balance>, Balance, FutureOr<Balance>>
    with $FutureModifier<Balance>, $FutureProvider<Balance> {
  const BalanceProvider._({
    required BalanceFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'balanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$balanceHash();

  @override
  String toString() {
    return r'balanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Balance> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Balance> create(Ref ref) {
    final argument = this.argument as int;
    return balance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BalanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$balanceHash() => r'b54ca7bbc068d5f52e5e952d4021b49f15f5e56a';

final class BalanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Balance>, int> {
  const BalanceFamily._()
    : super(
        retry: null,
        name: r'balanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BalanceProvider call(int month) =>
      BalanceProvider._(argument: month, from: this);

  @override
  String toString() => r'balanceProvider';
}
