import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/helpers/formatters.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/core/widgets/height_crossfade.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/widgets/secondary_button.dart';
import 'package:frontend/features/tracker/domain/models/category.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/entry_filter_list.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';
import 'package:toastification/toastification.dart';

class EntrySheet extends HookConsumerWidget {
  const EntrySheet({
    super.key,
    required this.entries,
    required this.week,
    required this.category,
    this.isYearly = false,
  });
  final int? week;
  final bool isYearly;
  final Category category;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;

    final keyboardHeight = context.bottomPadding;
    final stateEntries = useState(entries);

    final selectedEntry = useState<Entry?>(null);
    final lastEditedEntry = useState<Entry?>(null);

    useEffect(() {
      if (selectedEntry.value != null) {
        lastEditedEntry.value = selectedEntry.value;
      }
      return null;
    }, [selectedEntry.value]);

    final isEditing = selectedEntry.value != null;

    final scale = useState(0.0);

    useEffect(() {
      Future.delayed(Durations.short1, () {
        scale.value = 1.0;
      });
      return;
    }, []);
    return Wrap(
      children: [
        AnimatedScale(
          scale: scale.value,
          alignment: Alignment.bottomCenter,
          duration: Durations.medium2,
          curve: Curves.easeInOutBack,
          child: Container(
            decoration: BoxDecoration(
              color: FluentTheme.of(context).cardColor,
              borderRadius: BorderRadius.circular(40.0),
              border: GradientBoxBorder(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: FluentTheme.of(context).gradientBorderColors,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: FluentTheme.of(context).shadowColor.withAlpha(64),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ],
            ),
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(16.0),
            clipBehavior: Clip.none,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          '📌 ${week == 6 ? LocaleKeys.total.tr() : LocaleKeys.week.tr(namedArgs: {'value': '$week'})} >',
                          style: theme.bodySmall?.copyWith(height: 1.5),
                        ),
                        Text(
                          category.name,
                          style: theme.bodyLarge.bold?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: FluentTheme.of(context).menuColor,
                        iconSize: 24,
                      ),
                      onPressed: () {
                        unawaited(HapticFeedback.lightImpact());
                        Navigator.pop(context);
                      },
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                isYearly
                    ? EntryTotalView(
                        key: const ValueKey(1),
                        category: category,
                        stateEntries: stateEntries,
                        week: week,
                        isYearly: isYearly,
                        selectedEntry: selectedEntry,
                      )
                    : HeightCrossFade(
                        showFirst: !isEditing,
                        first: EntryTotalView(
                          key: const ValueKey(1),
                          category: category,
                          stateEntries: stateEntries,
                          week: week,
                          selectedEntry: selectedEntry,
                        ),
                        second: EditEntryView(
                          key: const ValueKey(2),
                          lastEditedEntry: lastEditedEntry,
                          selectedEntry: selectedEntry,
                        ),
                      ),
                SizedBox(height: keyboardHeight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EditEntryView extends HookWidget {
  const EditEntryView({
    super.key,
    required this.lastEditedEntry,
    required this.selectedEntry,
  });
  final ValueNotifier<Entry?> lastEditedEntry;
  final ValueNotifier<Entry?> selectedEntry;

  @override
  Widget build(BuildContext context) {
    final notesController = useTextEditingController();
    final theme = FluentTheme.of(context);
    useEffect(() {
      if (lastEditedEntry.value?.notes.isNotEmpty ?? false) {
        notesController.text = lastEditedEntry.value!.notes;
      }
      return;
    }, [lastEditedEntry.value]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        lastEditedEntry.value == null
            ? const SizedBox.shrink()
            : Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 4,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        const Icon(LucideIcons.dollarSign),
                        Text(
                          lastEditedEntry.value!.amount.formatCurrencySymbol(
                            showDecimals: true,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: theme.dividerColor),
                    Row(
                      spacing: 8,
                      children: [
                        const Icon(LucideIcons.calendar),
                        Text(lastEditedEntry.value!.addedDate.formatDate),
                      ],
                    ),
                  ],
                ),
              ),
        TextField(
          controller: notesController,
          decoration: InputDecoration(
            helperMaxLines: 3,
            hintMaxLines: 3,
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            border: FluentTheme.of(context).inputBorder(focused: false),
            enabledBorder: FluentTheme.of(context).inputBorder(focused: false),
            isDense: true,
            hintText: LocaleKeys.type_notes_here.tr(),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 12.0,
            ),
            focusedBorder: FluentTheme.of(context).inputBorder(),
            prefixIcon: const Icon(LucideIcons.messageCircle),
          ),
        ),
        Column(
          spacing: 4,
          children: [
            FractionallySizedBox(
              widthFactor: 1.0,
              child: Consumer(
                builder: (context, ref, _) {
                  return PrimaryButton(
                    onPressed: () {
                      try {
                        final entry = lastEditedEntry.value;
                        if (entry != null && notesController.text.isNotEmpty) {
                          ref
                              .read(entryRepositoryProvider)
                              .updateEntry(
                                entry.copyWith(notes: notesController.text),
                              );
                          selectedEntry.value = null;
                          unawaited(HapticFeedback.lightImpact());
                        }
                      } catch (e, s) {
                        if (kDebugMode) {
                          print('$e, stackTrace: $s');
                        }
                        toastification.show(
                          title: Text(
                            LocaleKeys.error_updating_entry.tr(
                              namedArgs: {'error': e.toString()},
                            ),
                          ),
                          type: ToastificationType.error,
                        );
                      }
                    },
                    padding: const EdgeInsets.all(12.0),
                    icon: LucideIcons.checkCircle,
                    label: LocaleKeys.save_changes.tr(),
                  );
                },
              ),
            ),
            FractionallySizedBox(
              widthFactor: 1.0,
              child: SecondaryButton(
                onPressed: () {
                  selectedEntry.value = null;
                },
                padding: const EdgeInsets.all(12.0),
                icon: LucideIcons.arrowLeft,
                outline: false,
                label: LocaleKeys.back.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EntryTotalView extends HookConsumerWidget {
  const EntryTotalView({
    super.key,
    required this.stateEntries,
    this.week,
    this.isYearly = false,
    required this.category,
    required this.selectedEntry,
  });
  final ValueNotifier<List<Entry>> stateEntries;
  final int? week;
  final bool isYearly;
  final Category category;
  final ValueNotifier<Entry?> selectedEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentMonth = now.month;

    final currentWeek = now.currentWeek;
    final theme = Theme.of(context).textTheme;
    final total = stateEntries.value.fold(
      0.0,
      (prod, entry) => prod + entry.amount,
    );

    final amountController = useTextEditingController();
    final amountField = useFocusNode();

    Future<void> submitEntry() async {
      //Save entry
      try {
        final amount = amountController.text.parseHungarianDecimal;
        if (amount != null && week != null) {
          final month = ref.read(reportProvider);
          final entryDate =
              month != currentMonth ||
                  week! < currentWeek ||
                  week! > currentWeek
              ? now.copyWith(
                  month: month,
                  day: week!.weekLimits.$2,
                  hour: 12,
                  minute: 0,
                  second: 0,
                )
              : now;
          final entry = Entry(
            id: -1,
            amount: amount,
            addedDate: entryDate.ignoringTimezone,
            category: category.id,
          );
          final result = await ref
              .read(entryRepositoryProvider)
              .addEntry(entry);
          stateEntries.value = [
            ...stateEntries.value,
            entry.copyWith(id: result),
          ];
          amountController.clear();
          amountField.requestFocus();
        }
      } catch (e, _) {
        if (kDebugMode) {
          print('Format error. check text: $e');
        }
      }
    }

    // Showing total entries
    final addDisabled = week == 6;

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 82,
          child: AnimatedCrossFade(
            firstChild: Container(
              width: context.width,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: FluentTheme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                spacing: 12,
                children: [
                  const Icon(LucideIcons.info),
                  Flexible(
                    child: Text(
                      LocaleKeys.no_entries_message.tr(),
                      style: theme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  LocaleKeys.edit_manually.tr(),
                  style: theme.bodySmall.light,
                ),
                FilterChipList(
                  initialList: stateEntries.value,
                  onPressed: (e) {
                    selectedEntry.value = e;
                    unawaited(HapticFeedback.lightImpact());
                  },
                  onDeleted: (e) async {
                    try {
                      final result = await ref
                          .read(entryRepositoryProvider)
                          .removeEntry(e.id);
                      if (result) {
                        stateEntries.value = stateEntries.value
                            .where((entry) => entry != e)
                            .toList();
                        unawaited(HapticFeedback.mediumImpact());
                        amountField.requestFocus();
                      }
                    } catch (e, _) {
                      if (kDebugMode) {
                        print(e.toString());
                      }
                      toastification.show(
                        title: Text(e.toString()),
                        type: ToastificationType.error,
                      );
                    }
                  },
                ),
              ],
            ),
            crossFadeState: stateEntries.value.isEmpty
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: kThemeAnimationDuration,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(LocaleKeys.total.tr(), style: theme.headlineMedium),
            Row(
              spacing: 8,
              children: [
                NumberFlow(
                  value: total,
                  style: theme.headlineMedium,
                  continuous: true,
                  tabularNums: true,
                  prefix: total > 0
                      ? category.isExpense
                            ? '-'
                            : '+'
                      : null,
                  locale: context.locale.languageCode,
                  format: const NumberFlowFormat.currency(
                    maxFraction: 2,
                    sign: SignDisplay.negative,
                    currencyCode: '',
                  ),
                ),
                Text(LocaleKeys.ft.tr(), style: theme.headlineMedium),
              ],
            ),
          ],
        ),
        if (!addDisabled)
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      autofocus: true,
                      focusNode: amountField,
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        border: InputBorder.none,
                        hintStyle: theme.headlineLarge?.copyWith(
                          color: theme.headlineLarge?.color?.withAlpha(128),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        submitEntry();
                      },
                      inputFormatters: [
                        const LeadingZeroInputFormatter(),
                        DecimalInputFormatter(decimalPlaces: 2),
                      ],
                      controller: amountController,
                      textAlign: TextAlign.center,
                      style: theme.headlineLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!addDisabled)
          FractionallySizedBox(
            widthFactor: 1.0,
            child: PrimaryButton(
              onPressed: () => submitEntry(),
              icon: LucideIcons.circlePlus,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              label: category.type == CategoryType.expense
                  ? LocaleKeys.add_expense.tr()
                  : LocaleKeys.add_income_action.tr(),
            ),
          ),
        if (week != null && week! > currentWeek && !addDisabled)
          Center(
            child: Row(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.info),
                Text(LocaleKeys.future_week_notice.tr()),
              ],
            ),
          ),
      ],
    );
  }
}
