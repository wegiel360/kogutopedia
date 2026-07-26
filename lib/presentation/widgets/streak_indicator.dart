import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'glass_card.dart';

class StreakIndicator extends StatelessWidget {
  final int streakCount;
  final int totalEntries;

  const StreakIndicator({
    super.key,
    required this.streakCount,
    required this.totalEntries,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGlow, width: 0.5),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dni z Tomkiem: $streakCount',
                    style: GoogleFonts.jetBrainsMono().copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Łącznie $totalEntries wpisów',
                    style: Theme.of(context).textTheme.bodySmall,
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
