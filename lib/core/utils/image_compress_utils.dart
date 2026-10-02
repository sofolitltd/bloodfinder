import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses an image to fit under [maxBytes], shrinking quality and then
/// resolution step by step. Always outputs JPEG, since it compresses far
/// more reliably to a target size than PNG.
class ImageCompressUtils {
  static const int defaultMaxBytes = 200 * 1024;

  static Future<Uint8List> compressToMaxSize(
    Uint8List bytes, {
    int maxBytes = defaultMaxBytes,
  }) async {
    if (bytes.length <= maxBytes) return bytes;

    Uint8List best = bytes;
    int quality = 90;
    int targetSize = 1280;

    for (var attempt = 0; attempt < 8; attempt++) {
      Uint8List result;
      try {
        result = await FlutterImageCompress.compressWithList(
          bytes,
          quality: quality,
          minWidth: targetSize,
          minHeight: targetSize,
          format: CompressFormat.jpeg,
        );
      } catch (_) {
        break;
      }

      if (result.length < best.length) best = result;
      if (result.length <= maxBytes) return result;

      quality = (quality - 15).clamp(10, 100);
      targetSize = (targetSize * 0.75).round().clamp(150, targetSize);
    }

    return best;
  }
}
