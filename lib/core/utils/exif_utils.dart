import 'dart:io';
import 'package:image/image.dart' as img;

class ExifUtils {
  ExifUtils._();

  static Future<DateTime?> readExifDate(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final ext = filePath.split('.').last.toLowerCase();
      if (ext == 'jpg' || ext == 'jpeg') {
        final bytes = await file.readAsBytes();
        final exif = img.decodeJpgExif(bytes);
        if (exif != null) {
          final dateStr =
              exif.exifIfd['DateTimeOriginal']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            final cleaned = dateStr.replaceAll(':', '-');
            final date = DateTime.tryParse(cleaned);
            if (date != null) return date;
          }
        }
      }

      final stat = await file.stat();
      return stat.modified;
    } catch (_) {
      return null;
    }
  }

  static DateTime getEffectiveDate({
    required DateTime? exifDate,
    required DateTime fallback,
  }) {
    return exifDate ?? fallback;
  }
}
