import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/helpers/toastification_service.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in the browser, or says so when it can't.
Future<void> openLink(BuildContext context, Uri uri) async {
  unawaited(HapticFeedback.selectionClick());
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ToastificationService.showError(
      context: context,
      title: LocaleKeys.could_not_open_link.tr(),
      description: uri.toString(),
    );
  }
}

/// [text] on one line with its links shortened to their site, e.g.
/// "Grey, 3 seats · ikea.com".
String descriptionPreview(String text) => text
    .replaceAllMapped(
      RegExp(r'(?:https?://|www\.)[^\s<>"]+', caseSensitive: false),
      (m) => extractLinks(m.group(0)!).map(linkLabel).firstOrNull ?? m[0]!,
    )
    .split(RegExp(r'\s*\n\s*'))
    .where((line) => line.trim().isNotEmpty)
    .join(' · ');

/// A tappable chip per link, labelled with the site.
class ShoppingLinkChips extends StatelessWidget {
  const ShoppingLinkChips({super.key, required this.links});

  final List<Uri> links;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final uri in links)
          Tooltip(
            message: uri.toString(),
            child: ActionChip(
              avatar: const Icon(LucideIcons.externalLink, size: 14),
              label: Text(linkLabel(uri)),
              backgroundColor: theme.scaffoldBackgroundColor,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: () => openLink(context, uri),
            ),
          ),
      ],
    );
  }
}
