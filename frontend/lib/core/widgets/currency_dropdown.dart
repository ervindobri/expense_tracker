import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/context_menu_overlay.dart';
import 'package:frontend/features/settings/domain/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Currency of the price, picked from the supported ones.
class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({required this.value, required this.onChanged});

  final Currency value;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ContextMenuOverlay<Currency>(
      items: Currency.values,
      initialValue: value,
      width: 200,
      itemBuilder: (_, c) => Text(c.display),
      onSelected: (c) {
        unawaited(HapticFeedback.selectionClick());
        onChanged(c);
      },
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(value.symbol, style: textTheme.titleMedium),
          Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }
}
