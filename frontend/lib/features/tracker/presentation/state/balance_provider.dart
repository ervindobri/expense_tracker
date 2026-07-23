import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'balance_provider.g.dart';

@riverpod
Future<Balance> balance(Ref ref, int month) async {
  final categories = await ref.watch(categoriesProvider.future);
  final entries = await ref.watch(entriesProvider.future);
  final balanceEntries = entries == null || entries.items.isEmpty
      ? <Entry>[]
      : entries.items.where((entry) => entry.addedDate.month == month).toList();

  final expenses = balanceEntries.where((e) => categories.firstWhere((c) => c.id == e.category).type == CategoryType.expense);
  final incomes = balanceEntries.where((e) => categories.firstWhere((c) => c.id == e.category).type == CategoryType.income);
  final expensesTotal = expenses.toList().fold(0.0, (double amount, Entry b) => amount + b.amount);
  final incomesTotal = incomes.toList().fold(0.0, (double amount, Entry b) => amount + b.amount);

  return Balance(totalAmount: 0, expenses: expensesTotal, incomes: incomesTotal);
}
