import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/achievement.dart';
import '../providers/achievement_provider.dart';
import '../widgets/glass_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementNotifierProvider);

    final regularAchievements = achievementState.achievements
        .where((a) => !a.isDailyChallenge)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Osiągnięcia i Medale',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
            if (achievementState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (regularAchievements.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: AppColors.textMuted,
                          size: 80,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Brak odznak',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dodawaj wpisy i zdobywaj osiągnięcia!',
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
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final achievement = regularAchievements[index];
                      return _buildAchievementCard(context, achievement);
                    },
                    childCount: regularAchievements.length,
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

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    IconData icon;
    switch (achievement.iconName) {
      case 'camera':
        icon = Icons.camera_alt;
        break;
      case 'video':
        icon = Icons.videocam;
        break;
      default:
        icon = Icons.emoji_events;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGlow, width: 0.5),
                ),
                child: Icon(icon, color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
