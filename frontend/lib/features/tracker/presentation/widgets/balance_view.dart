import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' hide IconButton, Tooltip;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/features/tracker/presentation/state/balance_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BalanceView extends HookConsumerWidget {
  const BalanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;
    // final compact = isCompactLayout(context);
    final selected = useState(DateTime.now().month);
    final balanceForMonth = ref.watch(balanceProvider(selected.value +1));
    return Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
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
                    itemBuilder: (BuildContext context, int item) => Text((item+1).toMonthLabel,),
                    onSelected: (item) {
                      selected.value = item;
                    },
                    items: List.generate(12, growable: false, (i) => i),
                    child: Row(
                      spacing: 8,
                      children: [
                        Text((selected.value + 1).toMonthLabel),
                        Icon(FluentIcons.chevron_down, size: 12,)
                      ],
                    ),
                  ),
                ),
                Tooltip(
                  message: isDark
                      ? 'Switch to light theme'
                      : 'Switch to dark theme',
                  child: IconButton(
                    icon: Icon(
                      isDark ? FluentIcons.sunny : FluentIcons.clear_night,
                    ),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
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
                  Text(
                    (balanceForMonth.value?.totalAmount ?? 0.0).toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                spacing: 48,
                children: [
                  Column(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Expenses',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Text(
                        (balanceForMonth.value?.expenses ?? 0.0).toString(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    spacing: 12,
                    children: [
                      Text(
                        'Incomes',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Text(
                        (balanceForMonth.value?.incomes ?? 0.0).toString(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    spacing: 12,
                    children: [
                      Text(
                        'Savings',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Text(
                        (balanceForMonth.value?.savings ?? 0.0).toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
