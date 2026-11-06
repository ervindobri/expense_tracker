// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every shopping list with its items. Changes are applied to the loaded
/// state directly instead of refetching, so ticking items off stays instant.

@ProviderFor(ShoppingLists)
const shoppingListsProvider = ShoppingListsProvider._();

/// Every shopping list with its items. Changes are applied to the loaded
/// state directly instead of refetching, so ticking items off stays instant.
final class ShoppingListsProvider
    extends $AsyncNotifierProvider<ShoppingLists, List<ShoppingList>> {
  /// Every shopping list with its items. Changes are applied to the loaded
  /// state directly instead of refetching, so ticking items off stays instant.
  const ShoppingListsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListsHash();

  @$internal
  @override
  ShoppingLists create() => ShoppingLists();
}

String _$shoppingListsHash() => r'ef698232d9fea1ec455f481cd13e3ecc577c5ea5';

/// Every shopping list with its items. Changes are applied to the loaded
/// state directly instead of refetching, so ticking items off stays instant.

abstract class _$ShoppingLists extends $AsyncNotifier<List<ShoppingList>> {
  FutureOr<List<ShoppingList>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ShoppingList>>, List<ShoppingList>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ShoppingList>>, List<ShoppingList>>,
              AsyncValue<List<ShoppingList>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// A single list, or null when it doesn't exist (any more).

@ProviderFor(shoppingList)
const shoppingListProvider = ShoppingListFamily._();

/// A single list, or null when it doesn't exist (any more).

final class ShoppingListProvider
    extends $FunctionalProvider<ShoppingList?, ShoppingList?, ShoppingList?>
    with $Provider<ShoppingList?> {
  /// A single list, or null when it doesn't exist (any more).
  const ShoppingListProvider._({
    required ShoppingListFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shoppingListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingListHash();

  @override
  String toString() {
    return r'shoppingListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ShoppingList?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShoppingList? create(Ref ref) {
    final argument = this.argument as int;
    return shoppingList(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingList? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingList?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingListHash() => r'e5782ab9dfffcaa164ffd7f4b36b3a2cc22c6f07';

/// A single list, or null when it doesn't exist (any more).

final class ShoppingListFamily extends $Family
    with $FunctionalFamilyOverride<ShoppingList?, int> {
  const ShoppingListFamily._()
    : super(
        retry: null,
        name: r'shoppingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A single list, or null when it doesn't exist (any more).

  ShoppingListProvider call(int id) =>
      ShoppingListProvider._(argument: id, from: this);

  @override
  String toString() => r'shoppingListProvider';
}
