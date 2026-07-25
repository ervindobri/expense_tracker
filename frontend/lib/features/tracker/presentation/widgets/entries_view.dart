import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/widgets/pill_tabbar.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:frontend/features/tracker/presentation/state/passthrough_enabled_notifier.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/sheet/entry_sheet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

enum WeekSelector { one, two, three, four, five, all }

class EntriesView extends HookConsumerWidget {
  const EntriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportProvider);
    final now = DateTime.now();

    final firstDayOfMonth = now.copyWith(
      month: month,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0,
    );
    // default current week
    final currentWeek = now.copyWith(month: month).currentWeek;
    final currentMonth = now.month;
    final week = useState(currentWeek);
    final selectedType = useState(CategoryType.expense);
    final isTotal = useState(false);

    final categories = ref.watch(categoriesProvider);
    final entries = ref.watch(monthlyEntriesProvider);
    final scrollController = useScrollController();
    final parentController = useScrollController();
    final topPadding = MediaQuery.paddingOf(context).top;
    // Scrolling offset for animation
    final offset = useState(0.0);
    final scrolled = useState(0.0);
    final passthroughNotifier = ref.read(passThroughEnabledProvider.notifier);
    useEffect(() {
      void listener() {
        scrolled.value = parentController.offset.abs();
        offset.value = scrolled.value / (balanceHeight / 2);
        passthroughNotifier.set(offset.value < 0.5);
        if (kDebugMode) {
          print(offset.value);
        }
      }

      parentController.addListener(listener);
      return () => parentController.removeListener(listener);
    });

    return ClipRRect(
      child: BackdropFilter(
        filterConfig: ImageFilterConfig.blur(
          sigmaX: lerpDouble(0, 12, offset.value)!,
          sigmaY: lerpDouble(0, 12, offset.value)!,
        ),
        child: RefreshIndicator.adaptive(
          onRefresh: (){
            ref.invalidate(entriesProvider);
            return Future.value();
          },
          child: CustomScrollView(
            controller: parentController,
            // mainAxisSize: MainAxisSize.min,
            // spacing: 32,
            slivers: [
              const SliverToBoxAdapter(
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox(height: balanceHeight),
                ),
              ),
              PinnedHeaderSliver(
                child: AnimatedContainer(
                  duration: Durations.short3,
                  decoration: BoxDecoration(
                    color: offset.value < 1.5
                        ? Colors.transparent
                        : FluentTheme.of(context).cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36.0),
                    ),
                  ),
                  padding: EdgeInsets.only(top: topPadding),
                  child: SizedBox(
                    height: 48,
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: 6,
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, index) {
                        return SizedBox(width: 32);
                      },
                      itemBuilder: (_, index) {
                        final isSelected = week.value == index + 1;
                        return AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: Duration(milliseconds: 100),
                          child: Material(
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (index == 5) {
                                  week.value = index + 1;
                                  isTotal.value = true;
                                } else {
                                  week.value = index + 1;
                                  isTotal.value = false;
                                }
          
                                const itemCount = 6;
                                final maxExtent =
                                    scrollController.position.maxScrollExtent;
                                final itemExtent =
                                    maxExtent /
                                    (itemCount -
                                        1); // distance between each item's scroll position
                                final offset = (itemExtent * index).clamp(
                                  0.0,
                                  maxExtent,
                                );
          
                                scrollController.animateTo(
                                  offset,
                                  duration: Durations.short2,
                                  curve: Curves.easeIn,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                  horizontal: 4.0,
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: Durations.short1,
                                    child: Text(
                                      key: ValueKey(index),
                                      (month == currentMonth && currentWeek == index ? '(c)' : '') +
                                          (index == 5
                                              ? "Total"
                                              : "Week ${index + 1}"),
                                      style: Theme.of(context).textTheme.bodyLarge
                                          ?.copyWith(
                                            // color: isSelected ? Colors.black : null,
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.w300,
                                            fontSize: isSelected ? 16 : 12,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          
              PinnedHeaderSliver(
                child: Container(
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).cardColor,
                    borderRadius: BorderRadius.lerp(
                      BorderRadius.vertical(top: Radius.circular(36.0)),
                      BorderRadius.zero,
                      offset.value,
                    ),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExpenseIncomeTabBar<CategoryType>(
                        items: CategoryType.values,
                        initialTab: selectedType.value,
                        itemToString: (val) => val.displayName,
                        onChanged: (val) {
                          selectedType.value = val;
                        },
                      ),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall!.color?.withAlpha(128),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text("Category"), Text("Total (Ft)")],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height,
                  child: Material(
                    color: FluentTheme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          ...categories.value
                                  ?.where((cat) => cat.type == selectedType.value)
                                  .map((cat) {
                                    final weeklimits = week.value.weekLimits;
                                    final entriesForCatWeek = entries.value?.items
                                        .where(
                                          (e) => isTotal.value
                                              ? e.category == cat.id
                                              : e.category == cat.id &&
                                                    (e.addedDate.isAfter(
                                                          firstDayOfMonth
                                                              .copyWith(
                                                                day:
                                                                    weeklimits.$1,
                                                              ),
                                                        ) &&
                                                        e.addedDate.isBefore(
                                                          firstDayOfMonth
                                                              .copyWith(
                                                                day:
                                                                    weeklimits.$2,
                                                                hour: 23,
                                                                minute: 59,
                                                                second: 59,
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
                                      splashColor: Colors.transparent,
                                      borderRadius: BorderRadius.circular(32),
                                      onTap: () async {
                                        if (week.value == 6) {
                                          return;
                                        }
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => EntrySheet(
                                            week: week.value,
                                            category: cat,
                                            entries:
                                                entriesForCatWeek ??
                                                const <Entry>[],
                                          ),
                                        );
                                        ref.invalidate(entriesProvider);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 12.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(cat.name),
                                            NumberFlow(
                                                key: ValueKey(totalForCategory),
                                              value: totalForCategory,
                                              format: NumberFlowFormat.decimal(),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

