import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/app/theme.dart';
import 'package:frontend/core/localization/locale_keys.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Phones can take a photo; everywhere else picks files.
bool get canTakePhoto =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Lets the user pick at most [limit] photos from [source], scaled down
/// and re-encoded so uploads stay small. Empty when they cancel.
Future<List<ImageUpload>> pickImageUploads(
  ImageSource source, {
  required int limit,
}) async {
  if (limit <= 0) {
    return const [];
  }
  const maxSide = 2048.0;
  const quality = 85;
  final picker = ImagePicker();
  final files = source == ImageSource.gallery && limit > 1
      ? await picker.pickMultiImage(
          maxWidth: maxSide,
          maxHeight: maxSide,
          imageQuality: quality,
          limit: limit,
        )
      : [
          ?await picker.pickImage(
            source: source,
            maxWidth: maxSide,
            maxHeight: maxSide,
            imageQuality: quality,
          ),
        ];
  return [
    for (final file in files.take(limit))
      ImageUpload(
        bytes: await file.readAsBytes(),
        filename: ImageUpload.uploadName(file.name, mimeType: file.mimeType),
      ),
  ];
}

/// Where [AddPhotoButton] gets photos from.
enum PhotoSource { camera, library, clipboard }

/// Desktop keyboards paste with a shortcut worth mentioning.
bool get _hasPasteShortcut => switch (defaultTargetPlatform) {
  TargetPlatform.iOS ||
  TargetPlatform.android ||
  TargetPlatform.fuchsia => false,
  _ => true,
};

String get _pasteShortcutLabel =>
    defaultTargetPlatform == TargetPlatform.macOS ? '⌘V' : 'Ctrl+V';

/// Menu of ways to add photos: the camera (phones), the library or files,
/// and the clipboard. Disabled once the item is full.
class AddPhotoButton extends StatelessWidget {
  const AddPhotoButton({
    super.key,
    required this.room,
    required this.onPick,
    this.enabled = true,
  });

  /// How many more photos fit.
  final int room;
  final bool enabled;
  final void Function(PhotoSource source) onPick;

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    final full = room <= 0;
    final tooltip = full
        ? LocaleKeys.photo_limit.tr(namedArgs: {'value': '$maxItemImages'})
        : LocaleKeys.add_photo.tr();
    const icon = Icon(LucideIcons.imagePlus, size: 20);

    if (full || !enabled) {
      return IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        color: hint,
        onPressed: null,
        icon: icon,
      );
    }
    return PopupMenuButton<PhotoSource>(
      tooltip: tooltip,
      icon: icon,
      iconColor: hint,
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      onSelected: (source) {
        unawaited(HapticFeedback.selectionClick());
        onPick(source);
      },
      itemBuilder: (_) => [
        if (canTakePhoto)
          PopupMenuItem(
            value: PhotoSource.camera,
            child: _MenuRow(
              icon: LucideIcons.camera,
              label: LocaleKeys.take_photo.tr(),
            ),
          ),
        PopupMenuItem(
          value: PhotoSource.library,
          child: _MenuRow(
            icon: LucideIcons.images,
            label: LocaleKeys.choose_photos.tr(),
          ),
        ),
        PopupMenuItem(
          value: PhotoSource.clipboard,
          child: _MenuRow(
            icon: LucideIcons.clipboardPaste,
            label: LocaleKeys.paste_image.tr(),
            shortcut: _hasPasteShortcut ? _pasteShortcutLabel : null,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.shortcut});

  final IconData icon;
  final String label;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (shortcut case final shortcut?)
          Text(shortcut, style: TextStyle(color: Theme.of(context).hintColor)),
      ],
    );
  }
}

/// Rounded square photo with a placeholder while it loads and when it
/// can't be loaded.
class ShoppingImageThumb extends StatelessWidget {
  const ShoppingImageThumb({
    super.key,
    required this.image,
    this.size = 64,
    this.onTap,
    this.onRemove,
    this.busy = false,
  });

  final ImageProvider image;
  final double size;
  final VoidCallback? onTap;

  /// Adds a small remove button in the corner.
  final VoidCallback? onRemove;

  /// Dims it with a spinner, e.g. while uploading.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final hint = Theme.of(context).hintColor;
    final radius = BorderRadius.circular(size / 5);
    Widget placeholder(IconData icon) => ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Icon(icon, size: size / 3, color: hint),
      ),
    );

    final photo = ClipRRect(
      borderRadius: radius,
      child: SizedBox.square(
        dimension: size,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
              wasSynchronouslyLoaded || frame != null
              ? child
              : placeholder(LucideIcons.image),
          errorBuilder: (_, _, _) => placeholder(LucideIcons.imageOff),
        ),
      ),
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null
                  ? null
                  : () {
                      unawaited(HapticFeedback.selectionClick());
                      onTap!();
                    },
              child: MouseRegion(
                cursor: onTap == null
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
                child: photo,
              ),
            ),
          ),
          if (busy)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: radius,
                ),
                child: const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (onRemove != null && !busy)
            Positioned(
              top: -6,
              right: -6,
              child: Tooltip(
                message: LocaleKeys.remove_photo.tr(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    onRemove!();
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.chipColor,
                      border: Border.all(color: theme.cardColor, width: 2),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 12,
                      color: theme.inverseTextColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Network image for a stored photo.
ImageProvider shoppingImageProvider(ShoppingImage image) =>
    NetworkImage(image.url);

/// Opens [images] full screen at [initialIndex]: swipe between them, pinch
/// or scroll to zoom.
Future<void> showShoppingImages(
  BuildContext context,
  List<ImageProvider> images, {
  int initialIndex = 0,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) =>
        _ShoppingImageViewer(images: images, initialIndex: initialIndex),
  );
}

class _ShoppingImageViewer extends StatefulWidget {
  const _ShoppingImageViewer({
    required this.images,
    required this.initialIndex,
  });

  final List<ImageProvider> images;
  final int initialIndex;

  @override
  State<_ShoppingImageViewer> createState() => _ShoppingImageViewerState();
}

class _ShoppingImageViewerState extends State<_ShoppingImageViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late var _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    unawaited(
      _controller.animateToPage(
        _index + delta,
        duration: Durations.medium2,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    final textTheme = Theme.of(context).textTheme;
    const white = Colors.white;

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
            if (_index > 0) {
              _go(-1);
            }
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): () {
            if (_index < count - 1) {
              _go(1);
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Image(
                      image: widget.images[i],
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const CircularProgressIndicator(color: white),
                      errorBuilder: (_, _, _) => const Icon(
                        LucideIcons.imageOff,
                        size: 48,
                        color: white,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      if (count > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            '${_index + 1} / $count',
                            style: textTheme.titleMedium?.copyWith(
                              color: white,
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        color: white,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                ),
              ),
              if (count > 1) ...[
                if (_index > 0)
                  _PageArrow(
                    alignment: Alignment.centerLeft,
                    icon: LucideIcons.chevronLeft,
                    onPressed: () => _go(-1),
                  ),
                if (_index < count - 1)
                  _PageArrow(
                    alignment: Alignment.centerRight,
                    icon: LucideIcons.chevronRight,
                    onPressed: () => _go(1),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.alignment,
    required this.icon,
    required this.onPressed,
  });

  final Alignment alignment;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}
