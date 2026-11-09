import 'dart:async';
import 'dart:js_interop';

import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:web/web.dart' as web;

/// Calls [onImages] with the images pasted anywhere on the page (Ctrl/⌘+V,
/// the browser's paste menu) until cancelled. Pastes with an image don't
/// also paste text into the focused field; other pastes are left alone.
///
/// The paste event hands over the clipboard's files directly, so unlike
/// reading the clipboard it needs no permission prompt.
StreamSubscription<void>? listenForPastedImages(
  void Function(List<ImageUpload> images) onImages,
) {
  return web.EventStreamProviders.pasteEvent.forTarget(web.document).listen((
    event,
  ) {
    final files = event.clipboardData?.files;
    if (files == null) {
      return;
    }
    final images = [
      for (var i = 0; i < files.length; i++)
        if (files.item(i) case final file? when file.type.startsWith('image/'))
          file,
    ];
    if (images.isEmpty) {
      return;
    }
    event.preventDefault();
    unawaited(() async {
      onImages([
        for (final file in images)
          ImageUpload(
            bytes: (await file.arrayBuffer().toDart).toDart.asUint8List(),
            filename: ImageUpload.uploadName(file.name, mimeType: file.type),
          ),
      ]);
    }());
  });
}
