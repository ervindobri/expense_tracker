import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/secondary_button.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:frontend/features/subscriptions/presentation/state/subscriptions_provider.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/renewal_badge.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_avatar.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_form_sheet.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> openSubscriptionDetails(BuildContext context, int id) {
  return showAdaptiveSheet<void>(
    context: context,
    builder: (_) => SubscriptionDetailSheet(subscriptionId: id),
  );
}

/// Everything stored about one subscription plus its linked transactions.
/// Reads the subscription from [subscriptionsProvider] by id so edits made
/// from here show up immediately.
class SubscriptionDetailSheet extends HookConsumerWidget {
  const SubscriptionDetailSheet({super.key, required this.subscriptionId});

  final int subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref
        .watch(subscriptionsProvider)
        .value
        ?.where((s) => s.id == subscriptionId)
        .firstOrNull;
    final isBusy = useState(false);

    if (subscription == null) {
      return const SheetContainer(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;

    Future<void> setActive({required bool active}) async {
      if (isBusy.value) {
        return;
      }
      isBusy.value = true;
      final repository = ref.read(subscriptionRepositoryProvider);
      try {
        if (active) {
          await repository.updateSubscription(
            subscription.copyWith(isActive: true),
          );
        } else {
          await repository.removeSubscription(subscription.id);
        }
        ref.invalidate(subscriptionsProvider);
        if (!context.mounted) {
          return;
        }
        unawaited(
          ToastificationService.showSuccess(
            context: context,
            title: active
                ? LocaleKeys.subscription_reactivated.tr()
                : LocaleKeys.subscription_removed.tr(),
          ),
        );
        if (!active) {
          Navigator.pop(context);
        }
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
          isBusy.value = false;
        }
      }
    }

    return SheetContainer(
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            leading: SubscriptionAvatar(subscription: subscription),
            title: Text(subscription.name),
          ),
          // Price per period and when it renews
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: ref.formattedAmount(subscription.amount),
                        style: textTheme.headlineMedium,
                      ),
                      TextSpan(
                        text: '  / ${subscription.period.label.toLowerCase()}',
                        style: textTheme.bodyMedium?.copyWith(color: hint),
                      ),
                    ],
                  ),
                ),
              ),
              RenewalBadge(subscription: subscription),
            ],
          ),
          _InfoPanel(subscription: subscription),
          _RelatedTransactions(entries: subscription.entries),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: PrimaryButton(
                  onPressed: () => showAdaptiveSheet<Subscription>(
                    context: context,
                    builder: (_) =>
                        SubscriptionFormSheet(initial: subscription),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  icon: LucideIcons.pencil,
                  label: LocaleKeys.edit.tr(),
                ),
              ),
              Expanded(
                child: SecondaryButton(
                  onPressed: () => setActive(active: !subscription.isActive),
                  padding: const EdgeInsets.all(12.0),
                  icon: subscription.isActive
                      ? LucideIcons.archive
                      : LucideIcons.rotateCcw,
                  label: subscription.isActive
                      ? LocaleKeys.remove_subscription.tr()
                      : LocaleKeys.reactivate_subscription.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends ConsumerWidget {
  const _InfoPanel({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final rows = <(IconData, String, String)>[
      if (subscription.isActive)
        (
          LucideIcons.calendarClock,
          LocaleKeys.next_renewal.tr(),
          subscription.nextRenewal().formatDateOnly,
        ),
      (LucideIcons.repeat, LocaleKeys.period.tr(), subscription.period.label),
      (
        LucideIcons.calendarPlus,
        LocaleKeys.created_on.tr(),
        subscription.createdDate.formatDateOnly,
      ),
      if (subscription.lastPayment != null)
        (
          LucideIcons.receipt,
          LocaleKeys.last_payment.tr(),
          subscription.lastPayment!.formatDateOnly,
        ),
      (
        LucideIcons.wallet,
        LocaleKeys.total_spent.tr(),
        ref.formattedAmount(subscription.totalSpent),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          for (final (i, (icon, label, value)) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                spacing: 12,
                children: [
                  Icon(icon, size: 18, color: Theme.of(context).hintColor),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelatedTransactions extends ConsumerWidget {
  const _RelatedTransactions({required this.entries});

  final List<Entry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleKeys.related_transactions.tr(),
              style: textTheme.bodyLarge.bold,
            ),
            if (entries.isNotEmpty)
              Text(
                LocaleKeys.payments_count.tr(
                  namedArgs: {'value': '${entries.length}'},
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
          ],
        ),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 12,
              children: [
                const Icon(LucideIcons.info),
                Flexible(
                  child: Text(
                    LocaleKeys.no_related_transactions.tr(),
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Column(
              children: [
                for (final (i, entry) in entries.indexed) ...[
                  if (i > 0) Divider(height: 1, color: theme.dividerColor),
                  _TransactionTile(entry: entry),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        spacing: 12,
        children: [
          Icon(LucideIcons.receipt, size: 18, color: hint),
          Expanded(
            child: Column(
              spacing: 2,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.addedDate.formatDateOnly,
                  style: textTheme.bodyMedium,
                ),
                if (entry.notes.isNotEmpty)
                  Text(
                    entry.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: hint),
                  ),
              ],
            ),
          ),
          Text(
            '-${ref.formattedAmount(entry.amount, showDecimals: true)}',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
