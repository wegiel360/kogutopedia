import 'dart:io';
import 'package:exif/exif.dart' as exif;
import 'package:flutter/foundation.dart';

class ExifUtils {
  ExifUtils._();

  static Future<DateTime?> readExifDate(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final tags = await exif.readExifFromFile(file);
      if (tags.isEmpty) {
        final stat = await file.stat();
        return stat.modified;
      }

      for (final key in ['EXIF DateTimeOriginal', 'Image DateTime', 'Thumbnail DateTime']) {
        final tag = tags[key];
        if (tag != null) {
          final dateStr = tag.printable;
          if (dateStr.isNotEmpty) {
            final cleaned = dateStr.replaceAll(':', '-');
            final date = DateTime.tryParse(cleaned);
            if (date != null) return date;
          }
        }
      }

      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      debugPrint('ExifUtils.readExifDate error: $e');
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
