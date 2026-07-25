import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' hide IconButton, Tooltip;
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/features/tracker/presentation/state/balance_provider.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

class BalanceView extends HookConsumerWidget {
  const BalanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;
    // final compact = isCompactLayout(context);
    final selected = ref.watch(reportProvider);
    final balanceForMonth = ref.watch(balanceProvider(selected));
    return Container(
      height: balanceHeight, //fixed
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(color: FluentTheme.of(context).activeColor),
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 24,
                  children: [
                    SizedBox(
                      child: ContextMenuOverlay<int>(
                        itemBuilder: (BuildContext context, int item) =>
                            Text((item + 1).toMonthLabel),
                        onSelected: (item) {
                          ref.read(reportProvider.notifier).set(item + 1);
                        },
                        items: List.generate(12, growable: false, (i) => i),
                        child: Row(
                          spacing: 8,
                          children: [
                            Text(selected.toMonthLabel),
                            Icon(FluentIcons.chevron_down, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Calculated balance from filtered month
              Column(
                spacing: 24,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    spacing: 12,
                    children: [
                      Text(
                        'TOTAL BALANCE',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: Row(
                          spacing: 4,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NumberFlow(
                              value: (balanceForMonth.value?.totalAmount ?? 0.0),
                              style: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.copyWith(),
                            // format: NumberFlowFormat.currency(currencyCode: currencyCode),
                            ),
                            Text(
                              'Ft',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    // spacing: 48,
                    children: [
                      Expanded(
                        child: Column(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Expenses',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            Text(
                              //TODO: animate text
                              (balanceForMonth.value?.expenses ?? 0.0)
                                  .formatCurrencySymbol,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 12,
                          children: [
                            Text(
                              'Incomes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            Text(
                              //TODO: animate text
                              (balanceForMonth.value?.incomes ?? 0.0)
                                  .formatCurrencySymbol,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.greenAccent),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 12,
                          children: [
                            Text(
                              'Savings',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            Text(
                              //TODO: animate text
                              (balanceForMonth.value?.savings ?? 0.0)
                                  .formatCurrencySymbol,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 32,
            child: Tooltip(
              message: isDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              child: IconButton(
                icon: Icon(
                  isDark ? FluentIcons.sunny : FluentIcons.clear_night,
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension<E> on int {
  String get toMonthLabel => switch (this) {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December',
    _ => toString(),
  };
}
