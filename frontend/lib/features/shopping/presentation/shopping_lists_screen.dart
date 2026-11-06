import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/presentation/shopping_list_screen.dart';
import 'package:frontend/features/shopping/presentation/state/shopping_provider.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_tile.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_list_name_sheet.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opens the shopping lists page on top of the current screen.
Future<void> openShoppingLists(BuildContext context) {
  unawaited(HapticFeedback.selectionClick());
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ShoppingListsScreen()));
}

Future<void> _openList(BuildContext context, int id) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ShoppingListScreen(listId: id)),
  );
}

/// Every shopping list, each opening its own checklist.
class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    final all = lists.value ?? const <ShoppingList>[];

    Future<void> create() async {
      final created = await showAdaptiveSheet<ShoppingList>(
        context: context,
        builder: (_) => const ShoppingListNameSheet(),
      );
      if (created != null && context.mounted) {
        unawaited(_openList(context, created.id));
      }
    }

    return Scaffold(
      backgroundColor: FluentTheme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: RefreshIndicator.adaptive(
              onRefresh: () => ref.refresh(shoppingListsProvider.future),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: ShoppingPageHeader(
                        title: LocaleKeys.shopping_lists.tr(),
                        actions: [
                          ShoppingActionButton(
                            icon: LucideIcons.plus,
                            tooltip: LocaleKeys.new_list.tr(),
                            onPressed: create,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (lists.hasError && !lists.hasValue)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShoppingEmptyState(
                        icon: LucideIcons.circleAlert,
                        message:
                            '${LocaleKeys.something_went_wrong.tr()}\n'
                            '${lists.error}',
                        action: PrimaryButton(
                          onPressed: () =>
                              ref.invalidate(shoppingListsProvider),
                          label: LocaleKeys.retry.tr(),
                        ),
                      ),
                    )
                  else if (!lists.hasValue)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    )
                  else if (all.isEmpty)
                    SliverToBoxAdapter(
                      child: ShoppingEmptyState(
                        icon: LucideIcons.shoppingCart,
                        message: LocaleKeys.no_shopping_lists.tr(),
                        action: PrimaryButton(
                          onPressed: create,
                          icon: LucideIcons.plus,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          label: LocaleKeys.new_list.tr(),
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: ShoppingProgressCard(
                          items: [for (final l in all) ...l.items],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: all.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => ShoppingListCard(
                          key: ValueKey(all[i].id),
                          list: all[i],
                          onTap: () => _openList(context, all[i].id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row in the lists overview: name, what's left and its expected cost.
class ShoppingListCard extends ConsumerWidget {
  const ShoppingListCard({super.key, required this.list, required this.onTap});

  final ShoppingList list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;
    final toBuy = list.toBuy;
    final total = list.items.length;
    final next = toBuy.where((i) => i.buyingGoal != null).firstOrNull;
    final overdue = next?.isOverdue() ?? false;
    final remaining = stillToSpend(ref, toBuy);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Material(
        color: theme.cardColor,
        child: InkWell(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              spacing: 12,
              children: [
                _ProgressRing(
                  progress: total == 0 ? 0 : (total - toBuy.length) / total,
                ),
                Expanded(
                  child: Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: total > 0 && toBuy.isEmpty
                                  ? LocaleKeys.all_bought.tr()
                                  : LocaleKeys.items_left.tr(
                                      namedArgs: {
                                        'left': '${toBuy.length}',
                                        'total': '$total',
                                      },
                                    ),
                            ),
                            if (next != null) ...[
                              const TextSpan(text: ' · '),
                              TextSpan(
                                text: goalLabel(next),
                                style: overdue
                                    ? TextStyle(color: theme.failureColor)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: hint),
                      ),
                    ],
                  ),
                ),
                if (remaining > 0)
                  Text(
                    ref.formattedAmount(remaining),
                    style: textTheme.bodyLarge,
                  ),
                Icon(LucideIcons.chevronRight, size: 18, color: hint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox.square(
      dimension: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            color: theme.chipColor,
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          Icon(
            progress >= 1 ? LucideIcons.check : LucideIcons.shoppingBag,
            size: 18,
          ),
        ],
      ),
    );
  }
}
