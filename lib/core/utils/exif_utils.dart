import 'dart:io';

class ExifUtils {
  ExifUtils._();

  static Future<DateTime?> readExifDate(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

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
