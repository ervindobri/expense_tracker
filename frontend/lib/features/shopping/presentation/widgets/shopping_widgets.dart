import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/ref.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Expected cost of the [items] not bought yet, in HUF.
double stillToSpend(WidgetRef ref, Iterable<ShoppingItem> items) => items
    .where((i) => !i.isBought)
    .fold(0.0, (sum, i) => sum + ref.hufAmount(i.expectedPrice, i.currency));

/// Back button, title and actions at the top of the shopping pages.
class ShoppingPageHeader extends StatelessWidget {
  const ShoppingPageHeader({
    super.key,
    required this.title,
    this.onTitleTap,
    this.actions = const [],
  });

  final String title;
  final VoidCallback? onTitleTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      spacing: 8,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: FluentTheme.of(context).cardColor,
            foregroundColor: FluentTheme.of(context).textColor,
          ),
          tooltip: LocaleKeys.back.tr(),
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            Navigator.maybePop(context);
          },
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        Expanded(
          child: InkWell(
            onTap: onTitleTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  if (onTitleTap != null)
                    Icon(
                      LucideIcons.pencil,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                ],
              ),
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Round black/white icon button matching the primary button.
class ShoppingActionButton extends StatelessWidget {
  const ShoppingActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return IconButton.filled(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: filled ? theme.chipColor : theme.cardColor,
        foregroundColor: filled ? theme.inverseTextColor : theme.textColor,
      ),
      onPressed: () {
        unawaited(HapticFeedback.selectionClick());
        onPressed();
      },
      icon: Icon(icon),
    );
  }
}

/// "Still to spend" total with a bought/total progress bar.
class ShoppingProgressCard extends ConsumerWidget {
  const ShoppingProgressCard({super.key, required this.items});

  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;
    final left = items.where((i) => !i.isBought).length;
    final total = items.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.still_to_spend.tr(),
            style: textTheme.bodyMedium?.copyWith(color: hint),
          ),
          Text(
            ref.formattedAmount(stillToSpend(ref, items)),
            style: textTheme.headlineMedium.bold,
          ),
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (total - left) / total),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: theme.chipColor,
                  backgroundColor: theme.scaffoldBackgroundColor,
                ),
              ),
            ),
            Text(
              left == 0
                  ? LocaleKeys.all_bought.tr()
                  : LocaleKeys.items_left.tr(
                      namedArgs: {'left': '$left', 'total': '$total'},
                    ),
              style: textTheme.bodySmall?.copyWith(color: hint),
            ),
          ],
        ],
      ),
    );
  }
}

/// Icon + hint + optional action, for empty lists.
class ShoppingEmptyState extends StatelessWidget {
  const ShoppingEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        spacing: 16,
        children: [
          Icon(icon, size: 40, color: hint),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: hint),
          ),
          ?action,
        ],
      ),
    );
  }
}
