import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/entry.dart';
import 'glass_card.dart';

class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entry.hasMedia) _buildMediaThumbnail(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildCharacterChip(),
                          const Spacer(),
                          Text(
                            AppDateUtils.formatDateTime(entry.entryDate),
                            style: GoogleFonts.getText('JetBrainsMono').copyWith(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.hasDescription) ...[
                        const SizedBox(height: 6),
                        Text(
                          entry.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: onDelete,
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: SizedBox(
        width: 100,
        child: Stack(
          children: [
            if (entry.isImage && entry.mediaPath != null)
              Image.file(
                File(entry.mediaPath!),
                fit: BoxFit.cover,
                width: 100,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _buildMediaPlaceholder(),
              )
            else
              _buildMediaPlaceholder(),
            if (entry.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder() {
    return Container(
      color: AppColors.surfaceMedium,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCharacterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: entry.characterName == 'Tomek'
            ? AppColors.accent.withOpacity(0.15)
            : AppColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.characterName == 'Tomek'
              ? AppColors.accent.withOpacity(0.5)
              : AppColors.borderGlow.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        entry.characterName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: entry.characterName == 'Tomek'
              ? AppColors.accent
              : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
