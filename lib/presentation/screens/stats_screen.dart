import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/usecases/get_statistics.dart';
import '../providers/stats_provider.dart';
import '../widgets/glass_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(statsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Kogucia Statystyka',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
            if (statsState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (statsState.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    statsState.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildStatsGrid(context, statsState.statistics),
                ),
              ),
              if (statsState.statistics != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCharacterBreakdown(context, statsState.statistics!),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppStatistics? stats) {
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.menu_book,
                label: 'Wpisy',
                value: '${stats.totalEntries}',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.local_fire_department,
                label: 'Dni z Tomkiem',
                value: '${stats.streakCount}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.people,
                label: 'Bohaterowie',
                value: '${stats.characterBreakdown.length}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.photo_library,
                label: 'Multimedia',
                value: '${stats.totalMediaCount}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono().copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterBreakdown(BuildContext context, AppStatistics stats) {
    if (stats.characterBreakdown.isEmpty) return const SizedBox.shrink();

    final total = stats.totalEntries;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Podział aktywności',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...stats.characterBreakdown.map((char) {
              final percentage = total > 0 ? (char.count / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          char.characterName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${char.count} wpisów',
                          style: GoogleFonts.jetBrainsMono().copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.glass,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          char.characterName == 'Tomek'
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.5),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.jetBrainsMono().copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
