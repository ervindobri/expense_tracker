import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_repository.g.dart';

abstract class IShoppingRepository {
  /// Every list with its items.
  Future<List<ShoppingList>> getLists();

  Future<ShoppingList> addList(String name);

  Future<ShoppingList> renameList(int id, String name);

  /// Deletes the list and its items.
  Future<void> removeList(int id);

  Future<ShoppingItem> addItem(ShoppingItem item);

  Future<ShoppingItem> updateItem(ShoppingItem item);

  Future<void> removeItem(int id);
}

class ShoppingRepository implements IShoppingRepository {
  ShoppingRepository({required this.client});

  final Dio client;

  void _check(Response<dynamic> result, String action) {
    final code = result.statusCode;
    if (code == null || code > 299) {
      throw Exception(
        '$action unsuccessful: ${result.statusCode} ${result.statusMessage}',
      );
    }
  }

  @override
  Future<List<ShoppingList>> getLists() async {
    final result = await client.get('shopping-lists/');
    _check(result, 'GET');
    final data = result.data;
    if (data is List<dynamic>) {
      return data
          .map((e) => ShoppingList.from(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<ShoppingList> addList(String name) async {
    final result = await client.post('shopping-lists/', data: {'name': name});
    _check(result, 'insert');
    return ShoppingList.from(result.data as Map<String, dynamic>);
  }

  @override
  Future<ShoppingList> renameList(int id, String name) async {
    final result = await client.put(
      'shopping-lists/$id/',
      data: {'name': name},
    );
    _check(result, 'PUT');
    return ShoppingList.from(result.data as Map<String, dynamic>);
  }

  @override
  Future<void> removeList(int id) async {
    final result = await client.delete('shopping-lists/$id/');
    _check(result, 'delete');
  }

  @override
  Future<ShoppingItem> addItem(ShoppingItem item) async {
    final result = await client.post('shopping-items/', data: item.toJson());
    _check(result, 'insert');
    return ShoppingItem.from(result.data as Map<String, dynamic>);
  }

  @override
  Future<ShoppingItem> updateItem(ShoppingItem item) async {
    final result = await client.put(
      'shopping-items/${item.id}/',
      data: item.toJson(),
    );
    _check(result, 'PUT');
    return ShoppingItem.from(result.data as Map<String, dynamic>);
  }

  @override
  Future<void> removeItem(int id) async {
    final result = await client.delete('shopping-items/$id/');
    _check(result, 'delete');
  }
}

@riverpod
IShoppingRepository shoppingRepository(Ref ref) {
  return ShoppingRepository(client: ref.watch(dioClientProvider));
}
