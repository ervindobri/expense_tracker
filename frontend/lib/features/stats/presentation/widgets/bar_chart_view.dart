import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors, Divider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/presentation/state/entries_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

class BarChartView extends HookConsumerWidget {
  const BarChartView({
    super.key,
    required this.type,
    required this.selectedMonth,
    this.scrollController,
  });

  final CategoryType type;
  final ValueNotifier<int?> selectedMonth;
  final ScrollController? scrollController; 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Entries grouped by month
    final allEntries =
        ref.watch(monthlyEntriesProvider).value ?? const <int, List<Entry>>{};
    const maxHeight = 128.0;
    // No month selected, show total
    final entriesGrouped = selectedMonth.value == null
        ? allEntries.entries.expand((e) => e.value).toList()
        : allEntries[selectedMonth.value];
    final selectedAmount = ref.watch(
      amountForTypeProvider((
        entries: entriesGrouped ?? [],
        type: type,
      )),
    );
    final max = ref.watch(maxMonthProvider(type)).$2.amount;
    final scrolledArea = useState(0.0);
    final height = useState(maxHeight);
    useEffect((){
      void listener(){
        // TODO: scrolling is too fast until the height is 0, slow down shrinking
        scrolledArea.value = (scrollController!.offset / maxHeight) / 2;
        height.value = (maxHeight * (1 - scrolledArea.value)).clamp(0.0, maxHeight);
      }
      scrollController?.addListener(listener);
      return () => scrollController?.removeListener(listener);
    });
    return ColoredBox(
          color: FluentTheme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: lerpDouble(0, 42.0, 1- scrolledArea.value)!.clamp(0, 42.0),
              child: Opacity(
                opacity: 1 - scrolledArea.value.clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FittedBox(
                      child: Row(
                        children: [
                          AnimatedScale(
                            scale: selectedAmount < max ? 1.0 : 0.0,
                            duration: Durations.short3,
                            alignment: Alignment.centerLeft,
                            child: AnimatedSize(
                              duration: Durations.short3,
                              child: SizedBox(
                                width: selectedAmount < max ? 24.0 : 0.0,
                                child: Icon(
                                  LucideIcons.arrowDown,
                                  color: FluentTheme.of(context).successColor,
                                ),
                              ),
                            ),
                          ),
                          NumberFlow(
                            value: selectedAmount.toDouble(),
                            locale: context.locale.languageCode,
                            suffix: 'Ft',
                            format: const NumberFlowFormat.currency(
                              maxFraction: 2,
                              sign: SignDisplay.negative,
                              currencyCode: '',
                            ),
                            style: context.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: lerpDouble(0, .3, 1- scrolledArea.value)!.clamp(0.0, .3),
                      child: Text(max.formatCurrency, style: context.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const MySeparator(),
                SizedBox(
                  height: height.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 4,
                    children: [
                      ...List.generate(12, (i) {
                        final month = i + 1;
                        final totalOfMonth = allEntries.isEmpty
                            ? 0.0
                            : ref.watch(
                                amountForTypeProvider((
                                  entries: allEntries[month] ?? [],
                                  type: type,
                                )),
                              );
                  
                        final calcHeight = allEntries.isEmpty
                            ? 0.0
                            : totalOfMonth / max;
                        return GestureDetector(
                          onTap: () {
                            if (selectedMonth.value == month) {
                              selectedMonth.value = null;
                            } else {
                              selectedMonth.value = month;
                            }
                            unawaited(HapticFeedback.lightImpact());
                          },
                          child: AnimatedContainer(
                            duration: Durations.medium1,
                            height: (calcHeight * maxHeight).clamp(0.0, 248.0),
                            width: 20,
                            decoration: BoxDecoration(
                              color: FluentTheme.of(context).textColor.withValues(
                                    alpha: selectedMonth.value == month
                                        ? 1.0
                                        : selectedMonth.value == null
                                        ? 1.0
                                        : 0.5,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Divider(height: 1.0, color: FluentTheme.of(context).dividerColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...List.generate(12, (i) {
                  final month = i + 1;
                  final isSelected = selectedMonth.value == month;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (selectedMonth.value == month) {
                          selectedMonth.value = null;
                        } else {
                          selectedMonth.value = month;
                        }
                        unawaited(HapticFeedback.lightImpact());
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.25 : 0.95,
                        duration: Durations.short3,
                        child: Container(
                          width: 24,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            month.toMonthLabelShort,
                            style: selectedMonth.value == month
                                ? context.bodySmall?.bold
                                : context.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class MySeparator extends StatelessWidget {
  const MySeparator({Key? key, this.height = 1, this.color = Colors.white})
    : super(key: key);
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).dividerColor,
                ),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}
