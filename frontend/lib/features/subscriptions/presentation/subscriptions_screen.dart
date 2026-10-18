import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/pill_tabbar.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/presentation/state/subscriptions_provider.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_form_sheet.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_summary_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SubscriptionsScreen extends HookConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final summary = ref.watch(subscriptionSummaryProvider);
    final renewingSoon = ref.watch(renewingSoonProvider);
    final showActive = useState(true);
    final visible = showActive.value
        ? ref.watch(activeSubscriptionsProvider)
        : ref.watch(inactiveSubscriptionsProvider);
    final textTheme = Theme.of(context).textTheme;

    void create() {
      unawaited(HapticFeedback.selectionClick());
      unawaited(
        showAdaptiveSheet<Subscription>(
          context: context,
          builder: (_) => const SubscriptionFormSheet(),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator.adaptive(
        onRefresh: () => ref.refresh(subscriptionsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.subscriptions.tr(),
                      style: textTheme.headlineSmall,
                    ),
                    _AddButton(onPressed: create),
                  ],
                ),
              ),
            ),
            if (subscriptions.hasError && !subscriptions.hasValue)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  detail: subscriptions.error.toString(),
                  onRetry: () => ref.invalidate(subscriptionsProvider),
                ),
              )
            else if (!subscriptions.hasValue)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: SubscriptionSummaryCard(summary: summary),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Text(
                    LocaleKeys.renewing_soon.tr(),
                    style: textTheme.bodyLarge.bold,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: renewingSoon.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: NothingRenewingSoon(),
                      )
                    : SizedBox(
                        height: RenewingSoonCard.height,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: renewingSoon.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, i) =>
                              RenewingSoonCard(subscription: renewingSoon[i]),
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              PinnedHeaderSliver(
                child: Container(
                  color: FluentTheme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Center(
                    child: ExpenseIncomeTabBar<bool>(
                      items: const [true, false],
                      initialTab: showActive.value,
                      backgroundColor: FluentTheme.of(context).cardColor,
                      itemToString: (active) => active
                          ? LocaleKeys.active.tr()
                          : LocaleKeys.inactive.tr(),
                      onChanged: (active) => showActive.value = active,
                    ),
                  ),
                ),
              ),
              if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(
                    active: showActive.value,
                    onCreate: create,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => SubscriptionCard(
                      key: ValueKey(visible[i].id),
                      subscription: visible[i],
                    ),
                  ),
                ),
            ],
            // room for the floating tab bar
            const SliverToBoxAdapter(
              child: SizedBox(height: kToolbarHeight + 48.0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round black/white "+" matching the primary button.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Tooltip(
      message: LocaleKeys.new_subscription.tr(),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: theme.chipColor,
          foregroundColor: theme.inverseTextColor,
        ),
        onPressed: onPressed,
        icon: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.active, required this.onCreate});

  final bool active;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        spacing: 16,
        children: [
          Icon(
            active ? LucideIcons.calendarSync : LucideIcons.archive,
            size: 40,
            color: hint,
          ),
          Text(
            active
                ? LocaleKeys.no_active_subscriptions.tr()
                : LocaleKeys.no_inactive_subscriptions.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: hint),
          ),
          if (active)
            PrimaryButton(
              onPressed: onCreate,
              icon: LucideIcons.plus,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              label: LocaleKeys.new_subscription.tr(),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.detail, required this.onRetry});

  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 32,
            color: FluentTheme.of(context).accentColor,
          ),
          Text(
            LocaleKeys.something_went_wrong.tr(),
            style: textTheme.titleMedium,
          ),
          Text(
            detail,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          PrimaryButton(onPressed: onRetry, label: LocaleKeys.retry.tr()),
        ],
      ),
    );
  }
}
