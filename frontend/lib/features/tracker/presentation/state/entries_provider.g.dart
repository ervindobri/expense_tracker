// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(entries)
const entriesProvider = EntriesProvider._();

final class EntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<EntriesList?>,
          EntriesList?,
          FutureOr<EntriesList?>
        >
    with $FutureModifier<EntriesList?>, $FutureProvider<EntriesList?> {
  const EntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entriesHash();

  @$internal
  @override
  $FutureProviderElement<EntriesList?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EntriesList?> create(Ref ref) {
    return entries(ref);
  }
}

String _$entriesHash() => r'89edd3a5b1b57b06654147436fd5fab109f26560';

@ProviderFor(currentMonthlyEntries)
const currentMonthlyEntriesProvider = CurrentMonthlyEntriesProvider._();

final class CurrentMonthlyEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<EntriesList?>,
          EntriesList?,
          FutureOr<EntriesList?>
        >
    with $FutureModifier<EntriesList?>, $FutureProvider<EntriesList?> {
  const CurrentMonthlyEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthlyEntriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthlyEntriesHash();

  @$internal
  @override
  $FutureProviderElement<EntriesList?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EntriesList?> create(Ref ref) {
    return currentMonthlyEntries(ref);
  }
}

String _$currentMonthlyEntriesHash() =>
    r'10637ab398630a7a64668b6d696acdbc2adc37ff';

@ProviderFor(monthlyEntries)
const monthlyEntriesProvider = MonthlyEntriesProvider._();

final class MonthlyEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, List<Entry>>>,
          Map<int, List<Entry>>,
          FutureOr<Map<int, List<Entry>>>
        >
    with
        $FutureModifier<Map<int, List<Entry>>>,
        $FutureProvider<Map<int, List<Entry>>> {
  const MonthlyEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyEntriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyEntriesHash();

  @$internal
  @override
  $FutureProviderElement<Map<int, List<Entry>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, List<Entry>>> create(Ref ref) {
    return monthlyEntries(ref);
  }
}

String _$monthlyEntriesHash() => r'd01bea004adefd0ea12f2a8c36a21d84eeeb4676';

@ProviderFor(amountForType)
const amountForTypeProvider = AmountForTypeFamily._();

final class AmountForTypeProvider extends $FunctionalProvider<num, num, num>
    with $Provider<num> {
  const AmountForTypeProvider._({
    required AmountForTypeFamily super.from,
    required AmountForTypeParams super.argument,
  }) : super(
         retry: null,
         name: r'amountForTypeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$amountForTypeHash();

  @override
  String toString() {
    return r'amountForTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<num> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  num create(Ref ref) {
    final argument = this.argument as AmountForTypeParams;
    return amountForType(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(num value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<num>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AmountForTypeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$amountForTypeHash() => r'7d6c215df14197ff9c8a419ca4e8dbb9e4f92e0a';

final class AmountForTypeFamily extends $Family
    with $FunctionalFamilyOverride<num, AmountForTypeParams> {
  const AmountForTypeFamily._()
    : super(
        retry: null,
        name: r'amountForTypeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AmountForTypeProvider call(AmountForTypeParams params) =>
      AmountForTypeProvider._(argument: params, from: this);

  @override
  String toString() => r'amountForTypeProvider';
}

@ProviderFor(amountForCategory)
const amountForCategoryProvider = AmountForCategoryFamily._();

final class AmountForCategoryProvider extends $FunctionalProvider<num, num, num>
    with $Provider<num> {
  const AmountForCategoryProvider._({
    required AmountForCategoryFamily super.from,
    required AmountForCategoryParams super.argument,
  }) : super(
         retry: null,
         name: r'amountForCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$amountForCategoryHash();

  @override
  String toString() {
    return r'amountForCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<num> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  num create(Ref ref) {
    final argument = this.argument as AmountForCategoryParams;
    return amountForCategory(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(num value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<num>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AmountForCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$amountForCategoryHash() => r'a8c946e90f518253e82b2fb635228ca4fe8d1a9f';

final class AmountForCategoryFamily extends $Family
    with $FunctionalFamilyOverride<num, AmountForCategoryParams> {
  const AmountForCategoryFamily._()
    : super(
        retry: null,
        name: r'amountForCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AmountForCategoryProvider call(AmountForCategoryParams params) =>
      AmountForCategoryProvider._(argument: params, from: this);

  @override
  String toString() => r'amountForCategoryProvider';
}

@ProviderFor(maxMonth)
const maxMonthProvider = MaxMonthFamily._();

final class MaxMonthProvider
    extends
        $FunctionalProvider<
          (int, List<Entry>),
          (int, List<Entry>),
          (int, List<Entry>)
        >
    with $Provider<(int, List<Entry>)> {
  const MaxMonthProvider._({
    required MaxMonthFamily super.from,
    required CategoryType super.argument,
  }) : super(
         retry: null,
         name: r'maxMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$maxMonthHash();

  @override
  String toString() {
    return r'maxMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<(int, List<Entry>)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  (int, List<Entry>) create(Ref ref) {
    final argument = this.argument as CategoryType;
    return maxMonth(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue((int, List<Entry>) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<(int, List<Entry>)>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MaxMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$maxMonthHash() => r'6542ee881d07482fb87e505cc0b930bc7acf2dae';

final class MaxMonthFamily extends $Family
    with $FunctionalFamilyOverride<(int, List<Entry>), CategoryType> {
  const MaxMonthFamily._()
    : super(
        retry: null,
        name: r'maxMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MaxMonthProvider call(CategoryType type) =>
      MaxMonthProvider._(argument: type, from: this);

  @override
  String toString() => r'maxMonthProvider';
}
