import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/helpers/arithmetic.dart';
import 'package:frontend/core/helpers/formatters.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/currency_dropdown.dart';
import 'package:frontend/core/widgets/date_picker.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/sheet_container.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:frontend/features/shopping/presentation/state/shopping_provider.dart';
import 'package:frontend/features/shopping/presentation/widgets/paste/pasted_images.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_error.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_images.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_links.dart';
import 'package:frontend/features/shopping/presentation/widgets/shopping_widgets.dart';
import 'package:frontend/features/subscriptions/presentation/widgets/subscription_price.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

/// Adds an item to list [listId], or edits [initial] when given.
/// [initialName] prefills the name of a new item.
class ShoppingItemSheet extends HookConsumerWidget {
  const ShoppingItemSheet({
    super.key,
    required this.listId,
    this.initial,
    this.initialName,
  });

  final int listId;
  final ShoppingItem? initial;
  final String? initialName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = initial != null;
    final nameController = useTextEditingController(
      text: initial?.name ?? initialName,
    );
    final descriptionController = useTextEditingController(
      text: initial?.description,
    );
    final priceController = useTextEditingController(
      text: switch (initial?.expectedPrice) {
        null || 0 => '',
        final a when a == a.truncateToDouble() => a.toInt().toString(),
        final a => a.toStringAsFixed(2),
      },
    );
    final currency = useState(initial?.currency ?? Currency.huf);
    final goal = useState(initial?.buyingGoal);
    final isSaving = useState(false);
    // photos kept from [initial] (or already uploaded), and picked ones that
    // upload on save
    final images = useState(initial?.images ?? const <ShoppingImage>[]);
    final uploads = useState(const <ImageUpload>[]);
    final photoRoom =
        maxItemImages - images.value.length - uploads.value.length;
    // set once the item exists on the server, so saving again after a failed
    // photo upload doesn't add it twice
    final saved = useState<ShoppingItem?>(null);
    useListenable(nameController);
    useListenable(descriptionController);
    useListenable(priceController);
    useArithmeticEvaluation(priceController, enabled: supportsInlineArithmetic);

    final theme = FluentTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = Theme.of(context).hintColor;
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final links = extractLinks(description);
    final price = priceController.text.isEmpty
        ? 0.0
        : priceController.text.parseAmount;
    final isValid = name.isNotEmpty && price != null && price >= 0;
    final convertedPrice = price == null
        ? null
        : convertedHint(ref, price, currency.value);

    Future<void> pickGoal() async {
      unawaited(HapticFeedback.selectionClick());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final current = goal.value;
      final picked = await showAppDatePicker(
        context,
        initialDate: current ?? today.add(const Duration(days: 7)),
        // keep an already passed goal pickable
        firstDate: current != null && current.isBefore(today) ? current : today,
        lastDate: DateTime(now.year + 10),
        helpText: LocaleKeys.buying_goal.tr(),
      );
      if (picked != null) {
        goal.value = DateTime(picked.year, picked.month, picked.day);
      }
    }

    void warn(String title) => ToastificationService.show(
      context: context,
      title: title,
      type: ToastificationType.warning,
    );

    /// Queues [added] for upload, as many as still fit.
    void addUploads(List<ImageUpload> added) {
      if (added.isEmpty || !context.mounted) {
        return;
      }
      final room = maxItemImages - images.value.length - uploads.value.length;
      if (room <= 0) {
        warn(LocaleKeys.photo_limit.tr(namedArgs: {'value': '$maxItemImages'}));
        return;
      }
      uploads.value = [...uploads.value, ...added.take(room)];
    }

    /// Adds the clipboard's image; without one, runs [orElse] or says so.
    Future<void> pasteImage({VoidCallback? orElse}) async {
      final image = await readClipboardImage();
      if (!context.mounted) {
        return;
      }
      if (image != null) {
        unawaited(HapticFeedback.selectionClick());
        addUploads([image]);
      } else if (orElse != null) {
        orElse();
      } else {
        warn(LocaleKeys.no_clipboard_image.tr());
      }
    }

