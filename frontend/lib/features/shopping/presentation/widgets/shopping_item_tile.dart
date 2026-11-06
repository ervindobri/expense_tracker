import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/presentation/state/shopping_provider.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_error.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_sheet.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_links.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_price.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Tomorrow", "In 5 days", "3 days late"; the date itself when it is more
/// than a month away.
String goalLabel(ShoppingItem item, {DateTime? now}) {
  final days = item.daysUntilGoal(now: now)!;
  return switch (days) {
    0 => LocaleKeys.today.tr(),
    1 => LocaleKeys.due_tomorrow.tr(),
    < 0 => LocaleKeys.overdue_days.tr(namedArgs: {'value': '${-days}'}),
    <= 30 => LocaleKeys.due_in_days.tr(namedArgs: {'value': '$days'}),
    _ => item.buyingGoal!.formatDateOnly,
  };
}

/// Checklist row: tap the circle to tick it off, the row to edit, swipe to
/// delete.
class ShoppingItemTile extends ConsumerWidget {
  const ShoppingItemTile({super.key, required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;
    final notifier = ref.read(shoppingListsProvider.notifier);
    final overdue = item.isOverdue();
    final preview = descriptionPreview(item.description);
    final links = item.links;

    Future<void> toggle() async {
      unawaited(
        item.isBought
            ? HapticFeedback.selectionClick()
            : HapticFeedback.mediumImpact(),
      );
      try {
        await notifier.toggleBought(item);
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      }
    }

    return Dismissible(
      key: ValueKey('shopping-item-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.failureColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) async {
        unawaited(HapticFeedback.mediumImpact());
        try {
          await notifier.removeItem(item);
        } catch (e) {
          if (context.mounted) {
            showShoppingError(context, e);
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Material(
          color: theme.cardColor,
          child: InkWell(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              unawaited(
                showAdaptiveSheet<void>(
                  context: context,
                  builder: (_) =>
                      ShoppingItemSheet(listId: item.listId, initial: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                spacing: 4,
                children: [
                  IconButton(
                    onPressed: toggle,
                    tooltip: item.isBought
                        ? LocaleKeys.to_buy.tr()
                        : LocaleKeys.bought.tr(),
                    icon: _CheckCircle(checked: item.isBought),
                  ),
                  Expanded(
                    child: Column(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: kThemeAnimationDuration,
                          style: textTheme.bodyLarge!.copyWith(
                            color: item.isBought ? hint : null,
                            decoration: item.isBought
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: hint,
                          ),
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (preview.isNotEmpty)
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(color: hint),
                          ),
                        if (item.buyingGoal != null && !item.isBought)
                          Row(
                            spacing: 4,
                            children: [
                              Icon(
                                LucideIcons.calendarCheck,
                                size: 12,
                                color: overdue ? theme.failureColor : hint,
                              ),
                              Text(
                                goalLabel(item),
                                style: textTheme.bodySmall?.copyWith(
                                  color: overdue ? theme.failureColor : hint,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (item.expectedPrice > 0)
                    Text(
                      formatInCurrency(item.expectedPrice, item.currency),
                      maxLines: 1,
                      style: textTheme.bodyMedium?.copyWith(
                        color: item.isBought ? hint : null,
                      ),
                    ),
                  if (links.isNotEmpty)
                    IconButton(
                      tooltip: LocaleKeys.open_link.tr(),
                      visualDensity: VisualDensity.compact,
                      color: hint,
                      onPressed: () => openLink(context, links.first),
                      icon: const Icon(LucideIcons.externalLink, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return AnimatedContainer(
      duration: kThemeAnimationDuration,
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? theme.chipColor : Colors.transparent,
        border: Border.all(
          color: checked ? theme.chipColor : theme.dividerColor,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: checked ? 1 : 0,
        duration: kThemeAnimationDuration,
        curve: Curves.easeOutBack,
        child: Icon(LucideIcons.check, size: 16, color: theme.inverseTextColor),
      ),
    );
  }
}
