import 'dart:async';
import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart' show FluentTheme, FluentIcons;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/core/widgets/pill_tabbar.dart';
import 'package:frontend/core/widgets/snap_scroll_physics.dart';
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
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);
    final DateTime now = DateTime.now();
    final entries = ref.watch(monthlyEntriesProvider);

    final DateTime firstDayOfMonth = now.copyWith(
      month: month,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    // default current week
    final int currentWeek = now.copyWith(month: month).currentWeek;
    final int currentMonth = now.month;
    final ValueNotifier<int> week = useState(currentWeek);
    final ValueNotifier<CategoryType> selectedType = useState(
      CategoryType.expense,
    );
    final ValueNotifier<bool> isTotal = useState(false);

    final ScrollController scrollController = useScrollController();
    final ScrollController parentController = useScrollController();
    // final double topPadding = MediaQuery.paddingOf(context).top;
    // Scrolling offset for animation
    final ValueNotifier<double> offset = useState(0.0);
    final ValueNotifier<double> scrolled = useState(0.0);
    final PassThroughEnabledNotifier passthroughNotifier = ref.read(
      passThroughEnabledProvider.notifier,
    );
    useEffect(() {
      void listener() {
        scrolled.value = parentController.offset.abs();
        offset.value = scrolled.value / (balanceHeight / 2);
        passthroughNotifier.set(offset.value < 0.5);
        unawaited(HapticFeedback.lightImpact());

        if (kDebugMode) {
          print(offset.value);
        }
      }

      parentController.addListener(listener);
      return () => parentController.removeListener(listener);
    });

    final TextTheme theme = Theme.of(context).textTheme;

    return ClipRRect(
      child: BackdropFilter(
        filterConfig: ImageFilterConfig.blur(
          sigmaX: lerpDouble(0, 12, offset.value)!,
          sigmaY: lerpDouble(0, 12, offset.value)!,
        ),
        child: RefreshIndicator.adaptive(
          onRefresh: () {
            ref.invalidate(monthlyEntriesProvider);
            unawaited(
              Future.wait([
                HapticFeedback.vibrate(),
                HapticFeedback.selectionClick(),
                HapticFeedback.selectionClick(),
              ]),
            );
            return Future<void>.value();
          },
          child: CustomScrollView(
            controller: parentController,
            hitTestBehavior: HitTestBehavior.deferToChild,
            physics: const HalfwaySnapPhysics(snapExtent: balanceHeight),
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox(height: balanceHeight),
                ),
              ),
              PinnedHeaderSliver(
                child: Padding(
                  padding: EdgeInsetsGeometry.only(
                    top: lerpDouble(
                      0,
                      MediaQuery.viewPaddingOf(context).top,
                      (offset.value / 2).clamp(0.0, 1.0),
                    )!,
                  ),
                  child: AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('📆 History', style: theme.bodyLarge.bold),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: FluentTheme.of(
                                context,
                              ).textColor,
                              padding: const EdgeInsets.all(4),
                              backgroundColor: Colors.transparent,
                              textStyle: theme.bodySmall?.copyWith(
                                color: FluentTheme.of(context).textColor,
                              ),
                            ),
                            onPressed: () {
                              week.value = currentWeek;
                              isTotal.value = false;
                              unawaited(HapticFeedback.selectionClick());
                            },
                            child: const Text('Now'),
                          ),
                        ],
                      ),
                    ),
                    secondChild: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('📆 History', style: theme.bodyLarge.bold),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ContextMenuOverlay<int>(
                              title: 'Select month',
                              itemBuilder: (BuildContext context, int item) =>
                                  Text(
                                    item + 1 == currentMonth
                                        ? 'This month'
                                        : (item + 1).toMonthLabel,
                                  ),
                              onSelected: (item) {
                                ref.read(reportProvider.notifier).set(item + 1);
                                if (month != item + 1) {
                                  // set week to Total
                                  week.value = 6;
                                  isTotal.value = true;
                                  scrollController.animateTo(
                                    scrollController.position.maxScrollExtent,
                                    duration: Durations.short2,
                                    curve: Curves.bounceInOut,
                                  );
                                }
                                unawaited(HapticFeedback.mediumImpact());
                              },
                              items: List.generate(
                                12,
                                growable: false,
                                (i) => i,
                              ),
                              child: Row(
                                spacing: 8,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    month == currentMonth
                                        ? 'This month'
                                        : month.toMonthLabel,
                                  ),
                                  const Icon(
                                    FluentIcons.chevron_down,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: offset.value >= 1.5
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: Durations.short3,
                  ),
                ),
              ),
              PinnedHeaderSliver(
                child: AnimatedContainer(
                  duration: Durations.short3,
                  decoration: BoxDecoration(
                    color: offset.value < 1.5
                        ? Colors.transparent
                        : FluentTheme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(36.0),
                    ),
                  ),
                  child: SizedBox(
                    height: 48,
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: 6,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, int index) {
                        return const SizedBox(width: 32);
                      },
                      itemBuilder: (_, int index) {
                        final bool isSelected = week.value == index + 1;
                        return AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 100),
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

                                const int itemCount = 6;
                                final double maxExtent =
                                    scrollController.position.maxScrollExtent;
                                final double itemExtent =
                                    maxExtent /
                                    (itemCount -
                                        1); // distance between each item's scroll position
                                final double offset = (itemExtent * index)
                                    .clamp(0.0, maxExtent);

                                scrollController.animateTo(
                                  offset,
                                  duration: Durations.short2,
                                  curve: Curves.easeIn,
                                );
                                unawaited(HapticFeedback.lightImpact());
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
                                      key: ValueKey<int>(index),
                                      (month == currentMonth &&
                                                  currentWeek == index + 1
                                              ? '*'
                                              : '') +
                                          (index == 5
                                              ? 'Total'
                                              : 'Week ${index + 1}'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
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
                      const BorderRadius.vertical(top: Radius.circular(36.0)),
                      BorderRadius.zero,
                      offset.value,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ExpenseIncomeTabBar<CategoryType>(
                        items: CategoryType.values,
                        initialTab: selectedType.value,
                        itemToString: (CategoryType val) => val.displayName,
                        onChanged: (CategoryType val) {
                          selectedType.value = val;
                        },
                      ),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall!.color?.withAlpha(128),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Category'),
                              Text('Total (Ft)'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 32.0 * (categories.value?.length ?? 0) + 96 + 32.0,
                  child: Material(
                    color: FluentTheme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: <Widget>[
                          ...categories.value
                                  ?.where(
                                    (Category cat) =>
                                        cat.type == selectedType.value,
                                  )
                                  .map((Category cat) {
                                    final (int, int) weeklimits =
                                        week.value.weekLimits;
                                    final List<Entry>? entriesForCatWeek =
                                        entries.value?.items
                                            .where(
                                              (e) => isTotal.value
                                                  ? e.category == cat.id
                                                  : e.category == cat.id &&
                                                        (e.addedDate.isDayAfterOrSame(
                                                              firstDayOfMonth
                                                                  .copyWith(
                                                                    day:
                                                                        weeklimits
                                                                            .$1,
                                                                  ),
                                                            ) &&
                                                            e.addedDate
                                                                .isDayBeforeOrsame(
                                                                  firstDayOfMonth
                                                                      .copyWith(
                                                                        day: weeklimits
                                                                            .$2,
                                                                      ),
                                                                )),
                                            )
                                            .toList() ??
                                        <Entry>[];
                                    final double totalForCategory =
                                        entriesForCatWeek!.fold<double>(
                                          0.0,
                                          (curre, Entry b) => curre + b.amount,
                                        );
                                    return InkWell(
                                      splashColor: Colors.transparent,
                                      borderRadius: BorderRadius.circular(32),
                                      onTap: () async {
                                        unawaited(
                                          HapticFeedback.selectionClick(),
                                        );
                                        if (kIsWeb) {
                                          await showDialog(
                                            context: context,
                                            builder: (_) {
                                              return Dialog(
                                                backgroundColor: Colors.transparent,
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 540,
                                                    ),
                                                child: EntrySheet(
                                                  week: week.value,
                                                  category: cat,
                                                  entries:
                                                      entriesForCatWeek,
                                                ),
                                              );
                                            },
                                          );
                                        } else {
                                          await showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => EntrySheet(
                                              week: week.value,
                                              category: cat,
                                              entries: entriesForCatWeek,
                                            ),
                                          );
                                        }
                                        ref.invalidate(entriesProvider);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 12.0,
                                        ),
                                        child: SizedBox(
                                          height: 24,
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Text(cat.name),
                                                NumberFlow(
                                                  value: totalForCategory,
                                                  continuous: true,
                                                  format:
                                                      const NumberFlowFormat.decimal(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList() ??
                              <Widget>[],
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
