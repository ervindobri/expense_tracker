import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/core/widgets/pill_tabbar.dart';
import 'package:frontend/core/widgets/snap_scroll_physics.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/presentation/state/categories_provider.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:frontend/features/tracker/presentation/state/passthrough_enabled_notifier.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/sheet/entry_sheet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';

enum WeekSelector { one, two, three, four, five, all }

enum EntriesViewType { table, list }

extension ViewTypeExt on EntriesViewType {
  String get display => switch (this) {
    .table => '📋',
    .list => '📅',
  };
}

class EntriesView extends HookConsumerWidget {
  const EntriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportProvider);
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);
    final DateTime now = DateTime.now();
    final entries = ref.watch(currentMonthlyEntriesProvider);

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

    final viewType = useState(EntriesViewType.table);

    useEffect(() {
      void listener() {
        scrolled.value = parentController.offset.abs();
        offset.value = scrolled.value / (balanceHeight / 2);
        passthroughNotifier.set(offset.value < 0.5);

        if (scrolled.value % 5 == 0) {
          unawaited(HapticFeedback.lightImpact());
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
                HapticFeedback.selectionClick(),
                Future.delayed(Durations.short2),
                HapticFeedback.selectionClick(),
                Future.delayed(Durations.short2),
                HapticFeedback.selectionClick(),
                Future.delayed(Durations.short2),
              ]),
            );
            return Future<void>.value();
          },
          child: WebSmoothScroll(
            controller: parentController,
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
                if (!kIsWeb)
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
                                Text(
                                  'history'.tr(),
                                  style: theme.bodyLarge.bold,
                                ),
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
                                  child: const Text(LocaleKeys.nowLabel).tr(),
                                ),
                              ],
                            ),
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'history'.tr(),
                                  style: theme.bodyLarge.bold,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ContextMenuOverlay<int>(
                                    title: LocaleKeys.selectMonthLabel.tr(),
                                    itemBuilder:
                                        (BuildContext context, int item) =>
                                            Text(
                                              item + 1 == currentMonth
                                                  ? 'this_month'.tr()
                                                  : (item + 1).toMonthLabel,
                                            ),
                                    onSelected: (item) {
                                      ref
                                          .read(reportProvider.notifier)
                                          .set(item + 1);
                                      if (month != item + 1) {
                                        // set week to Total
                                        week.value = 6;
                                        isTotal.value = true;
                                        scrollController.animateTo(
                                          scrollController
                                              .position
                                              .maxScrollExtent,
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
                                              ? 'this_month'.tr()
                                              : month.toMonthLabel,
                                        ),
                                        const Icon(
                                          LucideIcons.chevronDown,
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
                  ),
                PinnedHeaderSliver(
                  child: AnimatedContainer(
                    duration: Durations.short3,
                    decoration: BoxDecoration(
                      color: offset.value < 1.5
                          ? Colors.transparent
                          : FluentTheme.of(context).cardColor,
                    ),
                    padding: kIsWeb
                        ? const EdgeInsets.symmetric(vertical: 24.0)
                        : null,
                    child: Row(
                      children: [
                        SizedBox(
                          height: 48,
                          child: AnimatedCrossFade(
                            duration: kThemeAnimationDuration,
                            crossFadeState:
                                viewType.value == EntriesViewType.table
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            secondChild: Center(
                              child: Text(
                                'All transactions this month',
                                style: theme.headlineSmall,
                              ),
                            ),
                            firstChild: ListView.separated(
                              controller: scrollController,
                              itemCount: 6,
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8.0,
                              ),
                              scrollDirection: Axis.horizontal,
                              separatorBuilder: (_, int index) {
                                return const SizedBox(
                                  width: kIsWeb ? 24.0 : 12.0,
                                );
                              },
                              itemBuilder: (_, int index) {
                                final bool isSelected = week.value == index + 1;
                                return AnimatedScale(
                                  scale: isSelected ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Material(
                                    surfaceTintColor: Colors.transparent,
                                    elevation: 0,
                                    color: isSelected && kIsWeb
                                        ? FluentTheme.of(context).chipColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(99),
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
                                            scrollController
                                                .position
                                                .maxScrollExtent;
                                        final double itemExtent =
                                            maxExtent /
                                            (itemCount -
                                                1); // distance between each item's scroll position
                                        final double offset =
                                            (itemExtent * index).clamp(
                                              0.0,
                                              maxExtent,
                                            );

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
                                                          currentWeek ==
                                                              index + 1
                                                      ? '⏰'
                                                      : '') +
                                                  (index == 5
                                                      ? LocaleKeys.total.tr()
                                                      : LocaleKeys.week.tr(
                                                          namedArgs: {
                                                            'value':
                                                                '${index + 1}',
                                                          },
                                                        )),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: isSelected && kIsWeb
                                                        ? FluentTheme.of(
                                                            context,
                                                          ).inverseTextColor
                                                        : null,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w300,
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
                        if (kIsWeb)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: DefaultTextStyle(
                                style: theme.bodySmall!.copyWith(
                                  fontSize: 12,
                                  color: theme.bodySmall?.color?.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 12,
                                  children: [
                                    Column(
                                      spacing: 2,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Last edited'),
                                        Text(
                                          entries
                                                  .value
                                                  ?.lastCreated
                                                  .formatDayShort ??
                                              '',
                                        ),
                                      ],
                                    ),
                                    ExpenseIncomeTabBar<EntriesViewType>(
                                      onChanged: (val) {
                                        viewType.value = val;
                                      },
                                      itemWidth: 32.0,
                                      backgroundColor: FluentTheme.of(
                                        context,
                                      ).containerColor,
                                      itemToString: (v) => v.display,
                                      items: EntriesViewType.values,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (viewType.value == EntriesViewType.table)
                  PinnedHeaderSliver(
                    child: Container(
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context).cardColor,
                        borderRadius: BorderRadius.lerp(
                          const BorderRadius.vertical(
                            top: Radius.circular(36.0),
                          ),
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
                            itemToString: (CategoryType val) =>
                                val == CategoryType.expense
                                ? LocaleKeys.expenses.tr()
                                : LocaleKeys.incomes.tr(),
                            onChanged: (CategoryType val) {
                              selectedType.value = val;
                            },
                          ),

                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.color?.withAlpha(128),
                                ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Text(LocaleKeys.categoryLabel).tr(),
                                  Text(switch (ref.currency) {
                                    .huf => LocaleKeys.totalFtLabel,
                                    _ => 'Total(${ref.currency.symbol})',
                                  }).tr(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (categories.value != null && categories.value!.isNotEmpty)
                  switch (viewType.value) {
                    .table => SliverToBoxAdapter(
                      child: SizedBox(
                        height: kIsWeb
                            ? context.height
                            : 36.0 * (categories.value?.length ?? 0) +
                                  96 +
                                  32.0 +
                                  16,
                        child: Material(
                          color: FluentTheme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Builder(
                              builder: (context) {
                                final (int, int) weeklimits =
                                    week.value.weekLimits;
                                final weeklyEntries =
                                    entries.value?.items.where(
                                      (e) =>
                                          (categories.value ?? [])
                                              .where(
                                                (e) =>
                                                    e.type ==
                                                    selectedType.value,
                                              )
                                              .map((e) => e.id)
                                              .contains(e.category) &&
                                          e.addedDate.isDayAfterOrSame(
                                            firstDayOfMonth.copyWith(
                                              day: weeklimits.$1,
                                            ),
                                          ) &&
                                          // last day of the month is 0th day of next month
                                          e.addedDate.isDayBeforeOrsame(
                                            firstDayOfMonth.copyWith(
                                              month:
                                                  week.value == 5 ||
                                                      week.value == 6
                                                  ? month + 1
                                                  : month,
                                              day:
                                                  week.value == 5 ||
                                                      week.value == 6
                                                  ? 0
                                                  : weeklimits.$2,
                                              hour: 23,
                                              minute: 59,
                                              second: 59,
                                            ),
                                          ),
                                    ) ??
                                    [];
                                final weeklyTotal = weeklyEntries.fold<double>(
                                  0.0,
                                  (prod, entry) => prod + entry.amount,
                                );
                                final isExpense =
                                    selectedType.value == CategoryType.expense;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          dense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12.0,
                                              ),
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                LocaleKeys.total.tr(),
                                                style: theme.bodyMedium.bold,
                                              ),
                                              Text(
                                                '${ref.convertedAmount(weeklyTotal).formatCurrency}',
                                                style: theme.bodyMedium?.bold
                                                    ?.copyWith(
                                                      color:
                                                          selectedType.value ==
                                                              CategoryType
                                                                  .expense
                                                          ? weeklyTotal > 100000
                                                                ? FluentTheme.of(
                                                                    context,
                                                                  ).failureColor
                                                                : null
                                                          : weeklyTotal > 100000
                                                          ? FluentTheme.of(
                                                              context,
                                                            ).successColor
                                                          : null,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...categories.value
                                            ?.where(
                                              (Category cat) =>
                                                  cat.type ==
                                                  selectedType.value,
                                            )
                                            .map((Category cat) {
                                              final List<Entry>?
                                              entriesForCatWeek =
                                                  entries.value?.items
                                                      .where(
                                                        (e) => isTotal.value
                                                            ? e.category ==
                                                                  cat.id
                                                            : e.category ==
                                                                      cat.id &&
                                                                  (e.addedDate.isDayAfterOrSame(
                                                                        firstDayOfMonth.copyWith(
                                                                          day: weeklimits
                                                                              .$1,
                                                                        ),
                                                                      ) &&
                                                                      e.addedDate.isDayBeforeOrsame(
                                                                        firstDayOfMonth.copyWith(
                                                                          month:
                                                                              week.value ==
                                                                                      5 ||
                                                                                  week.value ==
                                                                                      6
                                                                              ? month +
                                                                                    1
                                                                              : month,
                                                                          day:
                                                                              week.value ==
                                                                                      5 ||
                                                                                  week.value ==
                                                                                      6
                                                                              ? 0
                                                                              : weeklimits.$2,
                                                                          hour:
                                                                              23,
                                                                          minute:
                                                                              59,
                                                                          second:
                                                                              59,
                                                                        ),
                                                                      )),
                                                      )
                                                      .toList() ??
                                                  <Entry>[];
                                              final double totalForCategory =
                                                  entriesForCatWeek!
                                                      .fold<double>(
                                                        0.0,
                                                        (curre, Entry b) =>
                                                            curre + b.amount,
                                                      );
                                              return InkWell(
                                                splashColor: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                                onTap: () async {
                                                  unawaited(
                                                    HapticFeedback.selectionClick(),
                                                  );
                                                  final edited = ValueNotifier(
                                                    false,
                                                  );
                                                  if (kIsWeb) {
                                                    await showDialog(
                                                      context: context,
                                                      builder: (_) {
                                                        return Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          constraints:
                                                              const BoxConstraints(
                                                                maxWidth: 540,
                                                              ),
                                                          child: EntrySheet(
                                                            week: week.value,
                                                            category: cat,
                                                            entries:
                                                                entriesForCatWeek,
                                                            onEdited: (value) {
                                                              edited.value =
                                                                  value;
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    await showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      builder: (_) => EntrySheet(
                                                        week: week.value,
                                                        category: cat,
                                                        entries:
                                                            entriesForCatWeek,
                                                        onEdited: (value) {
                                                          edited.value = value;
                                                        },
                                                      ),
                                                    );
                                                  }

                                                  if (edited.value) {
                                                    ref.invalidate(
                                                      entriesProvider,
                                                    );
                                                  }
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
                                                            value: ref
                                                                .convertedAmount(
                                                                  totalForCategory,
                                                                ),
                                                            continuous: true,
                                                            prefix:
                                                                totalForCategory <=
                                                                    0
                                                                ? null
                                                                : isExpense
                                                                ? '-'
                                                                : '+',
                                                            locale: context
                                                                .locale
                                                                .languageCode,

                                                            format:
                                                                const NumberFlowFormat.currency(
                                                                  maxFraction:
                                                                      2,

                                                                  sign: SignDisplay
                                                                      .negative,
                                                                  currencyCode:
                                                                      '',
                                                                ),
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
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    .list => SliverToBoxAdapter(
                      child: Column(
                        spacing: 24,
                        children: [
                          // Group by day
                          ...entries.value?.grouped.entries.map((entry) {
                                final cats = categories.value;
                                final dailyTotalAmount = entry.value.fold(0.0, (
                                  a,
                                  b,
                                ) {
                                  final isExpense =
                                      cats
                                          ?.firstWhere(
                                            (cat) => cat.id == b.category,
                                          )
                                          .isExpense ??
                                      false;
                                  return isExpense
                                      ? a - b.amount
                                      : a + b.amount;
                                });
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 12,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(entry.key.formatDate),
                                          Text(
                                            dailyTotalAmount
                                                .formatCurrencySymbol(),
                                            style: theme.bodySmall?.copyWith(
                                              color: theme.bodySmall?.color
                                                  ?.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...entry.value.map(
                                      (e) => EntryCard(entry: e),
                                    ),
                                  ],
                                );
                              }) ??
                              [],
                        ],
                      ),
                    ),
                  },

                const SliverToBoxAdapter(
                  child: SizedBox(height: kToolbarHeight + 48.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EntryCard extends HookConsumerWidget {
  const EntryCard({super.key, required this.entry});
  final Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryState = useState(entry);
    final categories = ref.watch(categoriesProvider);
    final category = categories.value == null
        ? Category(name: 'name', type: .expense, id: 0)
        : categories.value?.firstWhere(
            (Category cat) => cat.id == entry.category,
          );
    final isExpense = category?.isExpense ?? true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Material(
        color: FluentTheme.of(context).cardColor,
        child: InkWell(
          onTap: () async {
            unawaited(HapticFeedback.selectionClick());
            if (kIsWeb) {
              final instance = await showDialog<Entry?>(
                context: context,
                builder: (_) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: SingleEntrySheet(entry: entryState.value),
                  );
                },
              );
              if (instance != null) {
                ToastificationService.showSuccess(
                  context: context,
                  title: 'Entry edited successfully!',
                );
                entryState.value = instance;
              }
            } else {
              final instance = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SingleEntrySheet(entry: entryState.value),
              );
              if (instance != null) {
                ToastificationService.showSuccess(
                  context: context,
                  title: 'Entry edited successfully!',
                );
                entryState.value = instance;
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: category?.color,
                      child: Center(
                        child: Text(
                          category?.emoji ?? '',
                          style: const TextStyle(fontSize: 24.0),
                        ),
                      ),
                    ),
                    Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category?.name ?? ''),
                        Text(
                          entryState.value.notes.isEmpty
                              ? 'No notes added'
                              : entryState.value.notes,
                          style: TextTheme.of(context).bodyMedium?.copyWith(
                            color: TextTheme.of(context).bodyMedium?.color
                                ?.withValues(
                                  alpha: entryState.value.notes.isEmpty
                                      ? 0.5
                                      : 1.0,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  (isExpense ? '-' : '+') +
                      entry.amount.formatCurrencySymbol(showDecimals: true),
                  style: TextTheme.of(context).bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
