// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(entries)
const entriesProvider = QueriesProvider._();

final class QueriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<EntriesList?>,
          EntriesList?,
          FutureOr<EntriesList?>
        >
    with $FutureModifier<EntriesList?>, $FutureProvider<EntriesList?> {
  const QueriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queriesHash();

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

String _$queriesHash() => r'e1c53e7dcd00567d7688c531f469ae919207484c';
