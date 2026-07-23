// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(entryRepository)
const entryRepositoryProvider = EntryRepositoryProvider._();

final class EntryRepositoryProvider
    extends
        $FunctionalProvider<
          IEntryRepository,
          IEntryRepository,
          IEntryRepository
        >
    with $Provider<IEntryRepository> {
  const EntryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryRepositoryHash();

  @$internal
  @override
  $ProviderElement<IEntryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IEntryRepository create(Ref ref) {
    return entryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IEntryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IEntryRepository>(value),
    );
  }
}

String _$entryRepositoryHash() => r'c874b0861535766c3bd7e442e22506a4aa3f66ed';
