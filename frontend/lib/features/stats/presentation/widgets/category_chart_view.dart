import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' hide Divider;
import 'package:flutter/material.dart' show Divider, Durations;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/features/stats/presentation/widgets/chart.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryChartView extends HookConsumerWidget {
  const CategoryChartView({
    super.key,
    required this.selectedType,
    required this.selectedMonth,
  });

  final CategoryType selectedType;
  final ValueNotifier<int?> selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = DateTime.now().month;
    final categories = ref.watch(categoriesProvider);
    final typeCategories =
        categories.value?.where((c) => c.type == selectedType).toList() ?? [];

    final allEntries =
        ref.watch(monthlyEntriesProvider).value ?? const <int, List<Entry>>{};
    // No month selected, show total
    final entriesGrouped = selectedMonth.value == null
        ? allEntries.entries.expand((e) => e.value).toList()
        : allEntries[selectedMonth.value];
    final totalAmount = ref.watch(
      amountForTypeProvider((
        entries: entriesGrouped ?? [],
        type: selectedType,
      )),
    );

    final selectedCategory = useState<Category?>(null);
    return Container(
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16.0),
      width: double.infinity,
      child: Column(
        spacing: 48,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report by category', style: context.bodyLarge),
          Center(
            child: SizedBox(
              height: 248,
              child: ExpenseDonutChart<Category>(
                selected: selectedCategory.value,
                onTouched: (i) {
                  selectedCategory.value = i == null
                      ? null
                      : categories.value?[i];

                  unawaited(HapticFeedback.mediumImpact());
                },
                segments: [
                  ...typeCategories.map((cat) {
                    final selectedAmount = ref.watch(
                      amountForCategoryProvider((
                        entries: entriesGrouped ?? [],
                        category: cat.id,
                      )),
                    );
                    return ExpenseSegment<Category>(
                      item: cat,
                      label: cat.name,
                      amount: selectedAmount.toDouble(),
                      color: cat.color,
                    );
                  }),
                ],
              ),
            ),
          ),
          selectedMonth.value != null && selectedMonth.value! > currentMonth
              ? const Center(
                  child: Row(
                    spacing: 12,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.info),
                      Flexible(
                        child: Text(
                          'You are viewing a Future month without any data. Add expenses or incomes first.',
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    ...typeCategories.map((c) {
                      final selectedAmount = ref.watch(
                        amountForCategoryProvider((
                          entries: entriesGrouped ?? [],
                          category: c.id,
                        )),
                      );

                      final percentageOfTotal =
                          (selectedAmount * 100 / totalAmount).clamp(
                            0.0,
                            100.0,
                          );
                      return CategoryCard(
                        category: c,
                        percentageOfTotal: percentageOfTotal,
                        selected: selectedCategory.value == c,
                        selectedAmount: selectedAmount,
                        onTap: () async {
                          if (selectedCategory.value == c) {
                            selectedCategory.value = null;
                          } else {
                            selectedCategory.value = c;
                          }
                          unawaited(HapticFeedback.selectionClick());
                        },
                      );
                    }),
                  ],
                ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.percentageOfTotal,
    required this.selectedAmount,
    required this.category,
    this.onTap,
    this.selected = false,
  });

  final Category category;
  final double percentageOfTotal;
  final num selectedAmount;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Durations.short3,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.15)
              : FluentTheme.of(context).containerColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: FluentTheme.of(context).borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          spacing: 4,
          children: [
            Row(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name),
                        Text(
                          '${percentageOfTotal.toStringAsFixed(2)}% of total',
                          style: context.bodySmall.light,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  selectedAmount.formatCurrencySymbol,
                  style: context.bodyMedium.bold,
                ),
              ],
            ),
            Stack(
              children: [
                Divider(
                  color: category.color.withValues(alpha: 0.2),
                  thickness: 4.0,
                  radius: BorderRadius.circular(12.0),
                ),
                FractionallySizedBox(
                  widthFactor: percentageOfTotal / 100,
                  child: Divider(
                    color: category.color,
                    thickness: 4.0,
                    radius: BorderRadius.circular(12.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
