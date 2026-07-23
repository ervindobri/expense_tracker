import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entries_provider.g.dart';

@riverpod
Future<EntriesList?> entries(Ref ref) {
  return ref.watch(entryRepositoryProvider).getEntries();
}
