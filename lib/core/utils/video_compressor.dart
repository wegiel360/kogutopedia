import 'dart:io';
import 'package:video_compress/video_compress.dart';

class VideoCompressor {
  static Future<File?> compress(File input) async {
    try {
      final info = await VideoCompress.compressVideo(
        input.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: true,
      );
      if (info?.path != null) return File(info!.path!);
    } catch (_) {}
    return input;
  }
}