    Future<void> addPhotos(PhotoSource source) async {
      if (source == PhotoSource.clipboard) {
        return pasteImage();
      }
      try {
        addUploads(
          await pickImageUploads(
            source == PhotoSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
            limit: photoRoom,
          ),
        );
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      }
    }

    // web: the browser's paste event carries the image
    useEffect(() {
      final subscription = listenForPastedImages((pasted) {
        if (!isSaving.value) {
          addUploads(pasted);
        }
      });
      return () => unawaited(subscription?.cancel());
    }, const []);

    // elsewhere: catch the paste shortcut while the sheet has focus, add the
    // clipboard's image, or paste text into the focused field as usual
    KeyEventResult onKey(FocusNode _, KeyEvent event) {
      if (kIsWeb ||
          event is! KeyDownEvent ||
          event.logicalKey != LogicalKeyboardKey.keyV ||
          isSaving.value) {
        return KeyEventResult.ignored;
      }
      final keys = HardwareKeyboard.instance;
      final apple =
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS;
      final isPaste = apple
          ? keys.isMetaPressed && !keys.isControlPressed
          : keys.isControlPressed && !keys.isMetaPressed;
      if (!isPaste || keys.isShiftPressed || keys.isAltPressed) {
        return KeyEventResult.ignored;
      }
      final target = FocusManager.instance.primaryFocus?.context;
      unawaited(
        pasteImage(
          orElse: () {
            if (target != null && target.mounted) {
              Actions.maybeInvoke(
                target,
                const PasteTextIntent(SelectionChangedCause.keyboard),
              );
            }
          },
        ),
      );
      return KeyEventResult.handled;
    }

