import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_provider.g.dart';

/// Every shopping list with its items. Changes are applied to the loaded
/// state directly instead of refetching, so ticking items off stays instant.
@riverpod
class ShoppingLists extends _$ShoppingLists {
  IShoppingRepository get _repository => ref.read(shoppingRepositoryProvider);

  @override
  Future<List<ShoppingList>> build() {
    return ref.watch(shoppingRepositoryProvider).getLists();
  }

  List<ShoppingList> get _lists => state.value ?? const [];

  void _replaceList(int id, ShoppingList Function(ShoppingList) update) {
    state = AsyncData([for (final l in _lists) l.id == id ? update(l) : l]);
  }

  void _replaceItem(ShoppingItem item) {
    _replaceList(
      item.listId,
      (l) => l.copyWith(
        items: [for (final i in l.items) i.id == item.id ? item : i],
      ),
    );
  }

  Future<ShoppingList> addList(String name) async {
    final created = await _repository.addList(name);
    state = AsyncData([..._lists, created]);
    return created;
  }

  Future<void> renameList(int id, String name) async {
    final renamed = await _repository.renameList(id, name);
    _replaceList(id, (l) => l.copyWith(name: renamed.name));
  }

  Future<void> removeList(int id) async {
    await _repository.removeList(id);
    state = AsyncData(_lists.where((l) => l.id != id).toList());
  }

  Future<ShoppingItem> addItem(ShoppingItem item) async {
    final created = await _repository.addItem(item);
    _replaceList(
      created.listId,
      (l) => l.copyWith(items: [...l.items, created]),
    );
    return created;
  }

  Future<ShoppingItem> updateItem(ShoppingItem item) async {
    final saved = await _repository.updateItem(item);
    _replaceItem(saved);
    return saved;
  }

  /// Flips [item]'s bought state right away and rolls back if saving fails.
  Future<void> toggleBought(ShoppingItem item) async {
    final toggled = item.copyWith(isBought: !item.isBought);
    _replaceItem(toggled);
    try {
      await _repository.updateItem(toggled);
    } catch (_) {
      _replaceItem(item);
      rethrow;
    }
  }

  Future<void> removeItem(ShoppingItem item) async {
    _replaceList(
      item.listId,
      (l) => l.copyWith(items: l.items.where((i) => i.id != item.id).toList()),
    );
    try {
      await _repository.removeItem(item.id);
    } catch (_) {
      _replaceList(item.listId, (l) => l.copyWith(items: [...l.items, item]));
      rethrow;
    }
  }
}

/// A single list, or null when it doesn't exist (any more).
@riverpod
ShoppingList? shoppingList(Ref ref, int id) {
  final lists = ref.watch(shoppingListsProvider).value ?? const [];
  return lists.where((l) => l.id == id).firstOrNull;
}
