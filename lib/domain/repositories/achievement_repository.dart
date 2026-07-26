import '../entities/achievement.dart';

abstract class AchievementRepository {
  Future<List<Achievement>> getAllAchievements();
  Future<bool> isAchievementUnlocked(String achievementId);
  Future<Achievement> unlockAchievement(Achievement achievement);
  Future<int> getAchievementCount();
  Future<void> clearDailyChallenge();
}
