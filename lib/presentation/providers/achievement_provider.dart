import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/kogutopedia_db.dart';
import '../../data/repositories/achievement_repository_impl.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/usecases/get_statistics.dart';
import 'entry_provider.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AchievementRepositoryImpl(db);
});

class AchievementState {
  final List<Achievement> achievements;
  final bool isLoading;
  final String? error;
  final Achievement? dailyChallenge;
  final bool challengeCompletedToday;

  const AchievementState({
    this.achievements = const [],
    this.isLoading = false,
    this.error,
    this.dailyChallenge,
    this.challengeCompletedToday = false,
  });

  AchievementState copyWith({
    List<Achievement>? achievements,
    bool? isLoading,
    String? error,
    Achievement? dailyChallenge,
    bool? challengeCompletedToday,
  }) {
    return AchievementState(
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      challengeCompletedToday: challengeCompletedToday ?? this.challengeCompletedToday,
    );
  }
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  final AchievementRepository _repository;
  final GetStatisticsUseCase _getStatistics;
  final Random _random = Random();

  AchievementNotifier(this._repository, this._getStatistics)
      : super(const AchievementState());

  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final achievements = await _repository.getAllAchievements();
      final dailyChallenge = await _loadDailyChallenge();
      state = state.copyWith(
        achievements: achievements,
        isLoading: false,
        dailyChallenge: dailyChallenge,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nie udało się załadować osiągnięć',
      );
    }
  }

  Future<Achievement?> _loadDailyChallenge() async {
    final dailyAchievements = await _repository.getAllAchievements();
    final todaysChallenge = dailyAchievements
        .where((a) => a.isDailyChallenge)
        .toList();

    if (todaysChallenge.isNotEmpty) {
      final challenge = todaysChallenge.first;
      final today = DateTime.now();
      final challengeDate = challenge.unlockedAt;
      final isToday = challengeDate.year == today.year &&
          challengeDate.month == today.month &&
          challengeDate.day == today.day;
      return challenge;
    }
    return null;
  }

  Future<void> generateDailyChallenge() async {
    final existing = await _loadDailyChallenge();
    if (existing != null) return;

    final index = _random.nextInt(AppConstants.dailyChallenges.length);
    final challengeText = AppConstants.dailyChallenges[index];

    final challenge = Achievement(
      achievementId: 'daily_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Wyzwanie dnia',
      description: challengeText,
      iconName: 'star',
      unlockedAt: DateTime.now(),
      isDailyChallenge: true,
    );

    await _repository.unlockAchievement(challenge);
    state = state.copyWith(dailyChallenge: challenge);
  }

  Future<void> completeDailyChallenge() async {
    if (state.dailyChallenge == null) return;
    state = state.copyWith(challengeCompletedToday: true);
  }

  Future<void> checkAndUnlockAchievements() async {
    final appStats = await _getStatistics();

    final allAchievements = await _repository.getAllAchievements();
    final unlockedIds = allAchievements.map((a) => a.achievementId).toSet();

    final totalEntries = appStats.totalEntries;
    if (totalEntries >= AppConstants.paparazziThreshold &&
        !unlockedIds.contains('paparazzi')) {
      await _repository.unlockAchievement(Achievement(
        achievementId: 'paparazzi',
        title: 'Paparazzi',
        description: 'Zrobiłeś $totalEntries zdjęć!',
        iconName: 'camera',
        unlockedAt: DateTime.now(),
      ));
    }

    final videoCount = appStats.totalMediaCount;
    if (videoCount >= AppConstants.directorThreshold &&
        !unlockedIds.contains('director')) {
      await _repository.unlockAchievement(Achievement(
        achievementId: 'director',
        title: 'Reżyser',
        description: 'Nagrałeś $videoCount filmów!',
        iconName: 'video',
        unlockedAt: DateTime.now(),
      ));
    }

    await loadAchievements();
  }
}

final achievementNotifierProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  final repository = ref.read(achievementRepositoryProvider);
  final getStats = ref.read(getStatisticsUseCaseProvider);
  return AchievementNotifier(repository, getStats);
});
