
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categories_provider.g.dart';

@riverpod
Future<List<Category>> categories(Ref ref){
  return ref.watch(entryRepositoryProvider).getCategories();
}