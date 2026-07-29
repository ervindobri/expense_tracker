import 'dart:collection';

import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entries_provider.g.dart';

@riverpod
Future<EntriesList?> entries(Ref ref) {
  // Fetch all entries for this year
  return ref.watch(entryRepositoryProvider).getEntries();
}

@Riverpod(keepAlive: true)
Future<EntriesList?>? currentMonthlyEntries(Ref ref) async {
  final allEntries = await ref.watch(entriesProvider.future);
  final month = ref.watch(reportProvider);
  final items =
      allEntries?.items.where((e) => e.addedDate.month == month).toList() ??
      <Entry>[];
  return EntriesList(items: items, total: items.length);
}

@Riverpod(keepAlive: true)
Future<Map<int, List<Entry>>> monthlyEntries(Ref ref) async {
  final allEntries = await ref.watch(entriesProvider.future);

  final entriesMap = <int, List<Entry>>{};

  List.generate(12, (i) {
    final monthlyEntries = allEntries?.items
        .where((e) => e.addedDate.month == i + 1)
        .toList();
    entriesMap[i + 1] = monthlyEntries ?? <Entry>[];
    return;
  });

  final sortedKeys = entriesMap.keys.toList(
    growable: false,
  )..sort((k2, k1) => entriesMap[k1]!.amount.compareTo(entriesMap[k2]!.amount));
  final LinkedHashMap sortedMap = LinkedHashMap.fromIterable(
    sortedKeys,
    key: (k) => k,
    value: (k) => entriesMap[k],
  );

  final result = sortedMap.cast<int, List<Entry>>();
  return result;
}

typedef AmountForTypeParams = ({List<Entry> entries, CategoryType type});

@riverpod
num amountForType(Ref ref, AmountForTypeParams params) {
  final categories = ref.watch(categoriesProvider);
  final typeCategories =
      categories.value
          ?.where((c) => c.type == params.type)
          .map((e) => e.id)
          .toList() ??
      [];
  return params.entries
      .where((e) => typeCategories.contains(e.category))
      .toList()
      .amount;
}

typedef AmountForCategoryParams = ({List<Entry> entries, int category});

@riverpod
num amountForCategory(Ref ref, AmountForCategoryParams params) {
  final categories = ref.watch(categoriesProvider);
  final typeCategories =
      categories.value
          ?.where((c) => c.id == params.category)
          .map((e) => e.id)
          .toList() ??
      [];
  return params.entries
      .where((e) => typeCategories.contains(e.category))
      .toList()
      .amount;
}

@riverpod
(int month, List<Entry> entries) maxMonth(Ref ref, CategoryType type) {
  final entries = ref.watch(monthlyEntriesProvider);
  if (entries.value == null) {
    return (0, []);
  }
  var maximum = (entries.value!.entries.first.key, <Entry>[]);
  final categories = ref.watch(categoriesProvider);
  final typeCategories =
      categories.value
          ?.where((c) => c.type == type)
          .map((e) => e.id)
          .toList() ??
      [];
  for (final month in entries.value!.entries) {
    final monthEntries = month.value
        .where((e) => typeCategories.contains(e.category))
        .toList();
    if (monthEntries.amount > maximum.$2.amount) {
      maximum = (month.key, monthEntries);
    }
  }

  return maximum;
}

extension EntryListExt on List<Entry> {
  num get amount => fold<double>(0.0, (prod, Entry curr) => prod + curr.amount);
}
