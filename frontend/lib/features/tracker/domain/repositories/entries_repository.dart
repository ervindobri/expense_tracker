import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entries_repository.g.dart';

abstract class IEntryRepository {
  Future<List<Category>> getCategories();
  Future<EntriesList?> getEntries(); // Load all entries for this year
}

class TransactionEntryRepository implements IEntryRepository {
  TransactionEntryRepository({required this.client});

  final Dio client;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final result = await client.get('/categories');
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
      final result = await client.get('/entries');
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
}

@riverpod
IEntryRepository entryRepository(Ref ref) {
  return TransactionEntryRepository(client: ref.watch(dioClientProvider));
}
