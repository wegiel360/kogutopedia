import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_provider.dart';
import '../widgets/glass_card.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryState = ref.watch(entryNotifierProvider);

    final mediaEntries = entryState.entries
        .where((e) => e.hasMedia)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Galeria',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mediaEntries.length} ${_pluralize(mediaEntries.length, 'multimediów', 'multimediów', 'multimediów')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (entryState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (mediaEntries.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: AppColors.textMuted,
                          size: 80,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Brak multimediów',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dodaj zdjęcia lub filmy do wpisów, aby pojawiły się w galerii.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = mediaEntries[index];
                      return _buildMediaThumbnail(context, entry);
                    },
                    childCount: mediaEntries.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(BuildContext context, Entry entry) {
    return GestureDetector(
      onTap: () => _showMediaPreview(context, entry),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
          image: entry.isImage && entry.mediaPath != null
              ? DecorationImage(
                  image: FileImage(File(entry.mediaPath!)),
                  fit: BoxFit.cover,
                )
              : null,
          color: AppColors.surfaceMedium,
        ),
        child: entry.isVideo
            ? const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: AppColors.accent,
                  size: 32,
                ),
              )
            : null,
      ),
    );
  }

  void _showMediaPreview(BuildContext context, Entry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              entry.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          body: Center(
            child: entry.isImage && entry.mediaPath != null
                ? InteractiveViewer(
                    child: Image.file(
                      File(entry.mediaPath!),
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: AppColors.accent,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Odtwarzanie filmu...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _pluralize(int count, String singular, String plural, String genitive) {
    if (count == 1) return singular;
    if (count % 10 >= 2 && count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return genitive;
    }
    return plural;
  }
}
