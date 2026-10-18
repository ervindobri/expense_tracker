import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/helpers/arithmetic.dart';
import 'package:frontend/core/helpers/formatters.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:frontend/features/subscriptions/presentation/state/subscriptions_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Creates a subscription, or edits [initial] when given. Pops with the
/// saved subscription.
class SubscriptionFormSheet extends HookConsumerWidget {
  const SubscriptionFormSheet({super.key, this.initial});

  final Subscription? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = initial != null;
    final nameController = useTextEditingController(text: initial?.name);
    final amountController = useTextEditingController(
      text: switch (initial?.amount) {
        null || 0 => '',
        final a when a == a.truncateToDouble() => a.toInt().toString(),
        final a => a.toStringAsFixed(2),
      },
    );
    final period = useState(initial?.period ?? SubscriptionPeriod.monthly);
    final isSaving = useState(false);
    useListenable(nameController);
    useListenable(amountController);
    useArithmeticEvaluation(
      amountController,
      enabled: supportsInlineArithmetic,
    );

    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = nameController.text.trim();
    final amount = amountController.text.isEmpty
        ? 0.0
        : amountController.text.parseAmount;
    final isValid = name.isNotEmpty && amount != null && amount >= 0;

    // Renewals count from the creation date, which is "now" for a new one.
    final preview = Subscription(
      id: initial?.id ?? 0,
      name: name,
      period: period.value,
      createdDate: initial?.createdDate ?? DateTime.now(),
    );

    Future<void> save() async {
      if (isSaving.value) {
        return;
      }
      if (!isValid) {
        unawaited(HapticFeedback.heavyImpact());
        return;
      }
      isSaving.value = true;
      final repository = ref.read(subscriptionRepositoryProvider);
      try {
        final saved = isEditing
            ? await repository.updateSubscription(
                initial!.copyWith(
                  name: name,
                  amount: amount,
                  period: period.value,
                ),
              )
            : await repository.addSubscription(
                Subscription(
                  id: -1,
                  name: name,
                  amount: amount,
                  period: period.value,
                  createdDate: DateTime.now(),
                ),
              );
        ref.invalidate(subscriptionsProvider);
        if (!context.mounted) {
          return;
        }
        unawaited(
          ToastificationService.showSuccess(
            context: context,
            title: LocaleKeys.subscription_saved.tr(),
          ),
        );
        Navigator.pop(context, saved);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        if (context.mounted) {
          ToastificationService.showError(
            context: context,
            title: LocaleKeys.error_saving_subscription.tr(
              namedArgs: {'error': e.toString()},
            ),
            description: e.toString(),
          );
        }
      } finally {
        if (context.mounted) {
          isSaving.value = false;
        }
      }
    }

    final inputDecoration = InputDecoration(
      isDense: true,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      hintStyle: textTheme.titleMedium?.copyWith(color: theme.dividerColor),
    );

    return SheetContainer(
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: Text(
              isEditing
                  ? LocaleKeys.edit_subscription.tr()
                  : LocaleKeys.new_subscription.tr(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 4,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    const Icon(LucideIcons.tag),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        autofocus: !isEditing,
                        maxLength: 100,
                        textCapitalization: TextCapitalization.sentences,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.next,
                        style: textTheme.titleMedium,
                        decoration: inputDecoration.copyWith(
                          hintText: LocaleKeys.subscription_name_hint.tr(),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: theme.dividerColor),
                Row(
                  spacing: 12,
                  children: [
                    const Icon(LucideIcons.banknote),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: supportsInlineArithmetic
                            ? [ArithmeticInputFormatter(decimalPlaces: 2)]
                            : [
                                const LeadingZeroInputFormatter(),
                                DecimalInputFormatter(decimalPlaces: 2),
                              ],
                        onSubmitted: (_) => save(),
                        style: textTheme.titleMedium?.copyWith(
                          color: amount == null
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        decoration: inputDecoration.copyWith(
                          hintText: LocaleKeys.price_per_period.tr(),
                        ),
                      ),
                    ),
                    // Prices are stored in HUF like entries.
                    Text(Currency.huf.symbol, style: textTheme.titleMedium),
                  ],
                ),
              ],
            ),
          ),
          Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocaleKeys.period.tr(), style: textTheme.bodyLarge.bold),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in SubscriptionPeriod.values)
                    _PeriodPill(
                      label: p.label,
                      selected: p == period.value,
                      onTap: () {
                        period.value = p;
                        unawaited(HapticFeedback.selectionClick());
                      },
                    ),
                ],
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Icon(
                LucideIcons.calendarClock,
                size: 18,
                color: Theme.of(context).hintColor,
              ),
              Expanded(
                child: Text(
                  LocaleKeys.next_renewal.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: Durations.short3,
                child: Text(
                  preview.nextRenewal().formatDateOnly,
                  key: ValueKey(period.value),
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (amount != null &&
              amount > 0 &&
              period.value != SubscriptionPeriod.monthly)
            Text(
              LocaleKeys.per_month_estimate.tr(
                namedArgs: {
                  'value': ref.formattedAmount(
                    (amount * period.value.perMonth).roundToDouble(),
                  ),
                },
              ),
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          AnimatedOpacity(
            opacity: isValid ? 1.0 : 0.5,
            duration: kThemeAnimationDuration,
            child: FractionallySizedBox(
              widthFactor: 1.0,
              child: PrimaryButton(
                onPressed: save,
                padding: const EdgeInsets.all(12.0),
                icon: isEditing ? LucideIcons.checkCircle : LucideIcons.plus,
                label: isEditing
                    ? LocaleKeys.save_changes.tr()
                    : LocaleKeys.create_subscription.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: kThemeAnimationDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? theme.chipColor : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? theme.inverseTextColor : null,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
