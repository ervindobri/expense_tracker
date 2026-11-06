import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/secondary_button.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/presentation/state/shopping_provider.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_error.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Creates a list, or renames [initial] when given. Pops with the saved list.
class ShoppingListNameSheet extends HookConsumerWidget {
  const ShoppingListNameSheet({super.key, this.initial});

  final ShoppingList? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = initial != null;
    final controller = useTextEditingController(text: initial?.name);
    final isSaving = useState(false);
    useListenable(controller);

    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = controller.text.trim();
    final isValid = name.isNotEmpty && name != initial?.name;

    final existing = {
      for (final l in ref.watch(shoppingListsProvider).value ?? const [])
        l.name.toLowerCase(),
    };
    final suggestions = isEditing
        ? const <String>[]
        : [
            LocaleKeys.list_suggestion_groceries.tr(),
            LocaleKeys.list_suggestion_house.tr(),
            LocaleKeys.list_suggestion_gifts.tr(),
            LocaleKeys.list_suggestion_clothes.tr(),
          ].where((s) => !existing.contains(s.toLowerCase())).toList();

    Future<void> save() async {
      if (isSaving.value) {
        return;
      }
      if (!isValid) {
        unawaited(HapticFeedback.heavyImpact());
        return;
      }
      isSaving.value = true;
      final notifier = ref.read(shoppingListsProvider.notifier);
      try {
        final ShoppingList saved;
        if (isEditing) {
          await notifier.renameList(initial!.id, name);
          saved = initial!.copyWith(name: name);
        } else {
          saved = await notifier.addList(name);
        }
        if (context.mounted) {
          Navigator.pop(context, saved);
        }
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      } finally {
        if (context.mounted) {
          isSaving.value = false;
        }
      }
    }

    return SheetContainer(
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: Text(
              isEditing
                  ? LocaleKeys.rename_list.tr()
                  : LocaleKeys.new_list.tr(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                const Icon(LucideIcons.listChecks),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => save(),
                    style: textTheme.titleMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      hintText: LocaleKeys.list_name_hint.tr(),
                      hintStyle: textTheme.titleMedium?.copyWith(
                        color: theme.dividerColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (suggestions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    label: Text(s),
                    backgroundColor: theme.scaffoldBackgroundColor,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: () {
                      unawaited(HapticFeedback.selectionClick());
                      controller.text = s;
                    },
                  ),
              ],
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
                    : LocaleKeys.create_list.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks before deleting [list] with its items; pops with true to delete.
class DeleteShoppingListSheet extends StatelessWidget {
  const DeleteShoppingListSheet({super.key, required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: Text(LocaleKeys.delete_list.tr())),
          Text(
            LocaleKeys.delete_list_confirm.tr(namedArgs: {'name': list.name}),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () => Navigator.pop(context, false),
                  padding: const EdgeInsets.all(12.0),
                  label: LocaleKeys.cancel.tr(),
                ),
              ),
              Expanded(
                child: PrimaryButton(
                  onPressed: () => Navigator.pop(context, true),
                  padding: const EdgeInsets.all(12.0),
                  icon: LucideIcons.trash2,
                  label: LocaleKeys.delete.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
