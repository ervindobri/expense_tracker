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

@ProviderFor(monthlyEntries)
const monthlyEntriesProvider = MonthlyEntriesProvider._();

final class MonthlyEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<EntriesList?>,
          EntriesList?,
          FutureOr<EntriesList?>
        >
    with $FutureModifier<EntriesList?>, $FutureProvider<EntriesList?> {
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
  $FutureProviderElement<EntriesList?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EntriesList?> create(Ref ref) {
    return monthlyEntries(ref);
  }
}

String _$monthlyEntriesHash() => r'4a881b6d3ef296304063d4cf69449b825b45b6e8';
