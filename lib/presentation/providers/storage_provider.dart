import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageProgress {
  final int bytesTransferred;
  final int totalBytes;
  final double speedMBps;

  StorageProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.speedMBps,
  });

  double get fraction => totalBytes > 0 ? bytesTransferred / totalBytes : 0;
  String get transferredMB =>
      '${(bytesTransferred / (1024 * 1024)).toStringAsFixed(1)}';
  String get totalMB =>
      '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}';
  String get speedMBs => '${speedMBps.toStringAsFixed(1)} MB/s';
}

class StorageState {
  final bool isUploading;
  final bool isDownloading;
  final StorageProgress? progress;
  final String? error;

  const StorageState({
    this.isUploading = false,
    this.isDownloading = false,
    this.progress,
    this.error,
  });

  StorageState copyWith({
    bool? isUploading,
    bool? isDownloading,
    StorageProgress? progress,
    String? error,
  }) {
    return StorageState(
      isUploading: isUploading ?? this.isUploading,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

class StorageNotifier extends StateNotifier<StorageState> {
  StorageNotifier() : super(const StorageState());

  final FirebaseStorage _storage = FirebaseStorage.instance;

  StreamSubscription<TaskSnapshot>? _uploadSub;
  StreamSubscription<TaskSnapshot>? _downloadSub;

  Future<String?> uploadMedia({
    required File file,
    required String path,
    required void Function(StorageProgress progress) onProgress,
  }) async {
    try {
      state = state.copyWith(isUploading: true, error: null);
      final ref = _storage.ref(path);
      final task = ref.putFile(file);

      int lastBytes = 0;
      DateTime lastTime = DateTime.now();

      task.snapshotEvents.listen((snapshot) {
        final now = DateTime.now();
        final elapsed = now.difference(lastTime).inMilliseconds / 1000;
        final transferred = snapshot.bytesTransferred;
        final speed = elapsed > 0
            ? (transferred - lastBytes) / (1024 * 1024) / elapsed
            : 0.0;
        lastBytes = transferred;
        lastTime = now;

        onProgress(StorageProgress(
          bytesTransferred: transferred,
          totalBytes: snapshot.totalBytes,
          speedMBps: speed,
        ));
      });

      await task;
      final url = await ref.getDownloadURL();
      state = state.copyWith(isUploading: false);
      return url;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: '$e');
      return null;
    }
  }

  Future<File?> downloadMedia({
    required String url,
    required String localPath,
    required void Function(StorageProgress progress) onProgress,
  }) async {
    try {
      state = state.copyWith(isDownloading: true, error: null);
      final ref = _storage.refFromURL(url);
      final file = File(localPath);

      final task = ref.writeToFile(file);

      int lastBytes = 0;
      DateTime lastTime = DateTime.now();

      task.snapshotEvents.listen((snapshot) {
        final now = DateTime.now();
        final elapsed = now.difference(lastTime).inMilliseconds / 1000;
        final transferred = snapshot.bytesTransferred;
        final speed = elapsed > 0
            ? (transferred - lastBytes) / (1024 * 1024) / elapsed
            : 0.0;
        lastBytes = transferred;
        lastTime = now;

        onProgress(StorageProgress(
          bytesTransferred: transferred,
          totalBytes: snapshot.totalBytes,
          speedMBps: speed,
        ));
      });

      await task;
      state = state.copyWith(isDownloading: false);
      return file;
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: '$e');
      return null;
    }
  }

  @override
  void dispose() {
    _uploadSub?.cancel();
    _downloadSub?.cancel();
    super.dispose();
  }
}

final storageProvider =
    StateNotifierProvider<StorageNotifier, StorageState>((ref) {
  return StorageNotifier();
});
