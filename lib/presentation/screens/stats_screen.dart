import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
              if (statsState.statistics != null &&
                  statsState.statistics!.dailyEntries.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildLineChart(context, statsState.statistics!),
                  ),
                ),
              if (statsState.statistics != null &&
                  statsState.statistics!.characterBreakdown.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildPieChart(context, statsState.statistics!),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
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

  Widget _buildLineChart(BuildContext context, AppStatistics stats) {
    final daily = stats.dailyEntries;
    if (daily.isEmpty) return const SizedBox.shrink();

    final maxY = daily.map((d) => d.count).reduce(
      (a, b) => a > b ? a : b,
    );

    final spots = <FlSpot>[];
    for (int i = 0; i < daily.length; i++) {
      spots.add(FlSpot(i.toDouble(), daily[i].count.toDouble()));
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wpisy w czasie',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 1 ? 1 : 0.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.borderGlow.withOpacity(0.2),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.jetBrainsMono().copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: daily.length > 7
                            ? (daily.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= daily.length) {
                            return const SizedBox.shrink();
                          }
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              DateFormat('dd.MM').format(daily[idx].date),
                              style: GoogleFonts.jetBrainsMono().copyWith(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (daily.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY.toDouble() + 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColors.accent,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: daily.length < 30,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.accent,
                          strokeWidth: 1,
                          strokeColor: AppColors.background,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final date = idx >= 0 && idx < daily.length
                              ? DateFormat('dd.MM.yyyy').format(daily[idx].date)
                              : '';
                          return LineTooltipItem(
                            '$date\n${spot.y.toInt()} wpisów',
                            TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontFamily: 'JetBrainsMono',
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, AppStatistics stats) {
    final breakdown = stats.characterBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.textMuted,
    ];

    final total = breakdown.fold<int>(0, (sum, c) => sum + c.count);

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
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(breakdown.length, (i) {
                          final char = breakdown[i];
                          final pct = total > 0
                              ? (char.count / total * 100)
                              : 0.0;
                          return PieChartSectionData(
                            color: colors[i % colors.length],
                            value: pct,
                            title:
                                '${pct.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: GoogleFonts.jetBrainsMono().copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(breakdown.length, (i) {
                      final char = breakdown[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${char.characterName} (${char.count})',
                              style: GoogleFonts.jetBrainsMono().copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
