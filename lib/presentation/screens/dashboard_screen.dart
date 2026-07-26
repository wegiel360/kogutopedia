import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../providers/achievement_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/streak_indicator.dart';
import 'achievements_screen.dart';
import 'entry_form_screen.dart';
import 'gallery_screen.dart';
import 'stats_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardContent(),
    StatsScreen(),
    GalleryScreen(),
    AchievementsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(entryNotifierProvider.notifier).loadEntries();
      ref.read(statsNotifierProvider.notifier).loadStatistics();
      ref.read(achievementNotifierProvider.notifier).loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.borderGlow.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Statystyki',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              activeIcon: Icon(Icons.photo_library),
              label: 'Galeria',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Osiągnięcia',
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () => _navigateToForm(context),
          backgroundColor: AppColors.accent.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderGlow, width: 1.5),
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.accent,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EntryFormScreen()),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryState = ref.watch(entryNotifierProvider);
    final statsState = ref.watch(statsNotifierProvider);
    final achievementState = ref.watch(achievementNotifierProvider);

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, ref, entryState, statsState, achievementState),
      tablet: _buildTabletLayout(context, ref, entryState, statsState, achievementState),
      desktop: _buildDesktopLayout(context, ref, entryState, statsState, achievementState),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    EntryState entryState,
    StatsState statsState,
    AchievementState achievementState,
  ) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildHeader(context, ref, statsState, achievementState),
          _buildMotivationBar(context, entryState),
          if (entryState.entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.menu_book_outlined,
                message: 'Brak wpisów w dzienniku. Dodaj pierwszy materiał!',
              ),
            )
          else
            _buildEntriesList(context, entryState),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    EntryState entryState,
    StatsState statsState,
    AchievementState achievementState,
  ) {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: CustomScrollView(
              slivers: [
                _buildHeader(context, ref, statsState, achievementState),
                _buildMotivationBar(context, entryState),
                if (entryState.entries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.menu_book_outlined,
                      message: 'Brak wpisów w dzienniku. Dodaj pierwszy materiał!',
                    ),
                  )
                else
                  _buildEntriesList(context, entryState),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildQuickPreview(context, entryState),
                  const SizedBox(height: 16),
                  _buildDailyChallengeCard(context, achievementState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    EntryState entryState,
    StatsState statsState,
    AchievementState achievementState,
  ) {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: CustomScrollView(
              slivers: [
                _buildHeader(context, ref, statsState, achievementState),
                _buildMotivationBar(context, entryState),
                if (entryState.entries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.menu_book_outlined,
                      message: 'Brak wpisów w dzienniku. Dodaj pierwszy materiał!',
                    ),
                  )
                else
                  _buildEntriesGrid(context, entryState),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildQuickPreview(context, entryState),
                  const SizedBox(height: 16),
                  _buildDailyChallengeCard(context, achievementState),
                  const SizedBox(height: 16),
                  _buildAchievementsPreview(context, achievementState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    StatsState statsState,
    AchievementState achievementState,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kogutopedia',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Dziennik domowego dróbku',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            StreakIndicator(
              streakCount: statsState.statistics?.streakCount ?? 0,
              totalEntries: statsState.statistics?.totalEntries ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationBar(BuildContext context, EntryState entryState) {
    final hasRecentEntries = entryState.entries.isNotEmpty &&
        AppDateUtils.isSameDay(
          entryState.entries.first.entryDate,
          DateTime.now(),
        );

    if (hasRecentEntries || entryState.entries.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final lastEntry = entryState.entries.first;
    final daysSince = DateTime.now().difference(lastEntry.entryDate).inDays;

    if (daysSince < AppConstants.streakMotivationThreshold) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.pets, color: AppColors.warning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cześć, dawno nie widziałem Tomka. Może czas na nową, epicką sesję? Zrób fotkę i zdobądź kolejny medal!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPreview(BuildContext context, EntryState entryState) {
    final recent = entryState.entries.take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ostatnie wpisy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...recent.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                entry.title,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context, AchievementState achievementState) {
    final challenge = achievementState.dailyChallenge;
    if (challenge == null) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brak wyzwania',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Dodaj wpis aby otrzymać wyzwanie dnia!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final isCompleted = achievementState.challengeCompletedToday;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Wyzwanie dnia',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.glass,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.borderGlow,
                  width: 0.5,
                ),
              ),
              child: Text(
                isCompleted ? 'Wykonane' : 'Do wykonania',
                style: GoogleFonts.jetBrainsMono().copyWith(
                  fontSize: 12,
                  color: isCompleted ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsPreview(BuildContext context, AchievementState achievementState) {
    final achievements = achievementState.achievements
        .where((a) => !a.isDailyChallenge)
        .toList();
    if (achievements.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medale (${achievements.length})',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((a) {
                IconData icon;
                switch (a.iconName) {
                  case 'camera':
                    icon = Icons.camera_alt;
                    break;
                  case 'video':
                    icon = Icons.videocam;
                    break;
                  default:
                    icon = Icons.emoji_events;
                }
                return Tooltip(
                  message: a.title,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGlow, width: 0.5),
                    ),
                    child: Icon(icon, color: AppColors.accent, size: 24),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, EntryState entryState) {
    final entries = entryState.filteredEntries;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          return EntryCard(
            entry: entry,
            onTap: () {},
          );
        },
        childCount: entries.length,
      ),
    );
  }

  Widget _buildEntriesGrid(BuildContext context, EntryState entryState) {
    final entries = entryState.filteredEntries;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = entries[index];
            return EntryCard(
              entry: entry,
              onTap: () {},
            );
          },
          childCount: entries.length,
        ),
      ),
    );
  }
}
