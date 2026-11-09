import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frontend/features/shopping/domain/models/shopping_list.dart';
import 'package:pasteboard/pasteboard.dart';

export 'pasted_images_stub.dart'
    if (dart.library.js_interop) 'pasted_images_web.dart';

/// The image on the clipboard, or null when there is none or it can't be
/// read (e.g. the browser denied access).
Future<ImageUpload?> readClipboardImage() async {
  try {
    final bytes = await Pasteboard.image;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return ImageUpload(
      bytes: bytes,
      filename: ImageUpload.uploadName(
        'pasted',
        mimeType: imageMimeType(bytes),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('clipboard image: $e');
    }
    return null;
  }
}

/// Guesses the type from [bytes]' signature; null when it isn't a format
/// the server accepts (macOS hands over TIFF, for one).
String? imageMimeType(Uint8List bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) =>
      bytes.length >= offset + signature.length &&
      [
        for (var i = 0; i < signature.length; i++)
          bytes[offset + i] == signature[i],
      ].every((same) => same);

  if (startsWith([0x89, 0x50, 0x4E, 0x47])) {
    return 'image/png';
  }
  if (startsWith([0xFF, 0xD8, 0xFF])) {
    return 'image/jpeg';
  }
  if (startsWith([0x47, 0x49, 0x46, 0x38])) {
    return 'image/gif';
  }
  if (startsWith([0x52, 0x49, 0x46, 0x46]) &&
      startsWith([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}
