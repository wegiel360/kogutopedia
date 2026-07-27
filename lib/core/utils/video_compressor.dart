import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

class VideoCompressor {
  static Future<File?> compress(
    File input, {
    void Function(int percent)? onProgress,
  }) async {
    Subscription? sub;
    if (onProgress != null) {
      sub = VideoCompress.compressProgress$.subscribe((p) {
        onProgress((p * 100).toInt());
      });
    }
    try {
      final info = await VideoCompress.compressVideo(
        input.path,
        quality: VideoQuality.HighestQuality,
        deleteOrigin: true,
      );
      return info?.path != null ? File(info!.path!) : null;
    } catch (e) {
      debugPrint('VideoCompressor.compress error: $e');
      return null;
    } finally {
      sub?.unsubscribe();
    }
  }
}