import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' show FluentIcons, FluentTheme;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/core/extensions/build_context.dart';
import 'package:frontend/core/extensions/date_time.dart';
import 'package:frontend/core/extensions/string.dart';
import 'package:frontend/core/extensions/text_style.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/features/tracker/domain/models/entry.dart';
import 'package:frontend/features/tracker/domain/repositories/entries_repository.dart';
import 'package:frontend/features/tracker/presentation/state/report_notifier.dart';
import 'package:frontend/features/tracker/presentation/widgets/entry_filter_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';
import 'package:toastification/toastification.dart';

class EntrySheet extends HookConsumerWidget {
  const EntrySheet({
    super.key,
    required this.entries,
    required this.week,
    required this.category,
  });
  final int week;
  final Category category;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeek = DateTime.now().currentWeek;
    final theme = Theme.of(context).textTheme;
    final amountController = useTextEditingController();
    final amountField = useFocusNode();
    final keyboardHeight = context.bottomPadding;
    final stateEntries = useState(entries);

    final total = stateEntries.value.fold(
      0.0,
      (prod, entry) => prod + entry.amount,
    );

    final scale = useState(0.0);

    // Showing total entries
    final addDisabled = week == 6;

    useEffect(() {
      Future.delayed(Durations.short1, () {
        scale.value = 1.0;
      });
      return;
    }, []);

    Future<void> submitEntry() async {
      //Save entry
      try {
        final amount = amountController.text.parseHungarianDecimal;
        if (amount != null) {
          final entryDate = week < currentWeek || week > currentWeek
              ? DateTime.now().copyWith(
                  month: ref.read(reportProvider),
                  day: week.weekLimits.$2,
                )
              : DateTime.now();
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

    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: [
        AnimatedScale(
          scale: scale.value,
          alignment: Alignment.bottomCenter,
          duration: Durations.short4,
          child: Container(
            decoration: BoxDecoration(
              color: FluentTheme.of(context).cardColor,
              borderRadius: BorderRadius.circular(40.0),
              boxShadow: [
                BoxShadow(
                  color: FluentTheme.of(context).shadowColor.withAlpha(64),
                  blurRadius: 64,
                  spreadRadius: -24,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(12.0),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          '📌 ${week == 6 ?'Total' :'Week $week'} >',
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
                        iconSize: 16,
                      ),
                      onPressed: () {
                        unawaited(HapticFeedback.lightImpact());
                        Navigator.pop(context);
                      },
                      icon: const Icon(FluentIcons.chrome_close),
                    ),
                  ],
                ),
                AnimatedCrossFade(
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
                        const Icon(FluentIcons.info),
                        Flexible(
                          child: Text(
                            'There are no entries added to this category yet.\nAdd expenses/incomes to show entries.',
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
                      Text('edit manually', style: theme.bodySmall.light),
                      FilterChipList(
                        initialList: stateEntries.value,
                        onPressed: (e) {
                          toastification.show(
                            context:
                                context, // optional if you use ToastificationWrapper
                            title: Text('Added: ${e.addedDate.formatDate}'),
                            type: ToastificationType.info,
                            alignment: Alignment.topCenter,
                            style: ToastificationStyle.simple,
                            autoCloseDuration: const Duration(seconds: 2),
                          );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.headlineMedium),
                    Row(
                      spacing: 8,
                      children: [
                        NumberFlow(
                          value: total,
                          style: theme.headlineMedium,
                          continuous: true,
                          tabularNums: true,
                          format: const NumberFlowFormat.decimal(
                            maxFraction: 2,
                          ),
                        ),
                        Text('Ft', style: theme.headlineMedium),
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
                                  color: theme.headlineLarge?.color?.withAlpha(
                                    128,
                                  ),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (value) {
                                submitEntry();
                              },
                              inputFormatters: [
                                LeadingZeroInputFormatter(),
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
                      onPressed: submitEntry,
                      icon: FluentIcons.circle_plus,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      label:
                          "Add ${category.type == CategoryType.expense ? 'expense' : 'income'}",
                    ),
                  ),
                if (week > currentWeek && !addDisabled)
                  const Center(
                    child: Row(
                      spacing: 12,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.info),
                        Text('You are editing a future week.'),
                      ],
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

/// Strips leading zeros as the user types (e.g. "0" + "5" → "5"),
/// while still allowing a bare "0" or a decimal like "0.5" to remain.
class LeadingZeroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Allow a lone "0", or "0." while typing a decimal (e.g. "0.5")
    if (text == '0' || text.startsWith('0.')) {
      return newValue;
    }

    // Only reformat if it's a leading zero followed by another digit
    if (text.startsWith('0') && text.length > 1 && text[1] != '.') {
      final stripped = text.replaceFirst(RegExp(r'^0+'), '');
      final newText = stripped.isEmpty ? '0' : stripped;

      final removedCount = text.length - newText.length;
      final newOffset = (newValue.selection.baseOffset - removedCount).clamp(
        0,
        newText.length,
      );

      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }

    return newValue;
  }
}

/// Restricts input to a valid decimal number using ',' as the separator:
/// - only digits and commas allowed
/// - only the first comma is kept; any additional commas are stripped
/// - optionally caps decimal places (default: 2, matching CurrencyFormatter)
class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({this.decimalPlaces = 2});
  final int? decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Strip anything that isn't a digit or comma
    text = text.replaceAll(RegExp(r'[^\d,]'), '');

    // Keep only the first comma; drop any further ones
    final firstComma = text.indexOf(',');
    if (firstComma != -1) {
      final before = text.substring(0, firstComma + 1);
      final after = text.substring(firstComma + 1).replaceAll(',', '');
      text = before + after;

      // Optionally cap decimal digits after the comma
      if (decimalPlaces != null && after.length > decimalPlaces!) {
        text = before + after.substring(0, decimalPlaces!);
      }
    }

    if (text == newValue.text) {
      return newValue;
    }

    final lengthDiff = newValue.text.length - text.length;
    final newOffset = (newValue.selection.baseOffset - lengthDiff).clamp(
      0,
      text.length,
    );

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
