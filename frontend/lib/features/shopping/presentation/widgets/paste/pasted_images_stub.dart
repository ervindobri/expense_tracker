import 'dart:async';

import 'package:frontend/features/shopping/domain/models/shopping_list.dart';

/// Only the web gets paste events; elsewhere pasting is a key shortcut.
StreamSubscription<void>? listenForPastedImages(
  void Function(List<ImageUpload> images) onImages,
) => null;
