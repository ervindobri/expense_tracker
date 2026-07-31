import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide IconButton, Tooltip, ButtonStyle;
import 'package:flutter/services.dart';
import 'package:frontend/core/app/app.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/features/tracker/presentation/state/balance_provider.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

class BalanceView extends HookConsumerWidget {
  const BalanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = FluentTheme.of(context).brightness == Brightness.dark;
    // final compact = isCompactLayout(context);
    final month = ref.watch(reportProvider);
    final balanceForMonth = ref.watch(balanceProvider(month));
    final currentMonth = DateTime.now().month;
    return Container(
      height: balanceHeight, //fixed
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(color: FluentTheme.of(context).borderColor),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ContextMenuOverlay<int>(
                  title: LocaleKeys.select_month.tr(),
                  itemBuilder: (BuildContext context, int item) => Text(
                    item + 1 == currentMonth
                        ? LocaleKeys.this_month.tr()
                        : (item + 1).toMonthLabel,
                  ),
                  onSelected: (item) {
                    ref.read(reportProvider.notifier).set(item + 1);
                    unawaited(HapticFeedback.mediumImpact());
                  },
                  items: List.generate(12, growable: false, (i) => i),
                  child: Row(
                    spacing: 8,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        month == currentMonth
                            ? LocaleKeys.this_month.tr()
                            : month.toMonthLabel,
                      ),
                      const Icon(LucideIcons.chevronDown, size: 12),
                    ],
                  ),
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
                        LocaleKeys.total_balance.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: Row(
                          spacing: 4,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NumberFlow(
                              value: balanceForMonth.value?.totalAmount ?? 0.0,
                              motionBlur: 4.0,
                              locale: context.locale.languageCode,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.copyWith(),
                            ),
                            Text(
                              LocaleKeys.ft.tr(),
                              style: Theme.of(context).textTheme.headlineLarge,
                              maxLines: 1,
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
                              '🔺 ${LocaleKeys.expenses.tr()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            Text(
                              (balanceForMonth.value?.expenses ?? 0.0)
                                  .formatCurrencySymbol(),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: FluentTheme.of(context).failureColor,
                                  ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 12,
                          children: [
                            Text(
                              LocaleKeys.incomes.tr(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            Text(
                              (balanceForMonth.value?.incomes ?? 0.0)
                                  .formatCurrencySymbol(),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: FluentTheme.of(context).successColor,
                                  ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 12,
                          children: [
                            Text(
                              LocaleKeys.savings.tr(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            Text(
                              (balanceForMonth.value?.savings ?? 0.0)
                                  .formatCurrencySymbol(),
                              style: Theme.of(context).textTheme.bodyLarge,
                              maxLines: 1,
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
            child: IconButton(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleGradientBorder(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: FluentTheme.of(context).gradientBorderColors,
                    ),
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggle();
                unawaited(HapticFeedback.lightImpact());
              },
            ),
          ),
          if (kDebugMode)
            Positioned(
              left: 0,
              top: 32,
              child: Text(ref.read(dioClientProvider).options.baseUrl),
            ),
        ],
      ),
    );
  }
}
