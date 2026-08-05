import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors, Divider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/core/widgets/pill_tabbar.dart';
import 'package:frontend/features/stats/presentation/widgets/bar_chart_view.dart';
import 'package:frontend/features/stats/presentation/widgets/category_chart_view.dart';
import 'package:frontend/features/stats/presentation/year_provider.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StatsScreen extends HookConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = DateTime.now().year;
    final selectedType = useState(CategoryType.expense);
    final selectedMonth = useState<int?>(DateTime.now().month);
    final scrollController = useScrollController();
    final scrolledArea = useState(0.0);
    final selectedYear = useState(currentYear);
    useEffect(() {
      void listener() {
        scrolledArea.value = scrollController.offset;
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    });

    final yearNotifier = ref.read(yearProvider.notifier);
    useEffect(() {
      Future.microtask(() {
        yearNotifier.set(selectedYear.value);
      });
      return null;
    }, [selectedYear.value]);  
    return SafeArea(
      bottom: false,
      top: true,
      child: RefreshIndicator.adaptive(
        onRefresh: () {
          ref.invalidate(monthlyEntriesProvider);
          return Future.value();
        },
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          // crossAxisAlignment: CrossAxisAlignment.start,
          // spacing: 24,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.stats_and_charts.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    ContextMenuOverlay(
                      items: List.generate(3, (i) => i + 2024),
                      itemBuilder: (context, index) {
                        return Text(index.toString());
                      },
                      onSelected: (year) {
                        //selected year
                        selectedYear.value = year;
                      },
                      width: 128,
                      child: Row(
                        children: [
                          Text(
                            selectedYear.value == currentYear
                                ? 'This year'
                                : selectedYear.value.toString(),
                          ),
                          const Icon(LucideIcons.chevronDown),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PinnedHeaderSliver(
              child: Container(
                color: FluentTheme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Center(
                  child: ExpenseIncomeTabBar<CategoryType>(
                    items: CategoryType.values,
                    initialTab: selectedType.value,
                    backgroundColor: FluentTheme.of(context).cardColor,
                    itemToString: (CategoryType val) =>
                        val == CategoryType.expense
                        ? LocaleKeys.expenses.tr()
                        : LocaleKeys.incomes.tr(),
                    onChanged: (CategoryType val) {
                      selectedType.value = val;
                      HapticFeedback.lightImpact();
                      scrollController.animateTo(
                        0.0,
                        duration: Durations.medium2,
                        curve: Curves.easeOutBack,
                      );
                    },
                  ),
                ),
              ),
            ),
            // Bar chart of monthly view
            PinnedHeaderSliver(
              child: BarChartView(
                type: selectedType.value,
                selectedMonth: selectedMonth,
                scrollController: scrollController,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: CategoryChartView(
                  selectedType: selectedType.value,
                  selectedMonth: selectedMonth,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: kToolbarHeight + 48.0),
            ),
          ],
        ),
      ),
    );
  }
}
