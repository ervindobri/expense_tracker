// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shoppingRepository)
const shoppingRepositoryProvider = ShoppingRepositoryProvider._();

final class ShoppingRepositoryProvider
    extends
        $FunctionalProvider<
          IShoppingRepository,
          IShoppingRepository,
          IShoppingRepository
        >
    with $Provider<IShoppingRepository> {
  const ShoppingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingRepositoryHash();

  @$internal
  @override
  $ProviderElement<IShoppingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IShoppingRepository create(Ref ref) {
    return shoppingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IShoppingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IShoppingRepository>(value),
    );
  }
}

String _$shoppingRepositoryHash() =>
    r'683d9e3d05cb6b4d2c1abfa602a0f889199a7738';
