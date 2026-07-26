import 'dart:io';
import 'package:exif/exif.dart';

class ExifUtils {
  ExifUtils._();

  static Future<DateTime?> readExifDate(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final tags = await readExifFromBytes(bytes);

      final dateTaken = tags['EXIF DateTimeOriginal'] ??
          tags['EXIF DateTimeDigitized'] ??
          tags['Image DateTime'];

      if (dateTaken != null) {
        return ExifTag.parseDate(dateTaken.printable);
      }
      return null;
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
