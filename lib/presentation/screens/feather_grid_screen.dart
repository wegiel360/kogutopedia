import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/feather_provider.dart';
import 'feather_form_screen.dart';

class FeatherGridScreen extends ConsumerWidget {
  const FeatherGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featherNotifierProvider);

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
                      'Kolekcja piór',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.feathers.length} ${_pluralize(state.feathers.length, 'piór', 'pióra', 'piór')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (state.feathers.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          color: AppColors.textMuted,
                          size: 80,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Brak piór',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dodaj pierwsze pióro do kolekcji!',
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final feather = state.feathers[index];
                      return _FeatherCard(
                        feather: feather,
                        onDelete: () =>
                            _confirmDelete(context, ref, feather.uuid),
                      );
                    },
                    childCount: state.feathers.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 56,
        width: 56,
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const FeatherFormScreen()),
          ),
          backgroundColor: AppColors.accent.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
                color: AppColors.borderGlow, width: 1.5),
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.accent,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String uuid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Usuń pióro',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Na pewno chcesz usunąć to pióro?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anuluj',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(featherNotifierProvider.notifier)
                  .deleteFeather(uuid);
              Navigator.of(ctx).pop();
            },
            child: const Text('Usuń',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _pluralize(int count, String plural, String singular, String genitive) {
    if (count == 1) return singular;
    if (count % 10 >= 2 && count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return genitive;
    }
    return plural;
  }
}

class _FeatherCard extends StatelessWidget {
  final dynamic feather;
  final VoidCallback onDelete;

  const _FeatherCard({
    required this.feather,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = feather.imagePath != null;
    final hasCharacter = feather.characterName != null;

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.borderGlow.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Expanded(
                child: Image.file(
                  File(feather.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceMedium,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: AppColors.textMuted, size: 32),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  color: AppColors.surfaceMedium,
                  child: const Center(
                    child: Icon(Icons.eco_outlined,
                        color: AppColors.textMuted, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feather.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        hasCharacter
                            ? Icons.face
                            : Icons.help_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hasCharacter
                              ? feather.characterName
                              : 'Nie wiadomo',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
