import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../database/kogutopedia_db.dart';
import '../models/achievement_model.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  final KogutopediaDatabase _db;
  int _nextId = 1;

  AchievementRepositoryImpl(this._db);

  @override
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final models = await _db.getAchievements();
      models.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch achievements: $e');
    }
  }

  @override
  Future<bool> isAchievementUnlocked(String achievementId) async {
    try {
      final models = await _db.getAchievements();
      return models.any((e) => e.achievementId == achievementId);
    } catch (e) {
      throw DatabaseException('Failed to check achievement: $e');
    }
  }

  @override
  Future<Achievement> unlockAchievement(Achievement achievement) async {
    try {
      final models = await _db.getAchievements();
      final existing = models.where((e) => e.achievementId == achievement.achievementId).firstOrNull;
      if (existing != null) return _toEntity(existing);

      _nextId = models.fold(0, (max, e) => e.id != null && e.id! > max ? e.id! : max) + 1;
      final model = AchievementModel(
        id: _nextId,
        achievementId: achievement.achievementId,
        title: achievement.title,
        description: achievement.description,
        iconName: achievement.iconName,
        unlockedAt: achievement.unlockedAt,
        isDailyChallenge: achievement.isDailyChallenge,
      );
      models.add(model);
      await _db.saveAchievements(models);
      return _toEntity(model);
    } catch (e) {
      throw DatabaseException('Failed to unlock achievement: $e');
    }
  }

  @override
  Future<int> getAchievementCount() async {
    try {
      final models = await _db.getAchievements();
      return models.length;
    } catch (e) {
      throw DatabaseException('Failed to count achievements: $e');
    }
  }

  @override
  Future<void> clearDailyChallenge() async {
    try {
      final models = await _db.getAchievements();
      models.removeWhere((e) => e.isDailyChallenge);
      await _db.saveAchievements(models);
    } catch (e) {
      throw DatabaseException('Failed to clear daily challenges: $e');
    }
  }

  Achievement _toEntity(AchievementModel model) {
    return Achievement(
      achievementId: model.achievementId,
      title: model.title,
      description: model.description,
      iconName: model.iconName,
      unlockedAt: model.unlockedAt,
      isDailyChallenge: model.isDailyChallenge,
    );
  }

  AchievementModel _toModel(Achievement achievement) {
    return AchievementModel(
      achievementId: achievement.achievementId,
      title: achievement.title,
      description: achievement.description,
      iconName: achievement.iconName,
      unlockedAt: achievement.unlockedAt,
      isDailyChallenge: achievement.isDailyChallenge,
    );
  }
}
