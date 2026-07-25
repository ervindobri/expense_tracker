import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entries_provider.g.dart';

@riverpod
Future<EntriesList?> entries(Ref ref) {
  // Fetch all entries for this year
  return ref.watch(entryRepositoryProvider).getEntries();
}



@Riverpod(keepAlive: true)
Future<EntriesList?>? monthlyEntries(Ref ref) async {
  final allEntries = await ref.watch(entriesProvider.future);
  final month = ref.watch(reportProvider);
  final items = allEntries?.items.where((e) => e.addedDate.month == month).toList() ?? <Entry>[];
  return EntriesList(items: items, total: items.length);
}