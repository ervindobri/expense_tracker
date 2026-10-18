import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/features/subscriptions/domain/models/subscription.dart';
import 'package:frontend/features/subscriptions/presentation/state/subscriptions_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dropdown row for linking an entry to a subscription. Offers the active
/// subscriptions (plus the current one if it has since been removed) and
/// hides itself when there is nothing to pick.
class SubscriptionPicker extends ConsumerWidget {
  const SubscriptionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(subscriptionsProvider).value ?? const [];
    final options = <Subscription>[
      ...all.where((s) => s.isActive || s.id == value),
    ];
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected = options.where((s) => s.id == value).firstOrNull;
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;

    return Material(
      color: FluentTheme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(24.0),
      child: SizedBox(
        height: 48,
        child: ContextMenuOverlay<int?>(
          title: LocaleKeys.subscription.tr(),
          items: [null, ...options.map((s) => s.id)],
          initialValue: value,
          itemBuilder: (_, id) => Text(
            id == null
                ? LocaleKeys.no_subscription.tr()
                : options.firstWhere((s) => s.id == id).name,
          ),
          onSelected: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            spacing: 12,
            children: [
              Icon(LucideIcons.calendarSync, size: 20, color: hint),
              Text(
                LocaleKeys.subscription.tr(),
                style: textTheme.bodyMedium?.copyWith(color: hint),
              ),
              Expanded(
                child: Text(
                  selected?.name ?? LocaleKeys.no_subscription.tr(),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: selected == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronDown, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
