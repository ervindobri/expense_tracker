import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entries_repository.g.dart';

abstract class IEntryRepository {
  Future<List<Category>> getCategories();
  Future<EntriesList?> getEntries();

  Future<int> addEntry(Entry entry);

  Future<bool> removeEntry(int id);

  Future<void> updateEntry(Entry copyWith);
}

class TransactionEntryRepository implements IEntryRepository {
  TransactionEntryRepository({required this.client});

  final Dio client;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final result = await client.get('categories');
      final data = result.data;
      if (data is List<dynamic>) {
        return data.map((e) => Category.from(e)).toList();
      }

      return [];
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  @override
  Future<EntriesList?> getEntries({int? year}) async {
    try {
      // final result = await client.get('/entries?year=${DateTime.now().year}');
      final result = await client.get('entries');
      final data = result.data;
      if (data is List<dynamic>) {
        final parsed = EntriesList(
          items: data.map((e) => Entry.from(e)).toList(),
          total: data.length,
        );
        return parsed;
      }

      return null;
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  @override
  Future<int> addEntry(Entry entry) async {
    try {
      final body = entry.toJson();
      final result = await client.post('entries/', data: body);
      if (result.statusCode == 201) {
        // insert success
        final resultMap = result.data as Map<String, dynamic>;
        return resultMap['id'] as int? ?? 0;
      }

      throw Exception(
        'insert unsuccessful: ${result.statusCode} ${result.statusMessage}',
      );
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }
  
  @override
  Future<bool> removeEntry(int id) async {
    try {
      final result = await client.delete('entries/$id/');
      if (result.statusCode == 204) {
        return true;
      }

      throw Exception(
        'delete unsuccessful: ${result.statusCode} ${result.statusMessage}',
      );
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }
  
  @override
  Future<void> updateEntry(Entry entry) async {
    try {
      final body = entry.toJson();
      final result = await client.put('entries/${entry.id}/', data: body);
      if (result.statusCode != null && result.statusCode! > 299) {
        throw Exception(
          'PATCH unsuccessful: ${result.statusCode} ${result.statusMessage}',
        );
      }
    } catch (e, _) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }
}

@riverpod
IEntryRepository entryRepository(Ref ref) {
  return TransactionEntryRepository(client: ref.watch(dioClientProvider));
}