    void viewPhotos(int index) {
      unawaited(
        showShoppingImages(context, [
          for (final image in images.value) shoppingImageProvider(image),
          for (final upload in uploads.value) MemoryImage(upload.bytes),
        ], initialIndex: index),
      );
    }

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
        final base = saved.value ?? initial;
        final item = base != null
            ? await notifier.updateItem(
                base.copyWith(
                  name: name,
                  description: description,
                  expectedPrice: price,
                  currency: currency.value,
                  buyingGoal: () => goal.value,
                ),
              )
            : await notifier.addItem(
                ShoppingItem(
                  id: -1,
                  listId: listId,
                  name: name,
                  description: description,
                  expectedPrice: price,
                  currency: currency.value,
                  buyingGoal: goal.value,
                ),
              );
        saved.value = item;
        // one at a time, keeping track of what got through, so saving again
        // after a failure only retries the rest
        final keptIds = {for (final i in images.value) i.id};
        for (final image in item.images) {
          if (!keptIds.contains(image.id)) {
            await notifier.removeImage(item, image);
          }
        }
        for (final upload in [...uploads.value]) {
          final image = await notifier.addImage(item, upload);
          if (context.mounted) {
            images.value = [...images.value, image];
            uploads.value = uploads.value.where((u) => u != upload).toList();
          }
        }
        if (context.mounted) {
          Navigator.pop(context);
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

    Future<void> delete() async {
      final notifier = ref.read(shoppingListsProvider.notifier);
      Navigator.pop(context);
      try {
        await notifier.removeItem(initial!);
      } catch (e) {
        if (context.mounted) {
          showShoppingError(context, e);
        }
      }
    }

    final inputDecoration = InputDecoration(
      isDense: true,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      hintStyle: textTheme.titleMedium?.copyWith(color: theme.dividerColor),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: onKey,
      child: SheetContainer(
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: Text(
                isEditing
                    ? LocaleKeys.edit_item.tr()
                    : LocaleKeys.new_item.tr(),
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
                      const Icon(LucideIcons.shoppingBag),
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          autofocus: !isEditing && (initialName ?? '').isEmpty,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.sentences,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          style: textTheme.titleMedium,
                          decoration: inputDecoration.copyWith(
                            hintText: LocaleKeys.item_name_hint.tr(),
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: theme.dividerColor),
                  Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(LucideIcons.notebookText),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: descriptionController,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: 2000,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: textTheme.bodyLarge,
                              decoration: inputDecoration.copyWith(
                                hintText: LocaleKeys.item_description_hint.tr(),
                                hintStyle: textTheme.bodyLarge?.copyWith(
                                  color: theme.dividerColor,
                                ),
                                counterText: '',
                              ),
                            ),
                            if (images.value.isNotEmpty ||
                                uploads.value.isNotEmpty)
                              Padding(
                                // room for the remove buttons' overhang
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  right: 6,
                                  bottom: 4,
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (final (i, image)
                                        in images.value.indexed)
                                      ShoppingImageThumb(
                                        key: ValueKey('image-${image.id}'),
                                        image: shoppingImageProvider(image),
                                        onTap: () => viewPhotos(i),
                                        onRemove: isSaving.value
                                            ? null
                                            : () => images.value = images.value
                                                  .where((x) => x != image)
                                                  .toList(),
                                      ),
                                    for (final (i, upload)
                                        in uploads.value.indexed)
                                      ShoppingImageThumb(
                                        key: ObjectKey(upload),
                                        image: MemoryImage(upload.bytes),
                                        busy: isSaving.value,
                                        onTap: () =>
                                            viewPhotos(images.value.length + i),
                                        onRemove: () => uploads.value = uploads
                                            .value
                                            .where((x) => x != upload)
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      AddPhotoButton(
                        room: photoRoom,
                        enabled: !isSaving.value,
                        onPick: addPhotos,
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
                          controller: priceController,
                          autofocus:
                              !isEditing && (initialName ?? '').isNotEmpty,
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
                            color: price == null
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                          decoration: inputDecoration.copyWith(
                            hintText: LocaleKeys.expected_price.tr(),
                          ),
                        ),
                      ),
                      CurrencyDropdown(
                        value: currency.value,
                        onChanged: (c) => currency.value = c,
                      ),
                    ],
                  ),
                  if (convertedPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          convertedPrice,
                          style: textTheme.bodySmall?.copyWith(color: hint),
                        ),
                      ),
                    ),
                  Divider(color: theme.dividerColor),
                  InkWell(
                    onTap: pickGoal,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        spacing: 12,
                        children: [
                          const Icon(LucideIcons.calendarCheck),
                          Expanded(
                            child: Text(
                              LocaleKeys.buying_goal.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                color: hint,
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: Durations.short3,
                            child: Text(
                              goal.value?.formatDateOnly ??
                                  LocaleKeys.no_goal.tr(),
                              key: ValueKey(goal.value),
                              style: textTheme.titleMedium?.copyWith(
                                color: goal.value == null ? hint : null,
                              ),
                            ),
                          ),
                          if (goal.value != null)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                unawaited(HapticFeedback.selectionClick());
                                goal.value = null;
                              },
                              child: Icon(LucideIcons.x, size: 16, color: hint),
                            )
                          else
                            Icon(
                              LucideIcons.chevronDown,
                              size: 14,
                              color: hint,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (links.isNotEmpty) ShoppingLinkChips(links: links),
            Row(
              spacing: 12,
              children: [
                if (isEditing)
                  ShoppingActionButton(
                    icon: LucideIcons.trash2,
                    tooltip: LocaleKeys.delete.tr(),
                    filled: false,
                    onPressed: delete,
                  ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: isValid ? 1.0 : 0.5,
                    duration: kThemeAnimationDuration,
                    child: PrimaryButton(
                      onPressed: save,
                      padding: const EdgeInsets.all(12.0),
                      icon: isEditing
                          ? LucideIcons.checkCircle
                          : LucideIcons.plus,
                      label: isEditing
                          ? LocaleKeys.save_changes.tr()
                          : LocaleKeys.add_item.tr(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
