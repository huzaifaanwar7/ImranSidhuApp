import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Pops a photo source sheet (camera/gallery), reads the bytes, and returns
/// a `data:image/...;base64,...` string ready for the backend's
/// `LogoBase64` / `PhotoBase64` fields.
class ImagePickerHelper {
  static final _picker = ImagePicker();

  static Future<String?> pickAsBase64({ImageSource source = ImageSource.gallery}) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (x == null) return null;
      final bytes = kIsWeb ? await x.readAsBytes() : await File(x.path).readAsBytes();
      final ext = x.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('ImagePicker error: $e');
      return null;
    }
  }
}
