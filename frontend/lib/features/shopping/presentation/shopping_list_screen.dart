import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/presentation/state/shopping_provider.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_error.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_sheet.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_item_tile.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_list_name_sheet.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Checklist of one shopping list: what's still to buy, then what's bought.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key, required this.listId});

  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingListProvider(listId));
    final background = FluentTheme.of(context).scaffoldBackgroundColor;
    if (list == null) {
      // just deleted, or gone after a refresh
      return Scaffold(backgroundColor: background);
    }
    final textTheme = Theme.of(context).textTheme;
    final toBuy = list.toBuy;
    final bought = list.bought;

    Future<void> rename() async {
      await showAdaptiveSheet<ShoppingList>(
        context: context,
        builder: (_) => ShoppingListNameSheet(initial: list),
      );
    }

    Future<void> delete() async {
      final confirmed = await showAdaptiveSheet<bool>(
        context: context,
        builder: (_) => DeleteShoppingListSheet(list: list),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
      try {
        await ref.read(shoppingListsProvider.notifier).removeList(list.id);
        if (!context.mounted) {
          return;
        }
        unawaited(
          ToastificationService.showSuccess(
            context: context,
            title: LocaleKeys.list_deleted.tr(),
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      }
    }

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(text, style: textTheme.bodyLarge.bold),
    );

    // Each section is dragged on its own; the whole list's order is saved,
    // so an item ticked back off returns to where it was.
    Future<void> reorder(bool inToBuy, int oldIndex, int newIndex) async {
      final section = [...(inToBuy ? toBuy : bought)];
      if (newIndex == oldIndex) {
        return;
      }
      section.insert(newIndex, section.removeAt(oldIndex));
      final ordered = inToBuy
          ? [...section, ...bought]
          : [...toBuy, ...section];
      try {
        await ref.read(shoppingListsProvider.notifier).reorderItems(list.id, [
          for (final i in ordered) i.id,
        ]);
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      }
    }

    Widget items(List<ShoppingItem> items, {required bool inToBuy}) =>
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverReorderableList(
            itemCount: items.length,
            onReorderStart: (_) => unawaited(HapticFeedback.selectionClick()),
            onReorderItem: (from, to) => reorder(inToBuy, from, to),
            proxyDecorator: (child, _, animation) => AnimatedBuilder(
              animation: animation,
              builder: (_, child) => Transform.scale(
                scale: 1 + 0.02 * Curves.easeOut.transform(animation.value),
                child: child,
              ),
              child: Material(type: MaterialType.transparency, child: child),
            ),
            itemBuilder: (_, i) => ReorderableDelayedDragStartListener(
              key: ValueKey(items[i].id),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShoppingItemTile(item: items[i], dragIndex: i),
              ),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: background,
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
                        title: list.name,
                        onTitleTap: rename,
                        actions: [
                          ShoppingActionButton(
                            icon: LucideIcons.trash2,
                            tooltip: LocaleKeys.delete_list.tr(),
                            filled: false,
                            onPressed: delete,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: ShoppingProgressCard(items: list.items),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _QuickAddField(listId: list.id),
                    ),
                  ),
                  if (toBuy.isEmpty)
                    SliverToBoxAdapter(
                      child: ShoppingEmptyState(
                        icon: bought.isEmpty
                            ? LucideIcons.listPlus
                            : LucideIcons.partyPopper,
                        message: bought.isEmpty
                            ? LocaleKeys.no_items_to_buy.tr()
                            : LocaleKeys.all_bought.tr(),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: sectionTitle(
                        '${LocaleKeys.to_buy.tr()} (${toBuy.length})',
                      ),
                    ),
                    items(toBuy, inToBuy: true),
                  ],
                  if (bought.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: sectionTitle(
                        '${LocaleKeys.bought.tr()} (${bought.length})',
                      ),
                    ),
                    items(bought, inToBuy: false),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Type a name and press enter to add it right away; the button opens the
/// full form for a price and a buying goal.
class _QuickAddField extends HookConsumerWidget {
  const _QuickAddField({required this.listId});

  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;

    Future<void> add() async {
      final name = controller.text.trim();
      if (name.isEmpty) {
        return;
      }
      controller.clear();
      // keep typing the next one
      focusNode.requestFocus();
      unawaited(HapticFeedback.selectionClick());
      try {
        await ref
            .read(shoppingListsProvider.notifier)
            .addItem(ShoppingItem(id: -1, listId: listId, name: name));
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      }
    }

    void openForm() {
      final name = controller.text.trim();
      controller.clear();
      unawaited(
        showAdaptiveSheet<void>(
          context: context,
          builder: (_) => ShoppingItemSheet(listId: listId, initialName: name),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        spacing: 8,
        children: [
          Icon(LucideIcons.plus, color: Theme.of(context).hintColor),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => add(),
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                hintText: LocaleKeys.item_name_hint.tr(),
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: theme.dividerColor,
                ),
              ),
            ),
          ),
          ShoppingActionButton(
            icon: LucideIcons.slidersHorizontal,
            tooltip: LocaleKeys.add_item.tr(),
            onPressed: openForm,
          ),
        ],
      ),
    );
  }
}
