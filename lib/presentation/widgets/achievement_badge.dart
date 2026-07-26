import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_card.dart';

class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool unlocked;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.title,
    this.unlocked = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: unlocked ? AppColors.accent : AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
