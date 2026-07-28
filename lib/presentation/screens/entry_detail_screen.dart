import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_provider.dart';
import '../providers/storage_provider.dart';
import 'entry_form_screen.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry.isVideo && widget.entry.hasMedia) {
      _initVideo();
    }
    Future.microtask(() {
      ref.read(storageProvider.notifier).refreshQuota();
    });
  }

  Future<void> _initVideo() async {
    final path = widget.entry.primaryMediaPath;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isVideoInitialized = true);
        }
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _navigateToEdit() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(existingEntry: widget.entry),
      ),
    );
  }

  void _showMediaFullscreen() {
    final path = widget.entry.primaryMediaPath;
    if (path == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenMedia(
          path: path,
          isVideo: widget.entry.isVideo,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGlow, width: 0.5),
        ),
        title: const Text(
          'Usuń wpis',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Czy na pewno chcesz usunąć ten wpis? Multimedia zostaną również usunięte z Firebase Storage.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteEntry();
    }
  }

  Future<void> _deleteEntry() async {
    setState(() => _isDeleting = true);

    try {
      final entry = widget.entry;
      final storage = ref.read(storageProvider.notifier);

      for (int i = 0; i < entry.mediaPaths.length; i++) {
        try {
          final ext = entry.mediaTypes.length > i && entry.mediaTypes[i] == 'video' ? 'mp4' : 'jpg';
          await storage.deleteMedia('media/${entry.uuid}_$i.$ext');
        } catch (e) {
          debugPrint('Firebase deletion error for media $i: $e');
        }
        try {
          final localFile = File(entry.mediaPaths[i]);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        } catch (e) {
          debugPrint('Local file deletion error for media $i: $e');
        }
      }

      await ref.read(entryNotifierProvider.notifier).deleteEntry(entry.uuid);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd usuwania: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageState = ref.watch(storageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.accent),
            tooltip: 'Edytuj',
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Usuń',
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.entry.hasMedia) ...[
              _buildMediaPreview(),
              const SizedBox(height: 20),
            ],
            _buildInfoSection(),
            const SizedBox(height: 20),
            if (storageState.isUploading || storageState.isDownloading)
              _buildStorageProgress(storageState),
          ],
        ),
      ),
          if (_isDeleting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return GestureDetector(
      onTap: _showMediaFullscreen,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfaceMedium,
          border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.entry.isImage)
              Image.file(
                File(widget.entry.primaryMediaPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: AppColors.textMuted,
                  size: 64,
                ),
              )
            else if (_isVideoInitialized && _videoController != null)
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              const Icon(
                Icons.play_circle_outline,
                color: AppColors.accent,
                size: 80,
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.entry.isImage ? Icons.photo : Icons.videocam,
                      color: AppColors.textPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.entry.isImage ? 'Zdjęcie' : 'Film',
                      style: GoogleFonts.jetBrainsMono().copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.entry.isVideo && _isVideoInitialized)
              Center(
                child: IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: Colors.white70,
                    size: 64,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGlow, width: 0.5),
                ),
                child: Text(
                  widget.entry.characterName,
                  style: GoogleFonts.jetBrainsMono().copyWith(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppDateUtils.formatDateTime(widget.entry.entryDate),
                style: GoogleFonts.jetBrainsMono().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.entry.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 22),
          ),
          if (widget.entry.hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              widget.entry.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStorageProgress(StorageState state) {
    final progress = state.progress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isUploading ? Icons.cloud_upload : Icons.cloud_download,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                state.isUploading ? 'Wysyłanie...' : 'Pobieranie...',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              backgroundColor: AppColors.surfaceMedium,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.transferredMB} / ${progress.totalMB} MB',
                style: GoogleFonts.jetBrainsMono().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                progress.speedMBs,
                style: GoogleFonts.jetBrainsMono().copyWith(
                  color: AppColors.accent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullScreenMedia extends StatefulWidget {
  final String path;
  final bool isVideo;

  const _FullScreenMedia({required this.path, required this.isVideo});

  @override
  State<_FullScreenMedia> createState() => _FullScreenMediaState();
}

class _FullScreenMediaState extends State<_FullScreenMedia> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          if (mounted) setState(() => _isInitialized = true);
        });
    } else {
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: widget.isVideo
            ? _buildVideoView()
            : _buildImageView(),
      ),
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      maxScale: 5,
      child: Image.file(
        File(widget.path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    if (!_isInitialized || _videoController == null) {
      return const CircularProgressIndicator(color: AppColors.accent);
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          if (!_videoController!.value.isPlaying)
            const Icon(
              Icons.play_circle,
              color: Colors.white70,
              size: 80,
            ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.accent,
                backgroundColor: Colors.white24,
                bufferedColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
