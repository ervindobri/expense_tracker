import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum WeekSelector { one, two, three, four, five, all }

class EntriesView extends HookConsumerWidget {
  const EntriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportProvider);
    final firstDayOfMonth = DateTime.now().copyWith(
      month: month,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0,
    );
    final week = useState(DateTime.now().copyWith(month: month).currentWeek);
    final selectedType = useState(<CategoryType>{CategoryType.expense});
    final isTotal = useState(false);

    final categories = ref.watch(categoriesProvider);
    final entries = ref.watch(entriesProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 32,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            itemCount: 6,
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, index) {
              return SizedBox(width: 12);
            },
            itemBuilder: (_, index) {
              final isSelected = week.value == index + 1;
              return Material(
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (index == 5) {
                      week.value = index+1;
                      isTotal.value = true;
                    } else {
                      week.value = index + 1;
                      isTotal.value = false;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2.0,
                      horizontal: 4.0,
                    ),
                    child: Center(
                      child: Text(
                        index == 5 ? "Total" : "Week ${index + 1}",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected ? Colors.black : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.all(24),
            child: CustomScrollView(
              // mainAxisAlignment: MainAxisAlignment.center,
              slivers: [
                // category types:
                PinnedHeaderSliver(
                  child: Column(
                    children: [
                      SegmentedButton(
                        showSelectedIcon: false,
                        onSelectionChanged: (sett) {
                          selectedType.value = sett;
                        },
                        segments: [
                          ...CategoryType.values.map(
                            (e) => ButtonSegment(
                              value: e,
                              label: Text(e.displayName),
                            ),
                          ),
                        ],
                        selected: selectedType.value,
                      ),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Category"),
                              Text("Total (Ft)"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        spacing: 12,
                        children: [
                          // entries
                          ...categories.value
                                  ?.where(
                                    (cat) =>
                                        cat.type == selectedType.value.first,
                                  )
                                  .map((cat) {
                                    final weeklimits = week
                                                            .value
                                                            .weekLimits;
                                    final entriesForCatWeek = entries
                                        .value
                                        ?.items
                                        .where(
                                          (e) =>
                                              isTotal.value
                                              ? e.category == cat.id
                                              : e.category == cat.id && (e.addedDate.isAfter(
                                                      firstDayOfMonth.copyWith(
                                                        day: weeklimits
                                                            .$1,
                                                      ),
                                                    ) &&
                                                    e.addedDate.isBefore(
                                                      firstDayOfMonth.copyWith(
                                                        day: weeklimits
                                                            .$2,
                                                      ),
                                                    )),
                                        )
                                        .toList();
                                    final totalForCategory =
                                        entriesForCatWeek?.fold(
                                          0.0,
                                          (curre, b) => curre + b.amount,
                                        ) ??
                                        0.0;
                                    return InkWell(
                                      onTap: () {
                                        // TODO: open add sheet to add expense
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(cat.name),
                                            AnimatedSwitcher(
                                              duration: kThemeAnimationDuration,
                                              child: Text(
                                                key: ValueKey(totalForCategory),
                                                textAlign: TextAlign.end,
                                                totalForCategory.toString(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                                  .toList() ??
                              [],
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension on CategoryType {
  String get displayName => switch (this) {
    CategoryType.expense => '🛍️ Expenses',
    CategoryType.income => '💰 Incomes',
  };
}

extension on DateTime {
  // limits: 1-6, 7-13, 14-20, 21-27, 2
  int get currentWeek => day < 7
      ? 1
      : day < 14
      ? 2
      : day < 21
      ? 3
      : day < 28
      ? 4
      : 5;
}

extension on int {
  (int first, int last) get weekLimits {
    return switch (this) {
      1 => (1, 6),
      2 => (7, 13),
      3 => (14, 20),
      4 => (21, 27),
      5 => (28, 31),
      _ => (0, 0),
    };
  }
}
