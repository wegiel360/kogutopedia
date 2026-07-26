import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ImageCompressor {
  static const int _maxDimension = 1920;
  static const int _quality = 80;

  static Future<File> compress({
    required File input,
    String? outputPath,
    int? maxDimension,
    int? quality,
  }) async {
    final bytes = await input.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return input;

    if (bytes.length <= 1024 * 1024 &&
        image.width <= _maxDimension &&
        image.height <= _maxDimension) {
      return input;
    }

    final dim = maxDimension ?? _maxDimension;
    img.Image resized;
    if (image.width > dim || image.height > dim) {
      final scale = dim / (image.width > image.height ? image.width : image.height);
      resized = img.copyResize(image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round());
    } else {
      resized = image;
    }

    final outPath = outputPath ??
        '${input.parent.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpeg';
    final outFile = File(outPath);
    final jpegBytes = img.encodeJpg(resized, quality: quality ?? _quality);
    await outFile.writeAsBytes(jpegBytes);
    return outFile;
  }
}
